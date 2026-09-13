# Friends API — Amizades

Fontes primárias:

- `docs/api.json` (OpenAPI 3.1.0, `title: "Letra a Letra - API"`), tag **`Friend`** —
  *"Rotas relacionadas a funcionalidade de amizades"*.
- **Implementação do backend** (`../Letra-a-Letra-API`, pacote
  `com.letraaletra.api.features.friend` + compartilhados em `shared/`): todas as
  regras de negócio, erros, autenticação e eventos abaixo foram **confirmados no
  código**; referências indicam o arquivo exato. Onde documentação e código divergem,
  a divergência está registrada.

> Não há implementação de amizades no client Godot além da tela social
> (`game/features/social/`); este documento é o contrato para ela.

## Visão geral

O sistema de amizades é baseado em **solicitação com aceite explícito**:

1. Um usuário envia uma solicitação informando o `friendId` (UUID do outro usuário).
2. A solicitação nasce com status `PENDING`.
3. O destinatário **aceita** (`ACCEPT`) ou **recusa** (`DECLINED`); o remetente pode
   **cancelar** o envio enquanto pendente.
4. Qualquer participante pode **remover** a amizade depois.

São **8 operações** de amizade documentadas, todas sob paths `/friend*`, sem sobreposição com
outros domínios (usuários, jogos, loja, etc.), mais **2 endpoints auxiliares** da API de
usuários (`GET /user` para a lista inicial e `GET /user/username/{username}` para a
pesquisa por proximidade) usados para descobrir o `friendId` — total de
**10 operações** documentadas neste arquivo.

## Conceitos e estados

Enum de status — `FriendResponse.status` (`docs/api.json:4047-4054`):

| Valor    | Significado (confirmado em `Friend.java` + queries) |
|----------|-----------------------------------|
| `PENDING`  | Solicitação enviada, aguardando resposta |
| `ACCEPT`   | Amizade ativa (solicitação aceita) |
| `DECLINED` | Solicitação recusada               |

Transições confirmadas no código (`Friend.java`, `SendFriendRequestUseCase.java`):

```
(nenhuma relação) --POST /friend/request--> PENDING
PENDING           --PATCH /friend/accept---> ACCEPT   (só o destinatário)
PENDING           --PATCH /friend/reject---> DECLINED (só o destinatário)
PENDING           --PATCH /friend/cancel---> DECLINED (só o remetente)
ACCEPT            --PATCH /friend/remove---> DECLINED (qualquer participante; registro mantido)
DECLINED          --POST /friend/request--> PENDING   (reenvio permitido, atualiza requestDate)
```

`FriendResponse` traz ainda `friendId` (a **outra parte** da relação do ponto de vista de
quem chama — `FriendResponseMapper.toResponse(friend, viewerId)`) e `direction`
(`SENT` se o chamador é o remetente, `RECEIVED` se é o destinatário). Todos os
endpoints de leitura passam o `viewerId` do token, então os dois campos vêm sempre
preenchidos.

Semântica de `userId1`/`userId2` — **resolvido no código**: `SendFriendRequestUseCase`
cria `Friend.create(input.userId(), input.friendId())`, onde `input.userId()` é o
usuário autenticado (`principal.auth()`). Logo:

- **`userId1` = remetente** (quem enviou a solicitação);
- **`userId2` = destinatário** (quem recebe e pode aceitar/recusar).

Regras confirmadas:

- Só o **destinatário** (`userId2`) pode aceitar/recusar (`Friend.accept/decline`
  lançam `CanNotAcceptTheRequestException` / `CanNotDeclineTheRequestException` caso
  contrário).
- Aceitar/recusar exige status `PENDING` (chamadas repetidas no estado final são
  idempotentes: aceitar `ACCEPT` ou recusar `DECLINED` retorna sucesso sem alterar nada);
  remover exige participante e rejeita `PENDING` com `FRIEND_REQUEST_STILL_PENDING`;
  cancelar exige `PENDING` **e** que o chamador seja o remetente (`Friend.java`).
