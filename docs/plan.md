# Plano — Tela de Loading (Login → Loading → Home)

> Documento de planejamento. Nenhum código da aplicação foi alterado para produzi-lo.
> Todas as afirmações abaixo foram verificadas no repositório em `game/` e em `docs/api.json`.
> Convenção do projeto (cf. `AGENTS.md`): comentários e strings PT-BR, identificadores em inglês, indentação com Tab, `* text=auto eol=lf`.

---

## 1. Análise da implementação atual

### 1.1 Fluxo atual de Login → Home (verificado)

Cena inicial do app (`game/project.godot:14`):

```text
run/main_scene="uid://bh236m1jcaled" = game/features/main/presentation/views/main_screen.tscn
```

Passo a passo real (arquivo:linha aproximada):

1. `game/features/main/presentation/views/main_screen.gd:19-24` — `_ready()` cria `MainFactory.create()`, conecta popups, inicia `_start_logo_animation()` e `_start_top_animation()`. Não há checagem de sessão.
2. Botão Email (`main_screen.tscn:200`, conexão `:258`) → `_on_email_btn_pressed()` (`main_screen.gd:158`) → `_open_login()` (`:55`) → `login_popup.open()`. Existe também a tela standalone `game/features/login/presentation/views/login_screen.gd:23` (`LoginFactory.create()`, botão `LoginBtn → _on_login_btn_pressed`, `login_screen.tscn:116`).
3. `login_screen.gd:96-107` / `login_popup.gd:46-53` validam campos vazios (`shake()` + `error_label.show_error(...)`) e chamam `_view_model.login(email, password)`.
4. `game/features/login/main/factory/login_factory.gd:4-15` monta:
   `RemoteLoginRepository.new(services.http_client())` + `services.user_repository()` + `SessionStore` → `LoginUseCase` → `LoginViewModel(usecase, services.navigation_service())`.
5. `game/features/login/presentation/viewmodels/login_viewmodel.gd:19-40` — `_clear_error()`, `_set_loading(true)`, `await _usecase.execute(...)`, `_set_loading(false)`; se `success` → `_navigation.go_to(AppRoutes.SHELL)` (`:37`); senão `_set_error(result.message)`.
6. `game/features/login/application/usecases/login_usecase.gd:17-31`:
   - `await _login_repository.login(request)` → `game/features/login/infrastructure/repositories/remote_login_repository.gd:10` → `HttpClient.http_post("/user/auth", {"email","password"})`.
   - Em caso de sucesso, `await _user_repository.fetch_current_user(result.access_token)` → `game/features/user/infrastructure/repositories/remote_user_repository.gd:9-16` → `HttpClient.http_get("/user/me", access_token)`.
   - Se `user == null`, retorna `LoginResult(false, null, "", "Unable to load user profile.")` — login é considerado falha.
   - Senão `_session_store.start_session(user, result.access_token)` (`login_usecase.gd:29`).
7. `game/autoload/session_store.gd:12-17` — guarda `_current_user: User` + `_access_token: String` em memória, emite `session_started` / `session_changed`.
8. `game/core/presentation/navigation/navigation_service.gd:4-10` — `go_to()` = `tree.call_deferred("change_scene_to_file", scene)`. Troca de cena raiz, sem pilha.
9. Destino: `AppRoutes.SHELL` (`game/core/presentation/navigation/app_routes.gd:7` = `features/shell/presentation/views/shell_screen.tscn`), e **não** `AppRoutes.HOME` direto.
10. `game/features/shell/main/factory/shell_factory.gd:4-11` — `NavigationManager.new(view.page_container)` + `register_page(PAGE_SHOP→SHOP, PAGE_INVENTORY→INVENTORY, PAGE_PLAY→HOME, PAGE_SOCIAL→SOCIAL, PAGE_ROOMS→ROOMS)`.
11. `game/features/shell/presentation/views/shell_screen.gd:18-25` — `_ready()` faz `ShellFactory.bind(self)`; `setup()` conecta `navbar.page_selected → manager.select` e seleciona `PAGE_PLAY` como aba inicial. Ou seja, a Home é instanciada **dentro** do Shell.
12. `game/features/home/presentation/views/home_screen.gd:63-69` — `_ready()` faz `HomeFactory.create()`, conecta sinais e chama `_view_model.load_user()` **sempre, sem cache**.
13. `game/features/home/application/usecases/get_current_user_usecase.gd:11-15` — lê `SessionStore.get_token()` e refaz `fetch_current_user(token)` (`GET /user/me`). Falha → `HomeViewModel` emite erro `"Usuário não encontrado."` (`home_viewmodel.gd:27-29`) e a tela fica com zeros.

O fluxo de registro é idêntico no destino: `game/features/register/presentation/viewmodels/register_viewmodel.gd:35-36` → `go_to(AppRoutes.SHELL)` após sucesso.

Rotas existentes (`game/core/presentation/navigation/app_routes.gd:4-13`): `LOGIN, REGISTER, HOME, SHELL, SHOP, INVENTORY, SOCIAL, ROOMS, MATCHMAKING, GAME`. Não existe rota de Loading.

### 1.2 Estrutura das telas envolvidas

| Tela | Cena | Script | Padrão |
|---|---|---|---|
| Main (inicial) | `game/features/main/presentation/views/main_screen.tscn` (259 linhas) | `main_screen.gd` (178 linhas) | `Control` raiz + `MainFactory` + `MainViewModel` (só `login_with_google()` / `continue_as_guest()` stub com erro "em breve!") |
| Login popup | `game/features/login/presentation/views/login_popup.tscn` | `login_popup.gd` | Aberto sobre a Main; mesmos sinais `closed` / `switch_requested` |
| Login standalone | `game/features/login/presentation/views/login_screen.tscn` | `login_screen.gd` (167 linhas) | `LoginFactory.create()` no `_ready()` |
| Register | `game/features/register/presentation/views/*` | `register_viewmodel.gd` | Espelho do login |
| Shell | `game/features/shell/presentation/views/shell_screen.tscn` | `shell_screen.gd` | `Background(home.png)` + `PageContainer` + `Navbar`; `ShellFactory.bind()`; aba inicial `PAGE_PLAY` |
| Home | `game/features/home/presentation/views/home_screen.tscn` | `home_screen.gd` (266 linhas), `home_viewmodel.gd` (73 linhas) | `extends HubPage`; `HomeFactory.create()`; `load_user()` no `_ready()` |

Navegação interna do Shell: `game/core/presentation/navigation/navigation_manager.gd` (`register_page`, `select`, slide 0.25s, `can_leave/enter/exit` de `HubPage`). Só vale dentro do Shell.

### 1.3 Como HTTP é utilizado

