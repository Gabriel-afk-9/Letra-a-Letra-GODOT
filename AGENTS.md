# AGENTS.md

## Project

- Godot 4.7 client (GDScript) for "Letra a Letra", a multiplayer word-hunt game. Backend: external Spring Boot API ([Letra-a-Letra-API](https://github.com/Zidan-09/Letra-a-Letra-API)).
- **The Godot project root is `game/`** — open `game/project.godot` in the editor, not the repo root.
- No tests, no linters, no CI, no package manager. There is nothing to run besides the game itself: press F5 in the Godot editor. GDScript errors surface only when scenes load at runtime, so verify by actually running the app.
- The backend must be running locally. URLs are hardcoded in `game/core/infrastructure/environment/global_environment.gd`: `API_BASE_URL = "http://127.0.0.1:8080"`, `WS_BASE_URL = "ws://127.0.0.1:8080/ws/game"`. Without it, login/matchmaking fail.
- Code comments and user-facing strings are PT-BR; identifiers are English. Keep this convention.

## Architecture

Clean Architecture, feature-first. Every feature under `game/features/<name>/` has this exact layout:

```
main/factory/            # static Factory.create() -> ViewModel, wires all dependencies
application/usecases/    # business logic
domain/                  # requests, results, models
infrastructure/repositories/  # RemoteXxxRepository (HTTP/WS)
infrastructure/mappers/  # API response <-> domain (recommended for new features;
                         # game/ and matchmaking/ do NOT have it yet — they parse inline)
presentation/views/      # <name>_screen.tscn + <name>_screen.gd
presentation/viewmodels/ # extends BaseViewModel
```

- Mapper caveat: neither `game/` nor `matchmaking/` has an `infrastructure/mappers/` folder today. JSON → domain parsing is done inline in the domain models (`from_dictionary`/`from_array`) and inside the remote repositories. Prefer adding a real mapper layer for new features, but follow the existing inline style when touching these two.

- Dependency rule: view → viewmodel → usecase → repository. Repository interfaces (contracts) live in `core/application/contracts/` (e.g. `login_repository.gd`) and are `extends`-ed by the remote implementations.
- **Shared services come only from the `ServiceRegistry` autoload** (`HttpClient`, `WebSocketClient`, `NavigationService`, `UserRepository`, `MatchmakingRepository`). Never instantiate those yourself — features that do are assembled via their factory, e.g. `LoginFactory.create()` in the view's `_ready()`.
- To add a new screen: build the feature, then register its scene path in `core/presentation/navigation/app_routes.gd` and navigate with `ServiceRegistry.navigation_service().go_to(AppRoutes.X)` (or `NavigationService` injected into the viewmodel).
- `AppRoutes.GAME` points to `features/game/presentation/views/game_screen.tscn` — implemented; see "Game feature" below.
- Session state lives in the `SessionStore` autoload; persisted to `user://session.cfg` by `SessionPersistence` (defined in `ServiceRegistry`).

## Async & code style

- All I/O is `await`-based: repositories `await _http_client.http_post(...)`, usecases `await` repositories, viewmodels `await` usecases and emit `loading_changed` / `error_changed` signals (`BaseViewModel`). Views connect to those signals and never block.
- `HttpClient` returns `HttpResponse` (`.success`, `.body` Dictionary, `.error_message`). Endpoints are paths relative to `API_BASE_URL` (e.g. `/user/auth`); the Bearer token is attached automatically via `SessionStoreAuthProvider`.
- WebSocket: `WebSocketClient` exposes signals (`connected`, `disconnected`, `connection_error`, `message_received`) — repositories subscribe in their `_init`. Matchmaking protocol: event `MATCHMAKING_GAME`, status `FOUNDED`, default gameMode `CATACLYSM`; see `RemoteMatchmakingRepository`.
- Reusable UI components live in `assets/components/*.tscn` (e.g. `PasswordInput.shake()`, error labels with `show_error()`); button styles in `assets/styles/buttons/` are named `<color>_button_<state>` (`orange_button_default/hover/pressed/home`).
- Tab indentation (Godot default). `* text=auto eol=lf` via `.gitattributes`; `.godot/` is gitignored — never commit it.
## Game feature (implemented)

`features/game/` exists and follows the same layered pattern as `matchmaking/`
(no mappers layer — parsing is inline):

```
application/usecases/game_usecase.gd
domain/models/            # game_board.gd, game_cell.gd, game_word.gd,
                          # game_player_state.gd, game_power.gd, game_internal_event.gd
domain/game_power_catalog.gd   # power metadata: scope GLOBAL/CELL, offensive, usable while frozen
infrastructure/repositories/remote_game_repository.gd
main/factory/game_factory.gd   # GameFactory.bind(view) — consumes the MatchmakingFoundEvent navigation payload
presentation/views/       # game_screen.tscn + game_screen.gd (+ dashed_slot_frame.gd)
presentation/viewmodels/game_viewmodel.gd
```

Flow: matchmaking emits `match_found(MatchmakingFoundEvent)` as a navigation payload →
`GameFactory.bind()` builds usecase + viewmodel → `view.setup(...)` calls
`RemoteGameRepository.start(game_id)`. The initial board snapshot arrives BEFORE
`start()` (during matchmaking); the repository buffers it in `_pending_*` fields and
flushes through the regular signals on `start()` — don't duplicate this mechanism.

WS events handled by `RemoteGameRepository` (confirmed against the backend and the
legacy MVP client):

- `PLAYER_ACTION_RESULT` / `TURN_EXPIRED` — `currentTurnPlayerId` and `turnEndsAt`
  may appear at root OR inside `data`; resolved via `_first_string()`, which checks
  `WebSocketMessage.raw` first, then `data`. No dedicated branch needed: generic
  handlers run before the event `match`.
- `GAME_OVER` — `data.winner.id`; repository clears game state afterwards.
- `PARTICIPANT_LEAVE` / `PARTICIPANT_DISCONNECTED` — opponent left, emitted as
  win by W.O. (`opponent_disconnected`); repository clears game state.
- `REMOVED_BECAUSE_INACTIVITY` — local player kicked for inactivity.
- `ERROR` — `message` field carries an error code string (not just free text),
  e.g. "stepped_on_trap" (with `data.x`/`data.y`), "player_are_immune",
  "player_not_in_game" — client branches on this string, it's not just a display
  message.

Board/inventory state arrives via `data.board` (`GameBoard.from_array`),
`data.words`, and `data.players[].inventory` (5 fixed slots, each a
`GamePower{id, type}` or null, parsed by `GamePlayerState.from_dictionary`).

Client sends actions as: `{"type": "PLAYER_ACTION", "gameId": ..., "action": {"type": "REVEAL", "position": {"x": int, "y": int}}}`

`WebSocketMessage.raw` (`core/infrastructure/network/websocket/websocket_message.gd`)
gives access to root-level fields beyond `event`/`message`/`data` — use it for any
root-vs-data ambiguity instead of assuming one or the other.