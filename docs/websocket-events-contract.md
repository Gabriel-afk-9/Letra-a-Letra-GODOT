# Contrato dos eventos WebSocket — client ↔ backend

Referência gerada por leitura direta do código do backend
([Letra-a-Letra-API](https://github.com/Zidan-09/Letra-a-Letra-API)). Nomes de campo são literais.

## Envelope

Todo DTO que implementa `WsResponse` é anotado com:

```java
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "event")  // WsResponse.java
```

Ou seja: **o `@JsonTypeName` da classe vira o campo raiz `"event"`, e os componentes do record
são serializados NA RAIZ do JSON**. Não existe wrapper automático `"data"` — quando um campo se
chama `"data"`, é porque o record declara um componente com esse nome.

**Exceções:** `TURN_EXPIRED` e `REMOVED_BECAUSE_INACTIVITY` NÃO implementam `WsResponse` — são
records simples (`game/domain/turn/TurnExpired.java`, `game/domain/room/RemovedBecauseInactivity.java`)
que carregam o próprio campo `event: String` e chegam ao fio com a mesma forma de envelope.

Convenções de tipo no fio:

| Java | JSON |
|---|---|
| `Instant` | string ISO-8601 |
| `UUID` | string |
| enum | `name()` (ex.: `"FOUNDED"`, `"BLOCK"`) |
| campo `null` | serializado como `null` (não omitido) |

---

## Eventos

### 1. PLAYER_ACTION_RESULT

Fonte: `features/player/infrastructure/presentation/dto/response/PlayerActionResponse.java`.
Enviado como resposta a cada ação do jogador.

```json
{
  "event": "PLAYER_ACTION_RESULT",
  "turnEndsAt": "<ISO-8601 | null>",
  "events": [ { "event": "<StateEvent>", "data": { ...EventData } } ],
  "data": { GameStateResponse }
}
```

| Campo | Tipo | Onde | Observação |
|---|---|---|---|
| `turnEndsAt` | Instant \| null | raiz | pode ser `null` |
| `events` | lista | raiz | eventos internos derivados da ação |
| `data` | GameStateResponse | raiz (campo nomeado `data`) | estado completo do jogo |

`events[].event` — enum `StateEvent` (`game/domain/event/StateEvent.java`):
`CELL_REVEALED`, `WORD_FOUNDED`, `CELL_BLOCKED`, `CELL_STILL_BLOCKED`, `TURN_PASSED`,
`CELL_UNBLOCKED`, `CELL_TRAPPED`, `TRAP_TRIGGERED`, `TRAPS_DETECTED`, `PLAYER_SPIED`,
`PLAYER_FROZEN`, `PLAYER_UNFREEZE`, `PLAYER_BLINDED`, `PLAYER_USE_LANTERN`,
`PLAYER_USE_IMMUNITY`, `PLAYER_ARE_IMMUNE`.

`events[].data` — interface `EventData` (polimórfica, sem type info): conteúdo varia por evento interno; tratar como opaco no client.

### 2. TURN_EXPIRED

Fonte: `TurnExpired` (`game/domain/turn/TurnExpired.java`), enviado via
`gameNotifier.notifierAll(...)` em `DelayQueueTurnTimeoutManager.java:140-145`. Sem DTO dedicado.

```json
{
  "event": "TURN_EXPIRED",
  "data": {
    "user": "<UUID do jogador que deixou expirar>",
    "currentTurnPlayerId": "<UUID do novo jogador da vez>"
  }
}
```

**Atenção:** `currentTurnPlayerId` existe só dentro de `data` neste evento, mas na raiz em
outros contextos — o client resolve essa ambiguidade root-vs-data com `_first_string()`.

### 3. GAME_OVER

Fonte: `GameOverResultResponse.java`, montado por `assembleGameOver(...)`.

```json
{
  "event": "GAME_OVER",
  "data": {
    "winner": { PlayerResponse },
    "loser":  { PlayerResponse }
  }
}
```

### 4. MATCHMAKING_GAME

**Dois DTOs compartilham o mesmo `@JsonTypeName`:**

a) `JoinMatchmakingResponse.java` — resposta ao entrar na fila:

```json
{ "event": "MATCHMAKING_GAME", "status": "SEARCHING" }
```

b) `MatchSuccessResponse.java` — partida encontrada:

```json
{
  "event": "MATCHMAKING_GAME",
  "status": "FOUNDED",
  "turnEndsAt": "<ISO-8601 | null>",
  "gameId": "<UUID>",
  "data": { GameStateResponse }
}
```

`status` — enum `MatchmakingStatus` (`matchmaking/domain/MatchmakingStatus.java`):
`SEARCHING` ou `FOUNDED` (serializado pelo `name()`).

### 5. PARTICIPANT_LEAVE

Fonte: `LeftGameResponse.java`.

```json
{
  "event": "PARTICIPANT_LEAVE",
  "data": { GameResponse }
}
```

### 6. PARTICIPANT_DISCONNECTED

Fonte: `DisconnectParticipantResponse.java`. Campo único, na raiz:

```json
{ "event": "PARTICIPANT_DISCONNECTED", "user": "<UUID>" }
```

### 7. REMOVED_BECAUSE_INACTIVITY

Fonte: record `RemovedBecauseInactivity(String event)`, enviado **somente ao jogador removido**
via `notifierOne` (`DelayQueueTurnTimeoutManager.java:148-151`). Nenhum outro campo:

```json
{ "event": "REMOVED_BECAUSE_INACTIVITY" }
```

### 8. ERROR

Fonte: `ErrorWsResponse.java`, enviado por `MainWebSocketEndpoint.sendError()`
(`shared/infrastructure/websocket/MainWebSocketEndpoint.java:86-107`). Campo único, na raiz:

```json
{ "event": "ERROR", "message": "<código/texto do erro>" }
```

`message` = `DomainException.getMessage()` (string fixa do enum `GameMessages`, ex.:
`"the selected cell has already been revealed"`), ou
`"an unexpected internal server error occurred"` para exceções desconhecidas.
O client trata essa string como código de erro (branch em `GameViewModel._on_action_rejected`),
não apenas texto de exibição.

---

## DTOs compartilhados

### GameStateResponse (`.../dto/response/game/GameStateResponse.java`)

```json
{
  "players": [ { PlayerResponse } ],
  "board": [ [ { BoardResponse } ] ],
  "words": [ { WordResponse } ],
  "currentTurnPlayerId": "<UUID>"
}
```

### PlayerResponse

```json
{
  "id": "<UUID>",
  "nickname": "<string>",
  "cosmeticsEquipped": [ { InventoryItem } ],
  "score": <int>,
  "inventory": [ { "id": "<string>", "name": "<string>" } ],
  "effects": [ <PlayerEffect> ]
}
```

`inventory` — `InventoryResponse(id, name)`: **não inclui raridade nem type** hoje (a raridade
no client vem do catálogo local mapeado por id). `effects` — interface `PlayerEffect` sem type
info: forma no fio não garantida, tratar como opaco.

### BoardResponse (célula)

```json
{
  "revealed": <boolean>,
  "letter": "<1 char | null>",
  "revealedBy": "<UUID | null>",
  "effect": null | { "effect": "BLOCK" } | { "effect": "TRAP" }
}
```

`effect` — sealed interface `EffectView` com `@JsonTypeInfo(property = "effect")`
(`BlockView`, `TrapView`).

### WordResponse

```json
{ "word": "<string>", "found": <boolean>, "foundById": "<UUID | null>" }
```

### GameResponse (usado em PARTICIPANT_LEAVE)

```json
{
  "gameId": "<UUID>",
  "gameName": "<string>",
  "type": "<GameType>",
  "status": "<GameStatus>",
  "participants": [ { ParticipantResponse } ],
  "positions": { "<int>": "<UUID>" },
  "matches": [ { MatchHistoryResponse } ]
}
```

### ParticipantResponse

```json
{
  "id": "<UUID>",
  "nickname": "<string>",
  "cosmeticsEquipped": [ { InventoryItem } ],
  "role": "<ParticipantRole>",
  "isConnected": <boolean>
}
```

---

## Notas para o client Godot

- Ambiguidade root-vs-data (`currentTurnPlayerId`, `turnEndsAt`): usar `WebSocketMessage.raw`
  + `_first_string()` (`RemoteGameRepository`), nunca assumir um lado.
- Snapshot inicial do board pode chegar ANTES do `start()` (durante matchmaking) — o
  repositório bufferiza em `_pending_*` e libera no `start()`.
- Log bruto aditivo de toda mensagem recebida: `WebSocketClient.DEBUG_RAW_WS`
  (`core/infrastructure/network/websocket/websocket_client.gd`).