- `game/core/infrastructure/network/http/http_client.gd` (`class_name HttpClient extends Node`, 182 linhas): `http_get/post/put/delete/patch(endpoint, body, access_token)` → `_request()` (`:74-105`) cria um `HTTPRequest` temporário por chamada, `await request_completed`, `queue_free()`, `_parse_response()`.
- URL: `_build_url()` (`:135-139`) = `GlobalEnvironment.API_BASE_URL + endpoint`. Base hardcoded em `game/core/infrastructure/environment/global_environment.gd:3-4` (`http://127.0.0.1:8080`, `ws://127.0.0.1:8080/ws/game`), espelhada em `game/project.godot:21-22`. Backend precisa estar rodando.
- Auth: `_build_headers()` (`:108-124`) sempre envia `Content-Type: application/json` + `Authorization: Bearer <token>`, onde token = parâmetro explícito ou `_auth_provider.get_token()`. O provider é `game/core/infrastructure/network/auth/session_store_auth_provider.gd` (delega a `SessionStore.get_token()`), injetado em `game/autoload/service_registry.gd:20-23` (`HttpClient.new(auth_adapter)`). Ou seja, **Bearer é automático após o login**; só o `POST /user/auth` roda sem token.
- Resposta: `game/core/infrastructure/network/http/http_response.gd` (`status_code, success, body: Dictionary, error_message`; helpers `is_client_error/is_server_error/is_unauthorized(401)/is_not_found`). `success = 200 <= code < 300`; `error_message = body["message"]` se presente (`http_client.gd:142-165`). Falha ao iniciar request → `HttpResponse(0, false, {}, "Failed to execute request.")` (`:99`).
- Padrão de chamada (ex. `remote_login_repository.gd:10-16`): `await _http_client.http_post(...)`, `if not response.success: return erro`, senão mapper sobre `response.body`.

### 1.4 Como cada um dos quatro conjuntos de dados é obtido hoje

Verificado por leitura recursiva das features + `grep http_get/post/patch` + `docs/api.json` (lista completa de paths obtida por script; ver §1.7).

**1. Perfil do jogador — JÁ EXISTE stack completa.**

- Repository: `game/features/user/infrastructure/repositories/remote_user_repository.gd:9-16` — `fetch_current_user(access_token) → GET /user/me`.
- Mapper: `game/features/user/infrastructure/mappers/user_mapper.gd` — `from_response_body(body)` lê `body.data.user` (`stats{level,experience,totalWins,winStreak,totalMatches,rankingPoints}`, `wallet{coins,gems}`, `equipped[]{type,equipped,name}`).
- Modelo: `game/core/domain/entities/user.gd` (`class_name User`; única entidade global; `to_dictionary/from_dictionary/copy/is_valid`).
- Contrato: `game/core/application/contracts/repositories/user_repository.gd`.
- UseCase: `game/features/home/application/usecases/get_current_user_usecase.gd` (lê `SessionStore.get_token()`).
- ViewModel: `game/features/home/presentation/viewmodels/home_viewmodel.gd:22-33` (`load_user()` → sinais `user_loaded` / `profile_changed`).
- Armazenamento: `SessionStore._current_user` (global) + `HomeViewModel._profile: HomePlayerProfile` (volátil, por instância). `HomePlayerProfile.from_user()` em `game/features/home/domain/home_player_profile.gd`.
- Endpoint confirmado no backend: `GET /user/me → SuccessResponseGetMyProfileResponse{data: GetMyProfileResponse{user: UserResponse}}` (`docs/api.json:1579`).
- Atenção: `LoginMapper` (`game/features/login/infrastructure/mappers/login_mapper.gd:6-48`) parseia o `POST /user/auth` em formato **flat** (`data.token` + `User.from_dictionary`), enquanto `UserMapper` parseia o `GET /user/me` em formato **aninhado**. São dois parsers diferentes — não unificar neste plano.

**2. Amigos — JÁ EXISTE stack completa (única das 4 além do perfil).**

- Repository: `game/features/social/infrastructure/repositories/remote_friend_repository.gd` — `fetch_friends(page,size) → GET /friend?page=&size=&sort=requestDate,desc` (`:13-22`); `fetch_pending() → GET /friend/pending` (`:25-29`); `fetch_sent() → GET /friend/pending/sent` (`:32-36`); mutações `POST /friend/request`, `PATCH /friend/accept|reject|cancel|remove`. Erro padronizado `{"error": ...}` via `_message_or_default()` (`:89-92` → `response.error_message` ou `"Falha de conexão. Tente novamente."`).
- Mapper: `game/features/social/infrastructure/mappers/friend_mapper.gd` — `page_from_body` (`data.content[]` + `page/totalPages/totalElements`), `pending_from_body` (`data.requests[]`).
- Modelo: `game/features/social/domain/models/friendship.gd` (`class_name Friendship`).
- Contrato: `game/core/application/contracts/repositories/friend_repository.gd` (8 métodos).
- UseCase: `game/features/social/application/usecases/friends_usecase.gd` (passthrough + `my_id()` via `SessionStore.get_user().id`).
- ViewModel: `game/features/social/presentation/viewmodels/social_viewmodel.gd` — estado **volátil por instância** (`_friends/_pending/_sent_requests`, paginação `DISCOVER_PAGE_SIZE=6`); `load_all()` = `load_friends_page(0) + refresh_pending() + refresh_sent()`; `enter()` da view chama `load_all()` (`social_screen.gd`).
- Factory: `game/features/social/main/factory/social_factory.gd` — instancia `RemoteFriendRepository.new(services.http_client())` localmente (não está no `ServiceRegistry`).
- Endpoints confirmados: `/friend`, `/friend/pending`, `/friend/pending/sent`, `/friend/request`, `/friend/accept|reject|cancel|remove` (`docs/api.json`).

**3. Itens da loja — NÃO EXISTE nada no client Godot.**

- `game/features/shop/` contém apenas `presentation/views/shop_screen.gd` (6 linhas, `extends HubPage`, `page_id() &"shop"`) + `shop_screen.tscn`. Sem `application/`, `domain/`, `infrastructure/`, `factory`, `viewmodel`, `repository`, `usecase`, `mapper`.
- `grep http_*` em `game/` retorna zero ocorrência de `shop/store/offer/cosmetic` como endpoint consumido.
- Backend **tem**: `GET /shop/offers → SuccessResponseGetActiveOffersResponse{data: GetActiveOffersResponse{offers: Offer[]}}` (`docs/api.json:1818`); `Offer{offerId,title,coinType(SOFT|HARD|REAL),price,rewards[],repeatable,active,hasExpiration,...}`. Também `GET /offer`, `POST /shop/offers/{offerId}/buy`. O Loading deve usar `GET /shop/offers`.
- Conclusão: será preciso **criar** a stack shop (contract + repository + mapper + model + usecase) espelhando `social/`. Não é "arquitetura nova", é preencher a feature existente seguindo o layout exigido pelo `AGENTS.md`.

**4. Inventário do jogador — NÃO EXISTE consumo de backend no client.**

- `game/features/inventory/` contém apenas `presentation/views/inventory_screen.gd` (335 linhas, catálogo hardcoded `_build_catalog()` com `preload("res://assets/...")`, `_equipped/_selected/_catalog` voláteis por instância) + `inventory_screen.tscn`. Sem repository/usecase/mapper/viewmodel/factory. Não confundir com `game/assets/components/game/inventory/` (poderes em partida via WS, `GamePlayerState.inventory` de 5 slots — outro domínio).
- Backend **tem**: `GET /user/inventory → SuccessResponseGetMyInventoryResponse{data: GetMyInventoryResponse{inventory: InventoryItemResponse[]}}` (`docs/api.json:1599`); `InventoryItemResponse{cosmeticId,name,type(AVATAR|BANNER|EMOTE|FRAME),equipped,assetPath}`. Também `GET /user/{userId}/inventory` (paginado, admin/outro usuário — **não** usar no Loading).
- Conclusão: idem à loja — **criar** stack inventory espelhando `social/` (`GET /user/inventory`).

### 1.5 Onde os dados são armazenados / estado global