- **Cancelar solicitação enviada existe**: `PATCH /friend/cancel` (só o remetente;
  outro lado recebe `CAN_NOT_DECLINE_THE_REQUEST`). Para desfazer um envio, usar
  `cancel` — `remove` sobre `PENDING` falha com `FRIEND_REQUEST_STILL_PENDING`.
- **Envio valida o destinatário**: `friendId` de usuário inexistente →
  `FriendNotFoundException` (`SendFriendRequestUseCase.java:39-41`).
- **Auto-solicitação é rejeitada** (`userId == friendId` → `InvalidFriendRequestException`).
- **Duplicata é rejeitada**: se já existe relação com status diferente de `DECLINED`
  (ou seja, `PENDING` ou `ACCEPT`), novo envio → `InvalidFriendRequestException`.
  A busca é **bidirecional** (query `getFriend` testa os dois pares ordenados), então se B
  já enviou solicitação pendente para A, A não consegue enviar outra para B.
- **Reenvio após recusa/remoção é permitido**: relação `DECLINED` não bloqueia novo
  `POST /friend/request`, que reativa o registro para `PENDING` com nova `requestDate`
  (`reopen()`).
- `FRIEND_REQUEST_STILL_PENDING` agora **é lançado** por `remove()` sobre relação `PENDING`
  (antes era código morto).

## Autenticação e autorização

Confirmado no código (`SecurityConfig.java`, `JwtAuthenticationFilter.java`,
`AuthenticatedUser.java` no pacote `shared/` do backend):

- Autenticação via **JWT Bearer**: header `Authorization: Bearer <token>` (token obtido
  em `/user/auth`); sessão stateless (`SessionCreationPolicy.STATELESS`).
- **Todos os endpoints `/friend*` exigem autenticação** (`anyRequest().authenticated()`).
- O `userId` do solicitante **nunca vem do body**: todo controller recebe
  `@AuthenticationPrincipal AuthenticatedUser principal` e usa `principal.auth()` (UUID
  extraído do token) como `userId` do input. Não há distinção admin/usuário nos
  endpoints de amizade.
- Sem token ou token inválido → **401 Unauthorized**; acesso negado → **403 Forbidden**
  (fora do envelope padrão).
- Erros de domínio retornam sempre **400 Bad Request** com envelope de erro
  (`GlobalExceptionHandler.java`):

```json
{
  "success": false,
  "code": "INVALID_FRIEND_REQUEST",
  "message": "the friend request is invalid"
}
```

Códigos de erro de amizade (`FriendMessages`, `friend/domain/FriendMessages.java`):

| `code` | `message` | Quando |
|--------|-----------|--------|
| `INVALID_FRIEND_REQUEST` | `the friend request is invalid` | Auto-solicitação; duplicata/`ACCEPT` existente; aceitar/recusar/cancelar em estado errado; relação inexistente no accept/reject/cancel |
| `CAN_NOT_ACCEPT_THE_REQUEST` | `the friend request cannot be accepted` | Quem tenta aceitar não é o destinatário (`userId2`) |
| `CAN_NOT_DECLINE_THE_REQUEST` | `the friend request cannot be declined` | Quem tenta recusar/cancelar sem ser a parte autorizada |
| `FRIEND_NOT_FOUND` | `the friend was not found` | `PATCH /friend/remove` sem relação existente; envio com `friendId` de usuário inexistente |
| `FRIEND_REQUEST_STILL_PENDING` | `the friend request is still pending` | `PATCH /friend/remove` sobre relação `PENDING` (use `cancel` nesse caso) |
| `FRIENDS_FOUND` | `friends were found` | Sucesso informacional (não é erro) |
| `REQUEST_ACCEPTED` | `the friend request has been accepted` | Sucesso informacional (não é erro) |

Outros erros possíveis (genéricos, `GlobalExceptionHandler.java`): body ausente/malformado
→ `400 INVALID_INPUT`; `friendId` nulo ou inválido (Bean Validation `@NotNull` nos DTOs
de request) → `400 INVALID_REQUEST`; exceção inesperada → `500` com `code` de
`ServerMessages.INTERNAL_ERROR`.

