# Plano APK — Letra a Letra Godot + Servidor Java Hospedado

> **Data:** 2026-09-06
> **Engine:** Godot 4.7 `game/project.godot:9` Mobile 360x640 `stretch=canvas_items` portrait `renderer=mobile` `Jolt Physics`
> **Godot root:** `game/` `AGENTS.md:6` — abrir `game/project.godot`, não repo root
> **Backend:** Spring Boot `Letra-a-Letra-API` `http://127.0.0.1:8080` + `ws://127.0.0.1:8080/ws/game` hardcoded `game/core/infrastructure/environment/global_environment.gd:3` `GlobalEnvironment.is_debug_ws_enabled()` `global_environment.gd:5`
> **Autoload order:** `GlobalEnvironment → SessionStore → ServiceRegistry` `game/project.godot:19` (Fase 3 fix)
> **Testes:** `82/82` `219 asserts` GUT 9.7.1 `game/tests/unit` `docs/testing-plan.md:3`

## 1. Como funciona hoje (local)

Godot é só interface — sem servidor embutido. `game/core/infrastructure/network/http/http_client.gd:122` `_build_url()` + `websocket_client.gd:47` `?token=` `AGENTS.md:8` apontam para `127.0.0.1:8080`. Sem backend (`Letra-a-Letra-API` `github.com/Zidan-09`) login/matchmaking falham `F5`.

**Fluxo jogável local `AGENTS.md:41` `ServiceRegistry` DI:**
`Login` `login_viewmodel.gd:12` `POST /user/auth` → `SessionStore.start_session` `autoload/session_store.gd:1` → `SessionPersistence.save user://session.cfg` `session_persistence.gd:4` → `Home` `home_viewmodel.gd:28` `go_to(MATCHMAKING)` → `RemoteMatchmakingRepository.start_search` `WS connect` `MATCHMAKING_GAME SEARCHING/FOUNDED` `remote_matchmaking_repository.gd:24` → `MatchmakingFoundEvent` via `PendingNavigationPayload` `pending_navigation_payload.gd:5` `take_payload()` → `GameFactory.bind` `game_factory.gd:6` `view.setup()` `RemoteGameRepository.start(gameId)` `remote_game_repository.gd:47` flush `_pending_*` `remote_game_repository.gd:53` → `Ws GAME` `PLAYER_ACTION_RESULT/TURN_EXPIRED/GAME_OVER` `game_viewmodel.gd:231` `WebSocketMessage.raw` `websocket_message.gd:26` `_first_string()` `remote_game_repository.gd:341`

## 2. O que muda na sua parte Godot para APK com servidor hospedado

**Só 1 coisa:** trocar `127.0.0.1:8080` para URL hospedada. Hoje `const API_BASE_URL/WS_BASE_URL` `global_environment.gd:3` — APK no celular tentaria `127.0.0.1` do celular e falha.

**Exemplo produção:**

```gdscript
# game/core/infrastructure/environment/global_environment.gd:3
const API_BASE_URL = "https://api.letraaletra.seudominio.com"
const WS_BASE_URL = "wss://api.letraaletra.seudominio.com/ws/game" # wss para https
```

**Provider futuro já adicionado Fase 3 opção A `global_environment.gd:5`:**
`GlobalEnvironment.is_debug_ws_enabled()` `OS.get_environment("DEBUG_WS") != "0"` — mantém `DEBUG_RAW_WS:=true` `websocket_client.gd:7` hoje sem quebrar log `WS IN ->`, permite `DEBUG_WS=0` em prod sem rebuild. Estender para `API_BASE_URL` via `OS.get_environment("API_URL")` ou `ProjectSettings` `api_base_url` export var evita recompilar APK para `staging` vs `prod` (recomendado 5 linhas quando hospedar).

## 3. Gerar APK — passo a passo