- Único estado global mutável: `game/autoload/session_store.gd` (`_current_user`, `_access_token`, `_current_game_id`; `start_session/end_session/is_authenticated/has_session/get_user/get_token`; sinais `session_started/session_ended/session_changed`). Só sessão, sem disco nesta classe.
- Singletons compartilhados: `game/autoload/service_registry.gd` — `_http_client`, `_user_repository` (**único repository global**), `_websocket_client`, `_matchmaking_repository`, `_game_repository`, `_navigation_service`, `_pending_navigation_payload`, `_session_persistence`, `_current_user_provider`. `FriendRepository` **não** está aqui (instanciado por `SocialFactory`). Não há `ShopStore`, `InventoryStore`, cache ou `shared/` stateful (`game/shared/` só tem helpers stateless: `cosmetics/cosmetic_art.gd`, `components/navbar/`, `animation/`).
- Persistência em disco: `game/core/infrastructure/persistence/session_persistence.gd` (`user://session.cfg` + `user://session_<id>.cfg`) — **código morto hoje**: ninguém chama `save/restore/clear` (só instancia em `service_registry.gd:19`). Não há auto-login ativo; `MainScreen` nunca consulta `is_authenticated/has_session`.
- Cache de Views (não de dados): `NavigationManager._instances[page_id]` mantém a `Control` instanciada enquanto o Shell vive.
- Ordem dos autoloads (`game/project.godot:24-28`): `GlobalEnvironment → SessionStore → ServiceRegistry`.

### 1.6 Como a Home carrega seus dados hoje e como as features acessam loja/inventário/perfil/amigos

- Home (`home_screen.gd:63-69`): sempre refaz `GET /user/me` via `GetCurrentUserUseCase`; monta `HomePlayerProfile`; preenche labels/moedas/stats/cosméticos (`AVATAR_COSMETICS` locais). Não lê `SessionStore.get_user()` diretamente nem recebe payload de navegação.
- Loja/Inventário: telas mock acessadas pelas abas do Shell (`ShellFactory` → `AppRoutes.SHOP/INVENTORY`); nenhum dado de rede.
- Perfil: via Home (acima) e via `LoginUseCase` (no login).
- Amigos: via `SocialScreen.enter() → SocialViewModel.load_all()` (refetch paginado a cada entrada na aba).

### 1.7 Componentes/classes relevantes (índice de arquivos)

- Navegação: `game/core/presentation/navigation/app_routes.gd`, `navigation_service.gd`, `navigation_manager.gd`, `hub_page.gd`, `pending_navigation_payload.gd`.
- Auth/sessão: `game/autoload/session_store.gd`, `game/autoload/service_registry.gd`, `game/core/infrastructure/environment/global_environment.gd`, `game/core/infrastructure/network/auth/session_store_auth_provider.gd`, `game/core/infrastructure/persistence/session_persistence.gd`.
- HTTP: `game/core/infrastructure/network/http/http_client.gd`, `http_response.gd`.
- MVVM: `game/core/presentation/viewmodel/base_viewmodel.gd` (`loading_changed/error_changed`, `_set_loading` com dedupe, `_set_error/_clear_error`).
- Login: `features/login/{application/usecases/login_usecase.gd, domain/login_request.gd, domain/login_result.gd, infrastructure/repositories/remote_login_repository.gd, infrastructure/mappers/login_mapper.gd, main/factory/login_factory.gd, presentation/viewmodels/login_viewmodel.gd, presentation/views/login_screen.gd + login_popup.gd}`.
- Registro: `features/register/*` (espelho; `register_viewmodel.gd:35-36` → SHELL).
- User/perfil: `features/user/infrastructure/{repositories/remote_user_repository.gd, mappers/user_mapper.gd}`, `core/domain/entities/user.gd`, `core/application/contracts/repositories/user_repository.gd`, `features/home/{application/usecases/get_current_user_usecase.gd, domain/home_player_profile.gd + home_game_mode.gd, main/factory/home_factory.gd, presentation/viewmodels/home_viewmodel.gd}`.
- Social: `features/social/{application/usecases/friends_usecase.gd, domain/models/friendship.gd, infrastructure/repositories/remote_friend_repository.gd, infrastructure/mappers/friend_mapper.gd, main/factory/social_factory.gd, presentation/viewmodels/social_viewmodel.gd}` + contrato `core/application/contracts/repositories/friend_repository.gd`.
- Main: `features/main/{presentation/views/main_screen.tscn + main_screen.gd, presentation/viewmodels/main_viewmodel.gd, main/factory/main_factory.gd}`.
- Shell: `features/shell/{presentation/views/shell_screen.tscn + shell_screen.gd, main/factory/shell_factory.gd}`.
- UI reutilizável: `game/assets/components/*.tscn` (ex. `password_input` com `shake()`, `animated_error_label`), `game/assets/styles/buttons/*.tres` (`orange/blue/white/...`), `game/shared/animation/{animated_btn.gd, animated_error_label.gd, animated_input.gd}`. **Não existe `ProgressBar`/`TextureProgressBar` no jogo** (só no addon GUT e um `Spinner` circular em `PlayerCard.tscn`).
- Testes: GUT 9.7.1 (`game/addons/gut`), `game/tests/unit/{views,viewmodels,mappers,infra,integration}` + `tests/helpers/fake_*.gd`; comando em `AGENTS.md`.
- Backend (somente leitura, sem alterar): `docs/api.json` — endpoints de interesse `POST /user/auth`, `GET /user/me`, `GET /user/inventory`, `GET /shop/offers`, `GET /friend`, `GET /friend/pending`, `GET /friend/pending/sent`.

### 1.8 Arquitetura/padrão vigente (a reutilizar)

Clean Architecture feature-first (`AGENTS.md`): cada feature em `game/features/<nome>/` com `main/factory/` (`Factory.create()` estático) → `application/usecases/` → `domain/` (requests/results/models) → `infrastructure/repositories/` (`Remote*` estendendo contrato em `core/application/contracts/`) + `infrastructure/mappers/` → `presentation/views/` (`.tscn` + `.gd`) + `presentation/viewmodels/` (`extends BaseViewModel`). Regra de dependência: view → viewmodel → usecase → repository. Serviços compartilhados **somente** via autoload `ServiceRegistry` (`http_client()`, `user_repository()`, `navigation_service()` etc.) — nunca instanciar `HttpClient`/`NavigationService` na feature. Telas registradas em `AppRoutes`; navegação via `ServiceRegistry.navigation_service().go_to(AppRoutes.X)` ou `NavigationService` injetado no viewmodel. Tudo assíncrono com `await`; viewmodels emitem `loading_changed/error_changed`; views apenas conectam sinais e nunca bloqueiam.

---

## 2. Arquitetura proposta

### 2.1 Princípio

Nenhuma arquitetura nova. A Loading Screen será **uma feature comum** (`game/features/loading/`) no layout exigido pelo `AGENTS.md`, mais o **preenchimento das stacks ausentes** de `shop/` e `inventory/` (espelhando `social/`). O cache dos dados pré-carregados ficará num **store simples detido pelo `ServiceRegistry`** (sem criar autoload novo nem alterar ordem de autoloads), acessível às telas via factories — o mesmo papel que `ServiceRegistry.user_repository()` já cumpre hoje.

### 2.2 Componentes novos e responsabilidades

