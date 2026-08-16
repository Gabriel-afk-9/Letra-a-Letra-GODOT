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
infrastructure/mappers/  # API response <-> domain
presentation/views/      # <name>_screen.tscn + <name>_screen.gd
presentation/viewmodels/ # extends BaseViewModel
```

- Dependency rule: view → viewmodel → usecase → repository. Repository interfaces (contracts) live in `core/application/contracts/` (e.g. `login_repository.gd`) and are `extends`-ed by the remote implementations.
- **Shared services come only from the `ServiceRegistry` autoload** (`HttpClient`, `WebSocketClient`, `NavigationService`, `UserRepository`, `MatchmakingRepository`). Never instantiate those yourself — features that do are assembled via their factory, e.g. `LoginFactory.create()` in the view's `_ready()`.
- To add a new screen: build the feature, then register its scene path in `core/presentation/navigation/app_routes.gd` and navigate with `ServiceRegistry.navigation_service().go_to(AppRoutes.X)` (or `NavigationService` injected into the viewmodel).
- `AppRoutes.GAME` (`features/game/...`) is a **stub — the folder does not exist yet**. The game screen is not implemented.
- Session state lives in the `SessionStore` autoload; persisted to `user://session.cfg` by `SessionPersistence` (defined in `ServiceRegistry`).

## Async & code style

- All I/O is `await`-based: repositories `await _http_client.http_post(...)`, usecases `await` repositories, viewmodels `await` usecases and emit `loading_changed` / `error_changed` signals (`BaseViewModel`). Views connect to those signals and never block.
- `HttpClient` returns `HttpResponse` (`.success`, `.body` Dictionary, `.error_message`). Endpoints are paths relative to `API_BASE_URL` (e.g. `/user/auth`); the Bearer token is attached automatically via `SessionStoreAuthProvider`.
- WebSocket: `WebSocketClient` exposes signals (`connected`, `disconnected`, `connection_error`, `message_received`) — repositories subscribe in their `_init`. Matchmaking protocol: event `MATCHMAKING_GAME`, status `FOUNDED`, default gameMode `INSANE`; see `RemoteMatchmakingRepository`.
- Reusable UI components live in `assets/components/*.tscn` (e.g. `PasswordInput.shake()`, error labels with `show_error()`); button styles in `assets/styles/buttons/` are named `<color>_button_<state>` (`orange_button_default/hover/pressed/home`).
- Tab indentation (Godot default). `* text=auto eol=lf` via `.gitattributes`; `.godot/` is gitignored — never commit it.
## Game feature (not yet implemented)

`AppRoutes.GAME` points to a scene that doesn't exist yet — `features/game/` needs
to be scaffolded from scratch following the same layered pattern as `matchmaking/`.

WS events confirmed via legacy MVP client (`wsEventHandler.js`) and API test flows
(`matchmaking.flow.js`) — NOT yet implemented in any `.gd` file, treat as reference
only, re-verify against the live backend before trusting field names:

- `PLAYER_ACTION_RESULT` — turn result; `currentTurnPlayerId` and `turnEndsAt` may
  appear at root OR inside `data` (legacy client checks both: `msg.x || msg.data?.x`)
- `TURN_EXPIRED` — same currentTurnPlayerId/turnEndsAt shape
- `GAME_OVER` — `data.winner.id`
- `PARTICIPANT_LEAVE` / `PARTICIPANT_DISCONNECTED` — opponent left, treat as win by W.O.
- `REMOVED_BECAUSE_INACTIVITY` — local player kicked for inactivity
- `ERROR` — `message` field carries an error code string (not just free text),
  e.g. "stepped_on_trap" (with `data.x`/`data.y`), "player_are_immune",
  "player_not_in_game" — client branches on this string, it's not just a display
  message

Board state arrives via `data.board` (shape not yet confirmed).

Client sends actions as: `{"type": "PLAYER_ACTION", "gameId": ..., "action": {"type": "REVEAL", "position": {"x": int, "y": int}}}`

`WebSocketMessage.raw` already exists in `core/infrastructure/network/websocket/`
and gives access to root-level fields beyond `event`/`message`/`data` — use it for
any of the root-vs-data ambiguity above instead of assuming one or the other.