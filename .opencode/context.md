# Contexto Opencode — Letra a Letra Fase Testes

> **Para outro notebook/opencode:** este arquivo resume o estado de testes para continuar sem re-descobrir o projeto. Leia junto com `AGENTS.md` e `docs/testing-plan.md`.

## Projeto

- **Godot 4.7** `game/project.godot:1` Mobile 360x640 `stretch=canvas_items` portrait, renderer `mobile`, Jolt Physics
- **Godot root = `game/`** (abrir `game/project.godot`, não repo root) — `AGENTS.md:5`
- **Backend:** Spring Boot `http://127.0.0.1:8080` + `ws://127.0.0.1:8080/ws/game` hardcoded `game/core/infrastructure/environment/global_environment.gd:2` (env futuro não feito, ver discussão plan)
- **Arquitetura:** Clean Architecture + Feature-First `game/features/<nome>/` com `domain/`, `application/usecases/`, `infrastructure/{repositories,mappers}`, `presentation/{views,viewmodels}`, `main/factory` — `AGENTS.md:12`
- **Regra:** `View → ViewModel → UseCase → Repository Contract → RemoteRepository` (`core/application/contracts/repositories/`), shared só via `ServiceRegistry` autoload `autoload/service_registry.gd:15` (`HttpClient`, `WebSocketClient`, `NavigationService`), tab indentação PT-BR strings / inglês identifiers

## Bíblias

- **Testes:** `docs/testing-plan.md:1` — pirâmide 70% unit / 20% integração / 10% contrato WS, GUT 9.7.1, 102 tests 258 asserts (`game/tests/unit` 23 arquivos), Fase 1 15 casos (37 asserts), Fase 2 FakeRepo, Fase 4 102/102
- **Contrato WS:** `docs/websocket-events-contract.md:1` — 8 eventos (`PLAYER_ACTION_RESULT`, `TURN_EXPIRED`, `GAME_OVER`, `MATCHMAKING_GAME SEARCHING/FOUNDED`, `PARTICIPANT_LEAVE`, `PARTICIPANT_DISCONNECTED`, `REMOVED_BECAUSE_INACTIVITY`, `ERROR`), envelope `WsResponse` `@JsonTypeInfo(property="event")`, DTOs `GameStateResponse{players,board,words,currentTurnPlayerId}`, `PlayerResponse{inventory{id,name}}`, `BoardResponse{revealed,letter,revealedBy,effect}`, `WordResponse{word,found,foundById}`
- **Levantamento Game:** `GAME_FEATURE_ANALYSIS.md:1` — Fase 5C parcial, buffering `_pending_*` em `RemoteGameRepository.start(game_id)` `game/features/game/infrastructure/repositories/remote_game_repository.gd:47`, WS `_first_string()` root-vs-data `core/infrastructure/network/websocket/websocket_message.gd:26`, poderes `game_power_catalog.gd:125` 10 tipos

## Estado Atual Testes (2026-09-09 verificado — 102/102 verdes)

- **GUT 9.7.1** `game/addons/gut/plugin.cfg:5` `version="9.7.1"` habilitado `game/project.godot:32` `enabled=PackedStringArray("res://addons/gut/plugin.cfg"...)` — 9.6.1 causava `GUT (Indefinido)` + `WARNING uid://` + `RunAtCursor.gd:130 Nil`
- **Config:** `game/.gutconfig.json:1` `{"dirs":["res://tests/unit"],"include_subdirs":true,"prefix":"test_","suffix":".gd"}` — CLI lê `res://.gutconfig.json`, GUI lê `user://gut_temp_directory/gut_editor_config.json` (`addons/gut/gui/editor_globals.gd:11`) — precisa sincronizar via `Carregar` → `res://.gutconfig.json` → `Salvar` (fix `You do not have any directories set` `GutBottomPanel.gd:83` + `gut_config_gui.gd:61`)
- **Fase 1 37/37 verdes <1s** em `game/tests/unit/`:
  - `mappers/test_game_board_mapper.gd:1` 4 testes (vazio, 1x1 `revealed:true`, 2x2 `BLOCK`, row inválida)
  - `mappers/test_game_cell_mapper.gd:1` 5 testes (effect null, letter null, revealed string, `TRAP` owner/clicks, float)
  - `mappers/test_game_word_mapper.gd:1` 3 testes
  - `mappers/test_game_power_mapper.gd:1` 3 testes (fallback `RARE` via catalog)
  - `mappers/test_game_player_state_mapper.gd:1` 3 testes (size 5 `null` fill `INVENTORY_SIZE`)
  - `domain/test_game_power_catalog.gd:1` 4 testes (`FREEZE` offensive GLOBAL, `can_use_while_frozen`, fallback)
  - `domain/test_game_internal_event.gd:1` 7 testes (cells `Vector2i`, `contains_player_id`, `get_cell_x/y`, mapper)
  - `infra/test_json_serializer.gd:1` 4 testes (roundtrip, empty/invalid)
  - `infra/test_websocket_message.gd:1` 4 testes (`ERROR` + `PLAYER_ACTION_RESULT` + `has/get_*`)