```text
LoginViewModel / RegisterViewModel
  │  (antes: go_to(SHELL))
  ▼
AppRoutes.LOADING ──► LoadingScreen (view, derivada da Main)
  │                     │ _ready(): LoadingFactory.create() → LoadingViewModel
  │                     ▼
  │                   LoadingViewModel (extends BaseViewModel)
  │                     │ sinais: progress_changed(0..1), loading_changed, error_changed, loaded
  │                     ▼
  │                   LoadInitialDataUseCase (coordena as 4 cargas + escreve no store)
  │                     ├── GetCurrentUserUseCase (EXISTENTE, GET /user/me)
  │                     ├── ShopUseCase.fetch_offers (NOVO, GET /shop/offers)
  │                     ├── InventoryUseCase.fetch_my_inventory (NOVO, GET /user/inventory)
  │                     └── FriendsUseCase.fetch_friends+pending+sent (EXISTENTE, GET /friend*)
  │                     ▼
  │                   InitialDataStore (NOVO, RefCounted detido pelo ServiceRegistry)
  │                     { user, offers[], inventory[], friends, pending, sent, loaded_at }
  ▼
AppRoutes.SHELL ──► Shell → Home (lê SessionStore/InitialDataStore, sem refetch imediato)
```

| Componente | Responsabilidade | Onde mora |
|---|---|---|
| `LoadingScreen` | Clonar visual da Main; exibir `ProgressBar` + status + erro + retry; delegar tudo ao viewmodel; nunca chamar HTTP | `game/features/loading/presentation/views/loading_screen.{tscn,gd}` |
| `LoadingViewModel` | Orquestrar `LoadInitialDataUseCase.execute()` com callback de progresso; converter em `progress_changed`; decidir `go_to(SHELL)` / erro / `go_to(LOGIN)` em 401; expor `retry()` | `game/features/loading/presentation/viewmodels/loading_viewmodel.gd` |
| `LoadInitialDataUseCase` | Disparar as 4 cargas em paralelo (ver §6), contar conclusões, gravar cada resultado no `InitialDataStore`, agregar primeiro erro | `game/features/loading/application/usecases/load_initial_data_usecase.gd` |
| `ShopRepository` + `ShopMapper` + `ShopOffer` + `ShopUseCase` | `GET /shop/offers` → `Offer[]` (NOVO, espelho de `social/`) | `game/features/shop/{infrastructure,domain,application}/` + contrato em `core/application/contracts/repositories/shop_repository.gd` |
| `InventoryRepository` + `InventoryMapper` + `InventoryItem` + `InventoryUseCase` | `GET /user/inventory` → `InventoryItem[]` (NOVO, espelho de `social/`) | `game/features/inventory/...` + contrato `.../inventory_repository.gd` |
| `InitialDataStore` | Cache em memória dos 4 payloads + `is_ready()/clear()`; única fonte para Home/Shop/Inventory/Social no primeiro acesso | `game/core/application/stores/initial_data_store.gd` (instância única criada e exposta pelo `ServiceRegistry`) |
| `LoadingFactory` | Montar viewmodel + usecase com dependências do `ServiceRegistry` (+ `SessionStore`), como `LoginFactory`/`SocialFactory` fazem | `game/features/loading/main/factory/loading_factory.gd` |

Por que o store fica no `ServiceRegistry` e não é um autoload novo: evita alterar `game/project.godot:24-28` (ordem `GlobalEnvironment → SessionStore → ServiceRegistry`), evita novo singleton global desnecessário (vedado pelo item "Requisitos arquiteturais"), e segue o precedente de `user_repository()`/`pending_navigation_payload()` já centralizados ali. Alternativa considerada e **rejeitada**: estender `SessionStore` com ofertas/inventário/amigos — poluiria um store de sessão com domínios alheios e forçaria sinais de sessão a cada preload.

### 2.3 O que é reutilizado sem duplicar

- `HttpClient`/`HttpResponse`/`SessionStoreAuthProvider` (Bearer automático), `BaseViewModel`, `AppRoutes`/`NavigationService`, `SessionStore`, `ServiceRegistry.user_repository()`, `GetCurrentUserUseCase`, `RemoteUserRepository`/`UserMapper`/`User`, `RemoteFriendRepository`/`FriendMapper`/`Friendship`/`FriendsUseCase`, `HomePlayerProfile`, `animated_error_label.gd` (`show_error()`), assets da Main (ver §4). Loja/inventário **não** reutilizam `inventory_screen.gd` atual (mock local) como fonte de dados — só como referência de layout futuro; a tela de Loading não depende delas.

---

## 3. Fluxo detalhado

```text
Login concluído → abertura da Loading → disparo dos carregamentos
→ atualização do progresso → conclusão → navegação para Home (via Shell)
```

1. Usuário submete credenciais no `LoginPopup`/`LoginScreen` (ou registra-se). `LoginUseCase.execute()` faz `POST /user/auth` + `GET /user/me` e `SessionStore.start_session(user, token)` — **inalterado**.
2. `LoginViewModel.login()` (e `RegisterViewModel.register()`), hoje com `go_to(AppRoutes.SHELL)`, passam a `go_to(AppRoutes.LOADING)` — única mudança nesses arquivos (ver §9).
3. `loading_screen.tscn` abre. `loading_screen.gd._ready()` faz `LoadingFactory.create()`, conecta `progress_changed/loading_changed/error_changed/loaded`, preserva animações do logo/células (copiadas da Main), zera a barra (`0%`) e chama `_view_model.start()`.
4. `LoadingViewModel.start()` guarda contra reentrância (`if _loading: return`), limpa erro, chama `await _usecase.execute(func(completed, total): ...)` — o usecase invoca o callback a cada carga concluída; o viewmodel emite `progress_changed(completed/total)` e, ao fim, se tudo OK emite `loaded` e `go_to(AppRoutes.SHELL)`; se erro, `_set_error(...)` e permanece na tela com botão Tentar novamente visível.
5. `LoadInitialDataUseCase.execute()` dispara as 4 cargas **em paralelo** (ver §6): perfil (`GET /user/me`), ofertas (`GET /shop/offers`), inventário (`GET /user/inventory`), amigos (`GET /friend` pág. 0 + `pending` + `sent` — ver decisão no §5.4). Cada conclusão grava no `InitialDataStore` e incrementa o contador (callback de progresso). Falhas são coletadas; 401 em qualquer uma = erro de autenticação (ver §8).
6. Barra chega a `100%` somente quando os 4 grupos obrigatórios estão no store. Só então navega para `SHELL`.
7. `Shell` abre na aba `PAGE_PLAY` (Home) como hoje. `Home` passa a ler o perfil do `InitialDataStore`/`SessionStore` no primeiro acesso em vez de refazer `GET /user/me` imediatamente (ver §9; comportamento de refresh manual posterior permanece). Shop/Inventory/Social fazem o mesmo com seus slices do store, com fallback a fetch próprio se o store estiver vazio (ex. abertura futura sem passar pelo Loading — defesa, não caminho principal).

---

## 4. Loading Screen

### 4.1 Cena/script base a reutilizar