**Pré-requisito Android (1x):**
1. `JDK 17` + `Android SDK` `cmdline-tools` + `platform-tools`
2. Godot `Editor > Manage Export Templates > Download` `4.7.2` `godot.windows.opt.tools.64.exe`
3. `Project > Export > Add > Android` — cria `game/export_presets.cfg` (se não existir) `apk` `arm64-v8a` `targetSdk 34` `textures/vram_compression/import_etc2_astc=true` `project.godot:47`
4. `keystore` — debug `keystore/debug.keystore` já funciona; release `keytool -genkey -keystore release.keystore` + `Export > Keystore/user/pass` (sem release APK não instala fora Play `INSTALL_PARSE_FAILED`)

**Build Editor (teste local):**
`Project > Export > Android > Export Project` → `letra-a-letra.apk` `~30MB` `config/name="Letra a Letra"` `project.godot:13` `icon uid://dy1fknvv40pop` `boot_splash` `project.godot:16`

**Build CLI (CI `docs/testing-plan.md:85`):**
```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path game --export-release "Android" ../build/letra.apk
```

**Conteúdo APK:** `.godot/` gitignore `AGENTS.md:40` não vai; `game/.gutconfig.json:1` GUT só debug; `encrypt_pck` `export_presets.cfg` não quebra testes headless

## 4. Fluxo quando pessoa baixar APK com servidor hospedado

**Instalação:** baixa `apk` (Drive/Play Internal) → `Android > Instalar` (fontes desconhecidas) → `Letra a Letra` ícone `project.godot:13`

**Com conta já no backend hospedado:**
1. `Login` `login_screen.tscn` `email/senha` PT-BR `AGENTS.md:9` → `HttpClient http_post /user/auth` `global_environment.gd:3` agora `https://...` → `200 + {user, token}` → `SessionStore.start_session` + `SessionPersistence.save`
2. `Home` `home_screen.gd:12` `load_user()` `PlayerCard` `nickname`; fechar/reabrir → `SessionPersistence.restore` `session_persistence.gd:21` auto-login `user://session.cfg`
3. `Play > Matchmaking` `home_viewmodel.gd:28` `WS connect` `wss://.../ws/game?token=...` `websocket_client.gd:47` → `SEARCHING` → `FOUNDED` `turnEndsAt` `remote_matchmaking_repository.gd:24` → `GameScreen` `game_screen.gd:106` `GameFactory.bind` → joga `REVEAL` `remote_game_repository.gd:73` `type:REVEAL position{x,y}` + poderes `use_global_power` `remote_game_repository.gd:105` via `WS` `game_viewmodel.gd:94` `_lock_action` `3.0s` `game_viewmodel.gd:17` `get_cell_visual_state` `game_viewmodel.gd:231` `CLAIMED>REVEALED>HIDDEN`
4. Sair `leave_game` `remote_game_repository.gd:124` `type:LEFT_GAME` → `go_to(HOME)` `game_viewmodel.gd:187`

**Sem conta:** `Register` `register_screen` → `register_usecase.gd:21` `POST register` → auto `login` → Fase 3 fix `success=false` volta Login `Cadastro realizado! Mas...` `register_usecase.gd:24`

## 5. Backend hospedado requisitos

- `Letra-a-Letra-API` em `Render/Railway/Fly` + `Postgres` + `ws://.../ws/game` exposto `wss` cert `Let's Encrypt`
- `CORS` liberado `*` para `http-origin` APK ( `HTTPRequest` não precisa, `WebSocketPeer` sim)
- `JWT` mesma secret entre API e `SessionStoreAuthProvider` `session_store_auth_provider.gd:1`
- `API_BASE_URL`/`WS_BASE_URL` iguais entre Godot e API `GlobalEnvironment`

## 6. Trade-offs antes de exportar

- **URL hardcoded vs env:** hoje recompila APK para trocar `127.0.0.1` → `https://`. Transformar `global_environment.gd:3` em `ProjectSettings api_base_url` export var evita rebuild por env
- **wss vs ws:** local `ws://`, prod `wss://` — `is_debug_ws_enabled()` pode escolher `ws/wss` por `API_BASE_URL` contém `https`
- **APK debug vs aab release:** debug instala direto, Play exige `aab` + `keystore release`

## 7. Validação

```powershell
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path game --import
& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gexit
# 82/82 All tests passed! + F5 manual Login → Home → Sala (Salas em breve!)
```