- **Fase 4 102/102 verdes 258 asserts <0.5s (2026-09-09)** `game/tests/unit/` 23 arquivos:
  - `viewmodels/test_game_viewmodel_visual_state.gd:1` 8 testes (claimed vs revealed, `HIDDEN` dim)
  - `viewmodels/test_game_viewmodel_deadline.gd:1` 11 testes (`Z` trim, millis/nanos/micros, offset)
  - `viewmodels/test_game_viewmodel_action_lock.gd:1` 8 testes (global locks, cell arms, frozen blocks)
  - `viewmodels/test_word_paint_same_click.gd:1` 2 testes (reveal não repinta)
  - `viewmodels/test_freeze_lock_1_2.gd:1` 2 testes (`1.2s` geração)
  - `infra/test_websocket_first_string.gd:1` 4 testes (root vs data)
  - `infra/test_no_comment_regression.gd:1` 2 testes (sem `#` em `*.gd` / `*.tscn`)
  - `integration/test_remote_game_repository_buffering.gd:1` 4 testes (`_pending_*` flush)
  - `integration/test_websocket_contract_fixtures.gd:1` 10 testes (8 eventos `docs/websocket-events-contract.md:1`)
  - `views/test_game_screen_layout.gd:1` 3 testes (WordsWrapper 72 `clip` + `SIZE_*`, cards 220×70, inventory transparente)
  - `views/test_game_screen_interactivity.gd:1` 4 testes (board disabled, cell revelada)
  - `views/test_power_drag_preview.gd:1` 2 testes (`SWIPE_THRESHOLD 40` `LIFT_Y -10` `1.12` delta ±20)
  - `views/test_matchmaking_cancel_style.gd:1` 3 testes (`found` disabled não hidden)
  - `views/test_home_sair_removed.gd:1` 2 testes (sem `ExitButton`)
- **CLI headless:** `& "Godot_v4.7.1-stable_win64_console.exe" --headless --path game --import` (1x) depois ` --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gexit` ou ` -s addons/gut/gut_cmdln.gd -gexit` (usa `.gutconfig.json`) → `All tests passed!`
- **GUI:** dock `GUT` → `Run All` (não `Run At Cursor` — `RunAtCursor.gd:130` Nil se cursor fora `extends GutTest`) — se `Cannot run` ver acima `Carregar`/`Salvar`

## Como Continuar (outro PC)

1. `git pull` traz `docs/testing-plan.md`, `game/.gutconfig.json`, `game/tests/unit/**`, `game/addons/gut` (se versionado) e este `.opencode/context.md`
2. Instalar Godot 4.7.1 (`Godot_v4.7.1-stable_win64_console.exe` + `_console.exe`)
3. `godot --headless --path game --import`
4. Editor → `Project > Plugins > Gut 9.7.1 Enabled` (não `(Indefinido)`) → dock `GUT` → `Carregar` `res://.gutconfig.json` → `Salvar` → `Run All`
5. `opencode` na raiz (`letra-a-letra-GODOT`) lê este contexto automaticamente

## Próximos Passos Planejados

- **Fase 2/3 concluída 2026-09-06, Fase 4 102/102 concluída 2026-09-09** — ver `docs/testing-plan.md:95` `8b/8c`
- **Fase 5 (próxima):** cobertura `matchmaking` cancel `MatchmakingViewModel` + `Home` sair, poderes `discard_power` UI, `effect_state_changed`/`notification_requested`/`trap_animation_requested` View conecta (pendências `docs/game-feature-analysis.md:320`)
- **Não fazer:** `AnimatedBtn`, `Spinner` addon, layout `.tscn` pixel-perfect
- **Hardening futuro:** `export_presets.cfg:20` `encrypt_pck=true` não afeta testes, `log_debug=false` em prod via provider

## Regras para Novo Opencode

- Nunca instanciar `HttpClient`/`WebSocketClient` fora de `ServiceRegistry` — usar factories `LoginFactory.create()` etc.
- Respeitar `AGENTS.md:12` feature layout + `infrastructure/mappers/` (adicionar para novas features, manter inline para `game`/`matchmaking`)
- Tab indent, `* text=auto eol=lf` (`.gitattributes`), nunca commit `.godot/`
- Antes de editar, ler `AGENTS.md` + este contexto + `docs/testing-plan.md`