- Base: **copiar** `game/features/main/presentation/views/main_screen.tscn` → `game/features/loading/presentation/views/loading_screen.tscn` e `main_screen.gd` → `loading_screen.gd` como ponto de partida (não herdar por cena aninhada: a Main contém `LoginPopup`/`RegisterPopup` e 3 botões com conexões que não fazem sentido no Loading; herança traria acoplamento frágil).
- Script base: `main_screen.gd:4-7,74-151` (`@onready` de `Background/Main/Logo/cells`, `_start_logo_animation()`, `_start_top_animation()` + consts `CELL_*` e `_add_cell_flight()`). Copiar esses blocos **sem alterar valores** para preservar identidade e movimento.
- ViewModel/factory base: espelhar `login_viewmodel.gd` + `login_factory.gd` (injeção via `ServiceRegistry`, sinais `loading/error`), não o `MainViewModel` (que é stub de botões).

### 4.2 O que será reaproveitado (mesmos `res://`, sem duplicar arquivos)

- `Background.texture = res://assets/images/backgrounds/vertical_clean.jpg` (nó `Background`, `main_screen.tscn`).
- Células `res://assets/images/cells/l-cell.png`, `a-cell.png`, `l-cell-right.png` + `HBoxContainer` central (`anchor top/bottom 0.5, offset -214.5/-114.5`).
- `Logo` `AtlasTexture(atlas=res://assets/images/logo/lal.png, region=Rect2(52,140,398,226))`, `min 320x181`, centrado, `z_index 2`.
- Animações: pulso do logo (`scale 1.0↔1.05`, `1.5s`, `TRANS_SINE/EASE_IN_OUT`) e voo das células (consts `CELL_FLIGHT_TIME 0.45, LAUNCH_STAGGER 0.3, APEX_HOLD 0.45, FALL_STAGGER 0.5, END_PAUSE 0.05, REST_SCALE 0.85, TILT 0.15, FINAL_SCALE 1.2`; `pivot=size*0.1`; offsets/tilts/rest_shifts idênticos).
- `ErrorLabel` com `shared/animation/animated_error_label.gd` (`show_error()` com fade 0.3s + 3s + 0.5s).
- Estilos de botões **apenas** para o botão Retry (reutilizar `orange_button_default.tres`-like já usado no `EmailBtn`; ver `main_screen.tscn:209-211`).

### 4.3 O que será removido

- Os três `Button`s em `Main/ButtonsBox` (`GoogleBtn/EmailBtn/GuestBtn`, `main_screen.tscn:181-235`) e suas conexões (`:257-259` → `_on_google/email/guest_btn_pressed`), os `@onready` dos botões (`main_screen.gd:8-10`), `_connect_popups/_open_login/_open_register/_close_all_popups/_is_any_popup_open` e os nós `LoginPopup/RegisterPopup` (`main_screen.tscn:249-255`). A Loading não autentica — ela só aparece **após** `start_session`.
- Lógica de `MainViewModel` (stub "em breve!") — não reutilizar.

### 4.4 Barra e elementos novos

- Dentro do `ButtonsBox` existente (mantém `anchors top/bottom=1.0, offset_top=-278, offset_bottom=-66, separation=16, alignment=2` — **mesma região dos botões**, exigência do pedido), adicionar:
  - `StatusLabel: Label` ("Carregando dados...", depois "Loja pronta…", etc. — opcional, texto PT-BR).
  - `LoadingBar: ProgressBar` (`min 0, max 100, value 0, show_percentage=false`, `custom_minimum_size ≈ Vector2(280, 22)`, `size_flags_horizontal=4` como os botões) — começa vazia, preenche da esquerda para a direita via `value = progress * 100` (view conecta `progress_changed`).
  - `ErrorLabel` (reaproveitado) + `RetryBtn: Button` (texto "TENTAR NOVAMENTE", `visible=false`, mesmo estilo laranja) + `BackBtn: LinkButton` ("Voltar ao login", `visible=false`, só em 401 — ver §8).
- Estilo da barra: **não existe** `ProgressBar`/`StyleBox` de barra no projeto (verificado: só `assets/styles/buttons|input|player_color/*.tres`). Criar **dois** `StyleBoxFlat` novos em `game/features/loading/assets/styles/` (ex. `loading_bar_bg.tres` — trilho escuro `#1A2340` radius 11 — e `loading_bar_fill.tres` — preenchimento laranja `#E67F20` radius 11, coerente com `orange_button_default.tres`), aplicados a `theme_override_styles/background|fill`. Animação de `value` com `Tween` curto (`0.25s`) no setter da view para suavizar saltos do paralelo. Nenhum asset de imagem novo.

---

## 5. Carregamento HTTP

Todos via `HttpClient` com Bearer automático (sessão já iniciada). Tabela por recurso:

### 5.1 Perfil — REUTILIZAR (nada novo no repository)

- Endpoint: `GET /user/me` (`RemoteUserRepository.fetch_current_user`, `remote_user_repository.gd:9-16`).
- Método: `GetCurrentUserUseCase.execute() → User` (`get_current_user_usecase.gd:11-15`).
- Modelo: `User` (`core/domain/entities/user.gd`) via `UserMapper.from_response_body` (`body.data.user`).
- Armazenamento: `SessionStore` (atualiza `_current_user` — o login já gravou um `User` flat do `/user/auth`; o Loading sobrescreve com o `User` completo do `/user/me`) **e** `InitialDataStore.user`.
- Notificação: retorno do `await` dentro do `LoadInitialDataUseCase`; erro = `null` (repository retorna `null` em `!success` — sem mensagem). O usecase do Loading deve tratar `null` como `{"error": "Não foi possível carregar o perfil."}` para padronizar com os demais.
- Erros propagados: `null` genérico; 401 vira "sessão expirada" (ver §8; `HttpResponse.is_unauthorized()` disponível mas o repository atual descarta o status — o Loading precisará do `HttpResponse` ou de um novo método que o preserve; ver §10, item `fetch_current_user_result`).

### 5.2 Loja — CRIAR stack (espelho de `social/`)

- Endpoint: `GET /shop/offers` (`docs/api.json:1818`, `GetActiveOffersResponse{offers: Offer[]}`).
- A criar: contrato `core/application/contracts/repositories/shop_repository.gd` (`fetch_offers() → Dictionary`); `features/shop/infrastructure/repositories/remote_shop_repository.gd` (`http_get("/shop/offers")`, erro `{"error": _message_or_default(response)}` como `remote_friend_repository.gd:89-92`); `features/shop/infrastructure/mappers/shop_mapper.gd` (`offers_from_body(body) → Array[ShopOffer]`, lê `body.data.offers[]`); `features/shop/domain/models/shop_offer.gd` (`offerId,title,coinType,price,rewards,repeatable,active,expiresAt` cf. schema `Offer`); `features/shop/application/usecases/shop_usecase.gd` (`fetch_offers()` passthrough).
- Armazenamento: `InitialDataStore.offers: Array[ShopOffer]`.
- Notificação/conclusão: `await` no usecase do Loading + callback de progresso; erro = `{"error": ...}`.

### 5.3 Inventário — CRIAR stack (espelho de `social/`)

- Endpoint: `GET /user/inventory` (`docs/api.json:1599`, `GetMyInventoryResponse{inventory: InventoryItemResponse[]}`). **Não** usar `GET /user/{userId}/inventory` (paginado, outro propósito).
- A criar: contrato `.../inventory_repository.gd` (`fetch_my_inventory() → Dictionary`); `features/inventory/infrastructure/repositories/remote_inventory_repository.gd` (`http_get("/user/inventory")`); `features/inventory/infrastructure/mappers/inventory_mapper.gd` (`items_from_body(body) → Array[InventoryItem]`, lê `body.data.inventory[]`); `features/inventory/domain/models/inventory_item.gd` (`cosmeticId,name,type,equipped,assetPath` cf. `InventoryItemResponse`); `features/inventory/application/usecases/inventory_usecase.gd`.
- Armazenamento: `InitialDataStore.inventory: Array[InventoryItem]`.
- Erros: mesmo padrão `{"error": ...}`.