## Endpoints

Envelope de resposta padrão: `{ "success": boolean, "data": { ... } }`.
`Content-Type` de request: `application/json`.

### 1. Enviar solicitação de amizade

`POST /friend/request` — `operationId: handle_18`.

Request — `SendFriendRequestRequest` (`docs/api.json:4013-4024`):

```json
{
  "friendId": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `friendId` | string UUID do destinatário | Sim |

Response `200 OK` — `SuccessResponseSendFriendRequestResponse` → `SendFriendRequestResponse`
(`docs/api.json:4061-4079`):

```json
{
  "success": true,
  "data": {
    "request": {
      "userId1": "<UUID remetente>",
      "userId2": "<UUID destinatário>",
      "friendId": "<UUID destinatário>",
      "direction": "SENT",
      "status": "PENDING",
      "requestDate": "2026-01-01T12:00:00Z",
      "profile": { "..." }
    }
  }
}
```

Efeito colateral: o backend envia imediatamente ao destinatário o evento WebSocket
`{"event":"RECEIVE_FRIEND_REQUEST"}` (ver "Notificações e eventos").

Erros (todos `400`, envelope `{success:false, code, message}`):

| Condição | `code` |
|----------|--------|
| `friendId` igual ao próprio `userId` (auto-solicitação) | `INVALID_FRIEND_REQUEST` |
| Já existe relação `PENDING` ou `ACCEPT` entre os dois (em qualquer direção) | `INVALID_FRIEND_REQUEST` |
| `friendId` de usuário inexistente | `FRIEND_NOT_FOUND` |
| `friendId` ausente/nulo | `INVALID_REQUEST` (validação) |

Reenvio após `DECLINED` (recusa, remoção ou cancelamento anterior) é **permitido**.

### 2. Aceitar solicitação de amizade

`PATCH /friend/accept` — `operationId: handle_37` (`docs/api.json:1299-1328`).

Request — `AcceptFriendRequestRequest` (`docs/api.json:4481-4492`):

```json
{
  "friendId": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `friendId` | string UUID (remetente do pedido) | Sim |

Response `200 OK` — `SuccessResponseVoid` (sem corpo útil; efeito: status → `ACCEPT`).

> Divergência antiga resolvida: o controller voltou a retornar `200`
> (`ApiResponseHandler.success(null)`), sem `204`. O client aceita qualquer 2xx.

Erros (todos `400`):

| Condição | `code` |
|----------|--------|
| Nenhuma relação entre os dois usuários | `INVALID_FRIEND_REQUEST` |
| Relação existe mas não está `PENDING` (aceitar `ACCEPT`/`DECLINED` é idempotente e retorna sucesso) | `INVALID_FRIEND_REQUEST` |
| Quem chama **não é o destinatário** (`userId2`) | `CAN_NOT_ACCEPT_THE_REQUEST` |

### 3. Recusar solicitação de amizade

`PATCH /friend/reject` — `operationId: handle_35`.

Request — `RejectFriendRequestRequest` (`docs/api.json:4457-4468`):

```json
{
  "friendId": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `friendId` | string UUID (remetente do pedido) | Sim |

Response `200 OK` — `SuccessResponseVoid` (sem corpo útil; efeito: status → `DECLINED`;
recusar `DECLINED` é idempotente).

Erros (todos `400`):

| Condição | `code` |
|----------|--------|
| Nenhuma relação entre os dois usuários | `INVALID_FRIEND_REQUEST` |
| Relação existe mas não está `PENDING` | `INVALID_FRIEND_REQUEST` |
| Quem chama **não é o destinatário** (`userId2`) | `CAN_NOT_DECLINE_THE_REQUEST` |

### 4. Cancelar solicitação enviada

`PATCH /friend/cancel` — `operationId: handle_36` (`docs/api.json:1269-1298`).

Request — `CancelFriendRequestRequest` (`docs/api.json:4469-4480`):

```json
{
  "friendId": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `friendId` | string UUID (destinatário do pedido) | Sim |

Response `200 OK` — `SuccessResponseVoid` (sem corpo útil; efeito: status `PENDING` →
`DECLINED`). O outro lado é notificado via WS (`notifyFriendshipCancelled`).

Erros (todos `400`):

| Condição | `code` |
|----------|--------|
| Nenhuma relação entre os dois usuários | `INVALID_FRIEND_REQUEST` |
| Relação existe mas não está `PENDING` | `INVALID_FRIEND_REQUEST` |
| Quem chama **não é o remetente** (`userId1`) | `CAN_NOT_DECLINE_THE_REQUEST` |

### 5. Remover amizade

`PATCH /friend/remove` — `operationId: handle_34`.

Request — `RemoveFriendRequest` (`docs/api.json:4445-4456`):

```json
{
  "friendId": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `friendId` | string UUID (ex-amigo) | Sim |

Response `200 OK` — `SuccessResponseVoid` (sem corpo útil; efeito: status `ACCEPT` → `DECLINED`;
o registro é mantido, permitindo reenvio futuro).

Observação: o método é `PATCH` com corpo JSON (não `DELETE`).

Erros:

| Condição | HTTP | `code` |
|----------|------|--------|
| Nenhuma relação entre os dois usuários | `400` | `FRIEND_NOT_FOUND` (também usado pelo envio quando o `friendId` não é um usuário existente) |
| Relação existe mas não está `ACCEPT`/`DECLINED` (ex. `PENDING` — para desfazer envio, usar `PATCH /friend/cancel`) | `400` | `FRIEND_REQUEST_STILL_PENDING` |

Qualquer participante pode remover (não há restrição de lado como no accept/reject);
remover `DECLINED` é idempotente.

### 6. Listar amigos

`GET /friend` — `operationId: handle_59`.

Query parameters — `pageable` (obrigatório, `Pageable`):

| Campo | Tipo | Obrigatório | Restrição |
|-------|------|-------------|-----------|
| `page` | integer int32 | Sim* | `minimum: 0` |
| `size` | integer int32 | Sim* | `minimum: 1` |
| `sort` | array de string | Não | Só `requestDate` e `status` são aceitos (outros descartados); padrão `requestDate,desc`. Ex.: `?sort=requestDate,desc` |

\* `pageable` é `required: true` no contrato; o controller recebe um `Pageable` Spring
direto, logo na prática trafega como `?page=0&size=20&sort=requestDate,desc`.

Response `200 OK` — `SuccessResponsePageResponseFriendResponse` →
`PageResponseFriendResponse`:

```json
{
  "success": true,
  "data": {
    "content": [
      {
        "userId1": "<UUID>",
        "userId2": "<UUID>",
        "friendId": "<UUID outra parte>",
        "direction": "SENT|RECEIVED",
        "status": "ACCEPT",
        "requestDate": "2026-01-01T12:00:00Z",
        "profile": { "..." }
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1,
    "first": true,
    "last": true
  }
}
```

Filtros/ordenação — confirmados em `GetFriendListMapper.java`:

- A listagem retorna **somente relações `ACCEPT`** em que o usuário é qualquer um dos
  lados (query `getFriendsList` filtra `(userId1 = :userId OR userId2 = :userId) AND
  status = ACCEPT`).
- Ordenação permitida: apenas `requestDate` e `status` (`ALLOWED_SORTS`); qualquer outro
  campo de `sort` é descartado pelo sanitizador (`Pageables.sanitize`). Padrão:
  `requestDate` descendente.

### 7. Listar solicitações pendentes recebidas

`GET /friend/pending` — `operationId: handle_60`.

- Sem parâmetros (sem `pageable` — **não paginado**, ao contrário de `GET /friend`).
- Escopo **resolvido no código**: retorna **somente solicitações recebidas** — a query
  `getReceivedPendingRequests` filtra `userId2 = :receiverId AND status = PENDING`.
  Nas entradas, `friendId` é o remetente e `direction` é `RECEIVED`.

Response `200 OK` — `SuccessResponseGetFriendPendingRequestsResponse` →
`GetFriendPendingRequestsResponse`:

```json
{
  "success": true,
  "data": {
    "requests": [
      {
        "userId1": "<UUID remetente>",
        "userId2": "<UUID você>",
        "friendId": "<UUID remetente>",
        "direction": "RECEIVED",
        "status": "PENDING",
        "requestDate": "2026-01-01T12:00:00Z",
        "profile": { "..." }
      }
    ]
  }
}
```

### 8. Listar solicitações pendentes enviadas

`GET /friend/pending/sent` — `operationId: handle_61` (`docs/api.json:2100-2119`).

- Sem parâmetros, **não paginado**. Query espelho da anterior (`userId1 = :senderId AND
  status = PENDING`).
- Nas entradas, `friendId` é o destinatário e `direction` é `SENT`. Cada item permite
  `PATCH /friend/cancel` com esse `friendId`.

Response `200 OK` — `SuccessResponseGetSentPendingRequestsResponse` →
`GetSentPendingRequestsResponse`: mesmo formato `{ "requests": FriendResponse[] }`.

## Listagem e paginação

- `GET /friend`: paginação obrigatória via `pageable` (`page ≥ 0`, `size ≥ 1`, `sort`
  opcional). Resposta no envelope `PageResponse*` padrão da API (`content`, `page`,
  `size`, `totalElements`, `totalPages`, `first`, `last`).
- `GET /friend/pending`: lista simples (`{ "requests": [...] }`), sem paginação,
  só solicitações **recebidas**.
- `GET /friend/pending/sent`: idem, só solicitações **enviadas**.
- Não há filtro por status (cada endpoint já tem status fixo: `ACCEPT` vs. `PENDING`),
  nem busca por nickname dentro de amizades — busca é via `GET /user/username/{username}`.

## Solicitações de amizade

Fluxo coberto pelos endpoints 1–4 e 7–8 acima (numeração das seções deste documento). Resumo:

| Papel | Ação | Endpoint |
|-------|------|----------|
| Remetente | Envia solicitação | `POST /friend/request` |
| Destinatário | Recebe evento WS `RECEIVE_FRIEND_REQUEST` em tempo real | WebSocket (ver abaixo) |
| Destinatário | Vê pendentes recebidas | `GET /friend/pending` |
| Destinatário | Aceita | `PATCH /friend/accept` |
| Destinatário | Recusa | `PATCH /friend/reject` |
| Remetente | Vê pendentes enviadas | `GET /friend/pending/sent` |
| Remetente | Cancela envio | `PATCH /friend/cancel` |

## Status do relacionamento

Não há endpoint do tipo `GET /friend/status/{userId}` nem campo de relacionamento
em perfis de usuário (`UserResponse`, `GetMyProfileResponse` não contêm campos de
amizade — verificados em `docs/api.json`). A busca bidirecional existe só na camada de
persistência (`getFriend` testa os dois pares ordenados) e é usada internamente pelos
usecases, sem exposição HTTP. A única forma via API de conhecer relações é listar
`GET /friend` / `GET /friend/pending` / `GET /friend/pending/sent` e cruzar
`friendId`/`direction`.

## Bloqueios

Nenhuma funcionalidade de bloquear/desbloquear usuários existe no `api.json`
(busca por `block`/`follow`/`social`/`connection`/`relationship`/`contact`/`invite`
retorna apenas `BLOCK` como efeito de poder do jogo, sem relação com amizades)
**nem no backend** (o pacote `features/friend` não contém nenhum conceito de bloqueio;
`FriendStatus` tem só `ACCEPT`/`DECLINED`/`PENDING`). Confirmado ausente.

## Notificações e eventos

- Ao enviar uma solicitação, o backend notifica o **destinatário** via WebSocket unicast
  (`FriendBroadcastService implements FriendNotifier`), usando a sessão registrada em
  `WsConnectionRegistry.findByUserId`.
- Payload (`FriendRequestEvent.java`) — **só o nome do evento, sem dados**:

```json
{ "event": "RECEIVE_FRIEND_REQUEST" }
```

- Se o destinatário estiver offline (sem sessão WS aberta), a notificação é silenciosamente
  descartada.
- O cancelamento também notifica a outra parte (`notifyFriendshipCancelled`), com o mesmo
  formato de evento. Para saber que uma solicitação enviada foi aceita, o remetente precisa
  consultar `GET /friend` (polling) — não há evento de "solicitação aceita".
- Este evento ainda **não consta** em `docs/websocket-events-contract.md` (que documenta
  só os eventos de jogo/matchmaking) — registrar lá ao implementar o client.
- Webhooks HTTP: não existem.

## Modelos e schemas

| Schema | Origem | Uso |
|--------|--------|-----|
| `FriendResponse` | `docs/api.json:4078-4116` | `{ userId1, userId2, friendId: UUID (outra parte p/ o chamador), direction: SENT\|RECEIVED, status, requestDate, profile: FriendProfileResponse }` — objeto central |
| `FriendProfileResponse` | `docs/api.json:4047-4077` | `{ userId, nickname, inGame: bool, currentGameId: UUID\|null, stats: UserStats, banInfo, equipped: InventoryItemResponse[] (só equipados) }` — perfil da outra parte |
| `InventoryItemResponse` | `docs/api.json:4117-4143` | `{ cosmeticId: UUID, name, type: AVATAR\|BANNER\|EMOTE\|FRAME, equipped: bool, assetPath: string }` |
| `FriendDirection` | enum | `SENT` \| `RECEIVED` |
| `SendFriendRequestRequest` | `docs/api.json:4013-4024` | `{ friendId: UUID! }` |
| `AcceptFriendRequestRequest` | `docs/api.json:4481-4492` | `{ friendId: UUID! }` |
| `RejectFriendRequestRequest` | `docs/api.json:4457-4468` | `{ friendId: UUID! }` |
| `CancelFriendRequestRequest` | `docs/api.json:4469-4480` | `{ friendId: UUID! }` (só o remetente) |
| `RemoveFriendRequest` | `docs/api.json:4445-4456` | `{ friendId: UUID! }` |
| `SendFriendRequestResponse` | `docs/api.json:4061-4068` | `{ request: FriendResponse }` |
| `GetFriendPendingRequestsResponse` | `docs/api.json:5424-5434` | `{ requests: FriendResponse[] }` (recebidas) |
| `GetSentPendingRequestsResponse` | `docs/api.json:5446-5456` | `{ requests: FriendResponse[] }` (enviadas) |
| `PageResponseFriendResponse` | — | Envelope paginado de `FriendResponse[]` |
| `SuccessResponse*` | — | Envelopes `{ success, data }`; `SuccessResponseVoid.data` é vazio/não tipado |
| `ErrorResponse` | Backend: `shared/.../dto/response/ErrorResponse.java`, `GlobalExceptionHandler.java` | `{ success: false, code: string, message: string }` — usado em todos os erros (fora do `api.json`) |
| `FriendRequestEvent` | Backend: `friend/.../dto/response/FriendRequestEvent.java` | `{"event":"RECEIVE_FRIEND_REQUEST"}` — evento WS unicast (fora do `api.json`) |
| `FriendMessages` | Backend: `friend/domain/FriendMessages.java` | Enum de códigos de erro/sucesso (ver tabela em "Autenticação e autorização") |

`userId1` = remetente, `userId2` = destinatário. `profile` é o perfil da outra parte
(`friendId`); pode vir `null` se o usuário não for localizado no mapeamento — o client
deve tratar `profile` ausente com fallback (exibir id curto).

### Perfil do amigo e cosméticos (`profile.equipped`)

Cada item de `profile.equipped` (só itens com `equipped: true`, cf.
`FriendProfileMapper.java:18-23`) tem:

| Campo | Tipo | Uso no client |
|-------|------|---------------|
| `name` | string | Nome de catálogo (ex. `"logo"`) |
| `type` | `AVATAR`\|`BANNER`\|`EMOTE`\|`FRAME` | Determina o slot do card |
| `assetPath` | string | Referência ao asset local no formato `TIPO/arquivo.ext` (ex. `AVATAR/teste.webp`) — **não é URL** |
| `equipped` | bool | Sempre `true` neste contexto |

Regras para o client Godot (contrato da tela de amizades):

- `nickname` (`profile.nickname`) é o nome de exibição em todas as listas.
- `assetPath` resolve para o asset local `res://assets/cosmetics/<tipo-minúsculo>/<arquivo>`,
  ex. `AVATAR/teste.webp` → `cosmetics/avatar/teste.webp`. A resolução deve ser genérica
  por tipo (`AVATAR/`→`avatar/`, `BANNER/`→`banner/`, `FRAME/`→`frame/`, ...).
- Verificar existência antes de carregar; se ausente, usar o cosmético padrão
  (avatar `logo.png`, sem banner/frame — mesmo comportamento da Home).
- Nunca baixar nada da API a partir do `assetPath`.
- Campos ausentes/`null` (sem `profile`, sem `equipped`, sem item de um tipo) não podem
  quebrar o card — usar fallbacks.

## Recurso auxiliar: buscar usuários (para adicionar como amigos)

### 9. Buscar usuários por nickname (proximidade, paginado)

`GET /user/username/{username}` — tag `User`.

Parâmetros de path:

| Campo | Tipo | Obrigatório | Restrição |
|-------|------|-------------|-----------|
| `username` | string (termo) | Sim | `minLength: 1`, `@NotBlank` |

Query parameters — `pageable` (obrigatório, `Pageable`): `page ≥ 0`, `size ≥ 1`, `sort`
opcional restrito a `username|email|createdAt` (outros descartados).

Comportamento confirmado no código:

- Retorna usuários cujo nickname **contém** o termo (case-insensitive:
  `WHERE LOWER(username) LIKE LOWER('%term%')`) — **sem fuzzy matching além disso**;
  a "proximidade" é: nomes que **começam** com o termo primeiro, depois ordem alfabética.
- Ordenação do backend deve ser **preservada** (não reordenar no client). Para isso,
  **não enviar `sort`** na pesquisa — qualquer `sort` permitido substituiria a
  ordenação de proximidade. Na listagem inicial (`GET /user`), usar
  `sort=username,asc` para ordem determinística.
- Termo sem correspondência retorna **página vazia (`content: []`) — não `404`**.

Response `200 OK` — `SuccessResponsePageResponseUserResponse`, `content: UserResponse[]`.

Exemplo para `GET /user/username/samuel?page=0&size=6` (ordem do backend preservada):

```json
{
  "success": true,
  "data": {
    "content": [
      { "userId": "<UUID>", "nickname": "Samuel", "...": "..." },
      { "userId": "<UUID>", "nickname": "Samuel Silva", "...": "..." },
      { "userId": "<UUID>", "nickname": "Samuel Santos", "...": "..." },
      { "userId": "<UUID>", "nickname": "Samuele", "...": "..." },
      { "userId": "<UUID>", "nickname": "Samu", "...": "..." }
    ],
    "page": 0,
    "size": 6,
    "totalElements": 5,
    "totalPages": 1,
    "first": true,
    "last": true
  }
}
```

Estrutura do `UserResponse`:

| Campo | Tipo | Observação |
|-------|------|------------|
| `userId` | string UUID | ← usar como `friendId` no `POST /friend/request` |
| `nickname` | string | |
| `email` | string | Exposto na resposta — evitar exibir no client |
| `banInfo` | `BanInfoResponse` | `{ banned, type: PERMANENT\|TEMPORARY, reason, expiresAt }` |
| `stats` | `UserStats` | `{ totalMatches, totalWins, winStreak, level, experience, rankingPoints }` |
| `equipped` | `InventoryItemResponse[]` | Cosméticos equipados |
| `wallet` | `WalletResponse` | |

Erros: termo sem correspondência retorna página vazia (`content: []`), **não erro**.
Falhas de rede/validação seguem o padrão (`400 INVALID_REQUEST` para termo em branco, etc.).

Exemplo de fluxo de integração: `GET /user/username/jogador?page=0&size=6` → extrair
`data.content[0].userId` → `POST /friend/request` com `{ "friendId": "<userId>" }`.

### 10. Lista inicial de usuários

`GET /user` — tag `User`, `operationId: handle_6`.

Retorna usuários de maneira paginada — ideal para preencher a tela de "Adicionar amigo"
quando o usuário ainda não realizou uma busca. Quando houver busca por nickname, a grade
passa a exibir o resultado da pesquisa (`GET /user/username/{username}`) em vez da lista.

Query parameters — `pageable` (obrigatório): `page ≥ 0`, `size ≥ 1`, `sort` opcional
restrito a `username|email|createdAt`.

Response `200 OK` — mesmo envelope `SuccessResponsePageResponseUserResponse`
(`content: UserResponse[]`, paginação padrão).

## Fluxos comuns

### Enviar → aceitar

1. A descobre o UUID de B via `GET /user/username/{username}?page=0&size=6`
   (ou navegando pela lista inicial `GET /user`).
2. A chama `POST /friend/request` com `{ "friendId": "<UUID de B>" }` → recebe a
   relação com `status: PENDING` (`userId1` = A, `userId2` = B, `direction: SENT`). B recebe
   o evento WS `RECEIVE_FRIEND_REQUEST` se estiver conectado.
3. B chama `GET /friend/pending` e localiza a entrada enviada por A (`direction: RECEIVED`).
4. B chama `PATCH /friend/accept` com `{ "friendId": "<UUID de A>" }` → `200 OK`;
   relação passa a `ACCEPT`.
5. Ambos veem a relação em `GET /friend?page=0&size=20`.

### Enviar → recusar

Passos 1–3 iguais; B chama `PATCH /friend/reject` → status `DECLINED`. A pode reenviar
depois com novo `POST /friend/request`.

### Enviar → cancelar

1–2 iguais ao fluxo acima; A consulta `GET /friend/pending/sent`, localiza o pedido e
chama `PATCH /friend/cancel` com o `friendId` do destinatário → status `DECLINED`.

### Remover amizade

Qualquer parte chama `PATCH /friend/remove` com o UUID da outra parte (exige status
`ACCEPT`/`DECLINED`; `PENDING` retorna `FRIEND_REQUEST_STILL_PENDING` — nesse caso usar
`cancel`). O registro é mantido, então reenvio futuro continua possível.

## Observações e regras de negócio

1. **Métodos não convencionais**: aceitar/recusar/cancelar/remover usam `PATCH` com corpo
   JSON (não `PUT`/`DELETE`). Seguir o contrato literalmente na integração.
2. **Assimetria de listagem**: `GET /friend` (só `ACCEPT`, paginado, sort em
   `requestDate|status`) vs. `GET /friend/pending` e `/friend/pending/sent` (só `PENDING`
   recebidas/enviadas, sem paginação).
3. **`friendId`/`direction` facilitam o client**: em vez de cruzar `userId1`/`userId2` com
   o próprio id, usar `friendId` (outra parte) e `direction` (`SENT`/`RECEIVED`) da resposta.
4. **Erros de domínio são sempre `400`** com `{success:false, code, message}` (códigos em
   `FriendMessages`); `401`/`403` vêm do filtro de segurança fora do envelope; o `api.json`
   omite tudo isso (declara só `200` e nenhum `securityScheme`).
5. **`profile` enriquece as listas**: nickname e cosméticos vêm embutidos em cada
   `FriendResponse` — ver "Perfil do amigo e cosméticos" para resolução de `assetPath`.
6. **Tempo real parcial**: o envio (e o cancelamento) gera push WS (`RECEIVE_FRIEND_REQUEST`,
   sem payload) e só se o destinatário estiver conectado; aceite/recusa/remoção exigem
   polling de `GET /friend` / `GET /friend/pending*`. Registrar o evento em
   `docs/websocket-events-contract.md` ao implementar.