### 5.4 Amigos — REUTILIZAR (decisão de escopo necessária)

- Métodos existentes: `RemoteFriendRepository.fetch_friends(page,size)` (`GET /friend?...`), `fetch_pending()` (`GET /friend/pending`), `fetch_sent()` (`GET /friend/pending/sent`) + `FriendsUseCase` passthrough.
- Proposta: o Loading executa o equivalente a `SocialViewModel.load_all()` — `fetch_friends(0, 20)` + `fetch_pending()` + `fetch_sent()` — e grava os três resultados em `InitialDataStore.friends/pending/sent`. Tamanho da página: `20` (maior que o `DISCOVER_PAGE_SIZE=6` da aba, para que a Social abra já populada; paginação posterior continua via usecase existente). **Decisão a confirmar na implementação**: se o backend tiver milhares de amigos, trazer só a 1ª página no Loading é suficiente (o restante pagina sob demanda) — documentar como premissa.
- Modelos: `Friendship` + `FriendMapper.page_from_body/pending_from_body` (inalterados).
- Erros: `{"error": ...}` por chamada; qualquer uma das três falhando = grupo "amigos" falhou (ver §8).

### 5.5 Resumo

| Recurso | Endpoint | Repository (método) | Mapper | Modelo | Store |
|---|---|---|---|---|---|
| Perfil | `GET /user/me` | `RemoteUserRepository.fetch_current_user` (existente) | `UserMapper` (existente) | `User` (existente) | `InitialDataStore.user` + `SessionStore` |
| Loja | `GET /shop/offers` | `RemoteShopRepository.fetch_offers` (criar) | `ShopMapper` (criar) | `ShopOffer` (criar) | `InitialDataStore.offers` |
| Inventário | `GET /user/inventory` | `RemoteInventoryRepository.fetch_my_inventory` (criar) | `InventoryMapper` (criar) | `InventoryItem` (criar) | `InitialDataStore.inventory` |
| Amigos | `GET /friend` + `/pending` + `/pending/sent` | `RemoteFriendRepository` (existente) | `FriendMapper` (existente) | `Friendship` (existente) | `InitialDataStore.friends/pending/sent` |

---

## 6. Concorrência/assincronismo

### 6.1 Modelo atual

GDScript/Godot 4 com `await` em cadeia (`view await viewmodel await usecase await repository await HttpClient await request_completed`). Cada `HttpClient._request()` (`http_client.gd:81-101`) cria seu próprio nó `HTTPRequest`, de modo que **várias requisições coexistem** — não há fila global nem mutex. `BaseViewModel` não impõe serialização. Precedente de coordenação múltipla: `SocialViewModel.load_all()` dispara `load_friends_page + refresh_pending + refresh_sent` (sequencial por `await`, mas cada um é um `await` independente — nada impede o paralelo).

### 6.2 Proposta: paralelo com contador (sem biblioteca nova)

No `LoadInitialDataUseCase.execute(on_step: Callable)`:

```gdscript
# Dispara as 4 cargas SEM await — cada uma avança até seu primeiro await
# interno (o HTTPRequest) e rende; as 4 requisições viajam juntas.
var f_profile := _load_profile()    # coroutine 1
var f_shop := _load_shop()          # coroutine 2
var f_inventory := _load_inventory()# coroutine 3
var f_friends := _load_friends()    # coroutine 4 (3 GETs internos sequenciais)
# Aguarda todas, sinalizando progresso a cada conclusão (ordem de chegada):
var r1: Dictionary = await f_profile
_on_step_done(on_step)              # completed=1 → 25%
var r2: Dictionary = await f_shop
_on_step_done(on_step)              # completed=2 → 50%
...
```

Notas de implementação (a validar com teste, ver §12):

- Em Godot 4, chamar uma função `async` (que contém `await`) **sem** `await` inicia sua execução até o primeiro `await` e retorna um valor aguardável; o `await` posterior recolhe o resultado. Como cada `_load_*` faz `await _http_client.*` sobre `HTTPRequest`s distintos, as 4 janelas de rede se sobrepõem — conceitualmente o diagrama pedido (`Login ─┬─ Loja ─┬→ Home` etc.).
- Cada `_load_*` retorna `Dictionary` padronizado (`{"ok": true, "value": ...}` ou `{"error": ...}`, mais `status_code` quando disponível) e **nunca** lança: todo `await` é seguido de checagem `response.success`. O `execute()` agrega: se todos `ok` → grava no store e retorna sucesso; senão retorna o primeiro erro (com flag `unauthorized` se algum `status_code == 401`).
- Amigos: os 3 GETs internos de `_load_friends()` ficam **sequenciais entre si** (mesmo grupo, mesma ordem de `load_all()`), mas **paralelos** aos outros 3 grupos — 4 "trilhos" no total, 6 requisições no ar no pior caso. Alternativa rejeitada: paralelizar também os 3 de amigos (6 trilhos) — ganho marginal, mais estados de progresso parcial e divergência de `load_all()`.
- Fallback de segurança: se o padrão "chamar sem await" se mostrar frágil na versão 4.7 para algum caso (ex. retorno fora de ordem), o fallback é `await` sequencial dos 4 grupos com o mesmo contador/callback — o restante do plano (progresso, erros, navegação) não muda. A diferença é só latência (soma em vez de máximo). Registrar a escolha final no commit.

Não introduzir `Thread`, `Semaphore`, `HTTPClient` persistente nem fila própria — complexidade desnecessária vedada pelos requisitos.

---

## 7. Progresso

- Unidade: **4 grupos** (perfil, loja, inventário, amigos) — cada grupo vale `1/4`, independentemente de conter 1 ou 3 requisições HTTP. Amigos só conta quando `friends + pending + sent` concluídos.
- Cálculo: `progress = float(completed) / float(total)` com `total = 4`; marcos `0.00 → 0.25 → 0.50 → 0.75 → 1.00`. A ordem de chegada varia (paralelo) — o rótulo de status (`"Perfil pronto…"`) deve refletir **qual** grupo concluiu (passar o nome no callback), não uma ordem fixa. O exemplo do pedido (`loja 25%…`) é só um caso particular.
- Transporte: `LoadInitialDataUseCase.execute(on_step: Callable)` invoca `on_step.call(completed, total, group_name)`; `LoadingViewModel` converte em `signal progress_changed(value: float)` (+ opcional `status_changed(text)`); a view faz `loading_bar.value = progress * 100` com `Tween` de `0.25s` para suavizar.
- Regra dura: `100%` **somente** quando os 4 grupos estão `ok` e gravados no `InitialDataStore` (`store.is_ready()`). Qualquer falha trava a barra no valor atual e exibe erro (ver §8) — nunca "completa" com dado ausente.
- `LoadingViewModel` expõe ainda `progress() -> float` para testes GUT (assert por faixa, não por ordem).

---

## 8. Tratamento de erros

Baseado nos padrões existentes (`BaseViewModel.error_changed` + `animated_error_label.show_error()`, `HttpResponse`, `_message_or_default()` = `error_message` ou `"Falha de conexão. Tente novamente."`). Nenhum comportamento inventado fora desses.

| Caso | Detecção | Comportamento da Loading |
|---|---|---|
| Erro HTTP genérico (4xx/5xx com `message`) | `!response.success`, `status != 401` | **Permanece aberta**, barra congelada, `ErrorLabel.show_error(mensagem do servidor ou fallback)` + `RetryBtn.visible=true`. Não navega. `Retry` reexecuta `start()` do zero (idempotente; store parcial é sobrescrito). |
| Falha de conexão (sem resposta, `status_code 0`, JSON inválido) | `HttpResponse(0,false,{},"Failed to execute request.")` / `body {}` | Idem acima, mensagem `"Falha de conexão. Tente novamente."` (mesmo texto de `remote_friend_repository.gd:92` e `remote_user_repository.gd:55`). |
| Token inválido/expirado (401) | `response.status_code == 401` em **qualquer** das requisições | **Volta ao Login**: `SessionStore.end_session()` (emite `session_ended/changed`), `InitialDataStore.clear()`, `go_to(AppRoutes.LOGIN)` + erro `"Sessão expirada. Entre novamente."`. Exceção: o `BackBtn` ("Voltar ao login") fica visível como alternativa manual. Justificativa: sem Bearer válido nenhuma das 4 cargas passará no retry; insistir seria loop. Pré-requisito: expor o `status_code` até o usecase do Loading (hoje `RemoteUserRepository` descarta — ver §10). |
| Falha em apenas 1 dos 4 grupos | Agregação no `execute()` | Trata como falha total: **não navega** para o Shell ("evitar Home com dados obrigatórios ausentes"). Mensagem indica o grupo (`"Não foi possível carregar a loja."` etc.) + Retry. Premissa: os 4 são obrigatórios (pedido). Se futuramente algum virar opcional, este ponto muda — hoje não. |
| Retry | `RetryBtn → _view_model.retry()` → `start()` | Reentra com guarda (`if _loading: return`), reseta `completed=0`, barra volta a `0%`, erro limpo. Sem limite de tentativas (cada tentativa são só leituras GET). |
| Erro durante `POST /user/auth` / `GET /user/me` do login | Anterior ao Loading | Inalterado: fica no Login com `show_error + shake` (`login_screen.gd:150-160`). O Loading nunca abre sem `start_session`. |

Casos sem ação especial: timeout segue o padrão de falha de conexão; cancelamento pelo usuário não existe (sem botão fechar na Loading — voltar só via 401/BackBtn, para não deixar sessão semi-carregada).

---

## 9. Navegação

### 9.1 Alterações necessárias (3 redirecionamentos)

| # | Arquivo | Linha hoje | Alteração |
|---|---|---|---|
| 1 | `game/core/presentation/navigation/app_routes.gd` | `:4-13` | Adicionar `const LOADING := "res://features/loading/presentation/views/loading_screen.tscn"` (ordem alfabética não exigida; inserir após `HOME` ou ao fim — manter um `const` por linha). |
| 2 | `game/features/login/presentation/viewmodels/login_viewmodel.gd` | `:37` `go_to(AppRoutes.SHELL)` | Trocar para `go_to(AppRoutes.LOADING)`. Nada mais muda (loading/error já tratados). |
| 3 | `game/features/register/presentation/viewmodels/register_viewmodel.gd` | `:36` `go_to(AppRoutes.SHELL)` | Idem: `go_to(AppRoutes.LOADING)`. Registro cria sessão válida igual ao login, logo também pré-carrega. |
| 4 | `game/features/loading/presentation/viewmodels/loading_viewmodel.gd` (novo) | — | Sucesso → `go_to(AppRoutes.SHELL)`; 401 → `go_to(AppRoutes.LOGIN)` (após `end_session + clear`). |
| 5 | `game/features/home/presentation/views/home_screen.gd` | `:63-69` | Primeiro acesso lê `InitialDataStore.user` (se `is_ready()`) em vez de `load_user()` imediato; mantém `load_user()` como refresh manual/fallback quando o store está vazio. Detalhe de implementação no §11. |
| 6 | (futuro, mesma MR ou seguinte) `shop/social/inventory` views | — | Mesmo padrão do item 5 para seus slices (ler store primeiro, fetch sob demanda). Não é pré-requisito do Loading funcionar, mas é o que "evita refazer imediatamente as mesmas requisições". |

Fluxo final: `Main → LoginPopup/Register → LOADING → SHELL(PAGE_PLAY=Home)`. Nenhuma outra tela chama `go_to(SHELL)` na ida (matchmaking/game só **voltam** ao Shell em cancelar/erro/sair — `matchmaking_viewmodel.gd:65,94`, `game_viewmodel.gd:275` — inalterados).

### 9.2 Outros fluxos avaliados (sem mudança automática)

- **Login automático / recuperação de sessão / reabertura**: **não existe** hoje — `SessionPersistence.restore()` nunca é chamado (ver §1.5). Se um dia for ativado, o ponto de entrada deverá ser `LOADING` (restaurar → pré-carregar → SHELL), mas isso é trabalho futuro, fora deste plano.
- **Logout / novo login**: `SessionStore.end_session()` + `InitialDataStore.clear()` devem andar juntos (logout limpa o preload; novo login repopula). Verificar onde o logout é disparado hoje (`grep end_session` — `exit_button.gd` emite `logout_requested`; confirmar o handler na implementação e adicionar o `clear()` ali).
- **Login Google / Convidado**: stubs (`main_viewmodel.gd`) — quando implementados, devem apontar para `LOADING` também.
- **Deep-link direto ao SHELL** (F5/debug): Home/Shop/etc. com store vazio fazem fallback a fetch próprio (item 6 acima) — nunca tela vazia silenciosa.

---

## 10. Arquivos a criar/modificar

### CRIAR

```text
- game/features/loading/presentation/views/loading_screen.tscn
  - Cópia de main_screen.tscn sem popups/botões; com StatusLabel + ProgressBar + ErrorLabel + RetryBtn + BackBtn no ButtonsBox
- game/features/loading/presentation/views/loading_screen.gd
  - _ready/factory/signals/barra/status/erro/retry + cópia fiel de _start_logo_animation/_start_top_animation
- game/features/loading/presentation/viewmodels/loading_viewmodel.gd
  - extends BaseViewModel; signals progress_changed/status_changed/loaded; start()/retry(); go_to SHELL/LOGIN
- game/features/loading/application/usecases/load_initial_data_usecase.gd
  - Coordena 4 cargas em paralelo, callback de progresso, agrega erros, grava InitialDataStore
- game/features/loading/main/factory/loading_factory.gd
  - static create() -> LoadingViewModel via ServiceRegistry + SessionStore (padrão LoginFactory/SocialFactory)
- game/features/loading/domain/loading_result.gd (opcional, se preferir objeto a Dictionary)
  - success/failed_group/message/unauthorized — espelho de LoginResult
- game/core/application/stores/initial_data_store.gd
  - class_name InitialDataStore extends RefCounted; user/offers/inventory/friends/pending/sent + is_ready()/clear()
- game/core/application/contracts/repositories/shop_repository.gd
  - class_name ShopRepository; fetch_offers() -> Dictionary
- game/core/application/contracts/repositories/inventory_repository.gd
  - class_name InventoryRepository; fetch_my_inventory() -> Dictionary
- game/features/shop/domain/models/shop_offer.gd
  - class_name ShopOffer; from_dictionary (Offer do api.json)
- game/features/shop/infrastructure/mappers/shop_mapper.gd
  - offers_from_body(body) lê body.data.offers[]
- game/features/shop/infrastructure/repositories/remote_shop_repository.gd
  - GET /shop/offers via HttpClient (padrão RemoteFriendRepository)
- game/features/shop/application/usecases/shop_usecase.gd
  - fetch_offers() passthrough (padrão FriendsUseCase)
- game/features/inventory/domain/models/inventory_item.gd
  - class_name InventoryItem; from_dictionary (InventoryItemResponse)
- game/features/inventory/infrastructure/mappers/inventory_mapper.gd
  - items_from_body(body) lê body.data.inventory[]
- game/features/inventory/infrastructure/repositories/remote_inventory_repository.gd
  - GET /user/inventory via HttpClient
- game/features/inventory/application/usecases/inventory_usecase.gd
  - fetch_my_inventory() passthrough
- game/features/loading/assets/styles/loading_bar_bg.tres + loading_bar_fill.tres
  - StyleBoxFlat do trilho e do preenchimento (únicos assets novos; ver §4.4)
- game/tests/unit/viewmodels/test_loading_viewmodel_progress.gd (e/ou test_load_initial_data_usecase.gd)
  - GUT: progresso 0→1, 100% só com 4 ok, erro trava, 401 → LOGIN (fakes existentes)
```

### MODIFICAR

```text
- game/core/presentation/navigation/app_routes.gd
  - Adicionar const LOADING
- game/autoload/service_registry.gd
  - Criar + expor InitialDataStore (e opcionalmente shop/inventory repositories se preferir singleton; mínimo: só o store)
- game/features/login/presentation/viewmodels/login_viewmodel.gd
  - :37 SHELL → LOADING
- game/features/register/presentation/viewmodels/register_viewmodel.gd
  - :36 SHELL → LOADING
- game/features/user/infrastructure/repositories/remote_user_repository.gd
  - Expor status do /user/me (ex. novo método fetch_current_user_result() -> {user, status_code} ou similar), pois hoje retorna null e descarta o 401
- game/features/home/presentation/views/home_screen.gd (+ home_viewmodel.gd se necessário)
  - Primeiro acesso: ler InitialDataStore em vez de GET imediato; fallback a load_user() se store vazio
- (na mesma linha, quando as telas deixarem de ser mock)
  game/features/shop/presentation/views/shop_screen.gd,
  game/features/inventory/presentation/views/inventory_screen.gd,
  game/features/social/presentation/views/social_screen.gd
  - Ler o slice do InitialDataStore no enter(); fetch sob demanda se vazio
- (logout) handler de logout_requested/end_session onde existir
  - Adicionar InitialDataStore.clear() junto ao end_session()
```

Não alterar: `HttpClient`, `SessionStore`, `GlobalEnvironment`, `NavigationService/Manager`, `Main` (exceto como modelo de cópia), `matchmaking/game/rooms`, backend/API, `.godot/`, `project.godot` (autoloads inalterados).

---

## 11. Ordem de implementação

Sequência segura (minimiza risco de quebrar o login; cada passo é testável isoladamente):

```text
1. Contratos + modelos + mappers + repositories + usecases de SHOP e INVENTORY
   (sem tocar em navegação; validar com GUT de mapper + chamada manual ao backend local)
2. InitialDataStore + exposição no ServiceRegistry
   (só adiciona; nada consome ainda; GUT de is_ready/clear)
3. LoadInitialDataUseCase (com callback de progresso + agregação de erros)
   (GUT com FakeAuthProvider/FakeUser-FriendRepository nos moldes de tests/helpers/fake_*.gd)
4. LoadingViewModel + LoadingFactory + AppRoutes.LOADING
   (sem redirecionar login ainda; abrir a cena manualmente pelo editor para validar visual)
5. loading_screen.tscn/gd derivada da Main + barra + estilos
   (validar animações, barra 0→100% com dados simulados)
6. Redirecionar LoginViewModel e RegisterViewModel: SHELL → LOADING
   (a partir daqui o fluxo novo está ativo; testar login real ponta a ponta)
7. Home lendo InitialDataStore no primeiro acesso (+ fallback)
   (eliminar o GET /user/me duplicado pós-login)
8. Tratamento de erros completo (mensagens por grupo, Retry, 401 → LOGIN + end_session + clear)
9. Logout limpando o store + fallback das abas Shop/Inventory/Social com store vazio
10. GUT novos + rodada completa (comando do AGENTS.md) + teste manual §12
```

Regra de cada passo: nada de `SH → LOADING` antes dos passos 1–5 estarem verdes; cada passo mantém `Login → SHELL` funcionando até o passo 6.

---

## 12. Validação

Comando base (cf. `AGENTS.md`): `godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gexit` (102 testes / 258 asserts <0.5s como referência; sem PATH, usar o caminho completo do Steam). Backend local em `http://127.0.0.1:8080` deve estar rodando para testes manuais.

| # | Cenário | Como validar | Esperado |
|---|---|---|---|
| 1 | Login bem-sucedido | Credenciais válidas no `LoginPopup` | `POST /user/auth` + `GET /user/me` OK, `start_session`, abre `LOADING` (não `SHELL`) |
| 2 | Loading antes da Home | Observar transição | Logo/células animam como a Main; barra parte de `0%`; `SHELL` só após `100%` |
| 3 | Quatro requisições | Log `[HTTP]` (`http_client.gd:87`) / proxy | `GET /user/me`, `GET /shop/offers`, `GET /user/inventory`, `GET /friend*` disparam sobrepostas (paralelo), não em cadeia longa |
| 4 | Barra | Marcar tempos | `0 → 25 → 50 → 75 → 100%` por grupo concluído (ordem pode variar); `100%` só com `is_ready()` |
| 5 | Home com dados prontos | Inspecionar rede após `SHELL` | Nenhum `GET /user/me` imediato duplicado; nickname/moedas/stats vindos do store |
| 6 | Falha em 1 requisição | Derrubar rota (ex. backend sem `/shop/offers`) ou mockar `{"error":...}` | Loading permanece, barra congela, erro PT-BR do grupo + Retry visível; sem navegação |
| 7 | Retry | Clicar Tentar novamente após corrigir backend | Barra volta a `0%`, recarrega os 4, navega em sucesso |
| 8 | Token expirado | Simular 401 (token inválido) | `end_session + clear`, volta ao `LOGIN` com `"Sessão expirada. Entre novamente."` |
| 9 | Falha de conexão | Backend desligado | `"Falha de conexão. Tente novamente."` (texto já padronizado), Retry |
| 10 | Logout e novo login | Logout → login com outra conta | Store limpo no logout; Loading repopula com dados da nova conta; sem vazamento da anterior |
| 11 | Registro | Nova conta via `RegisterPopup` | Mesmo fluxo `→ LOADING → SHELL` |
| 12 | GUT | Rodar comando base + testes novos | Tudo verde; contrato-por-texto (`FileAccess...contains("LOADING")`) nos moldes de `test_shell_navigation.gd` + instanciação com fakes sem rede |

Critério de aceite: itens 1–10 verdes manual + GUT verde, sem regressão no fluxo `Main → Login/Register` nem em `matchmaking/game` (que só voltam ao Shell).
