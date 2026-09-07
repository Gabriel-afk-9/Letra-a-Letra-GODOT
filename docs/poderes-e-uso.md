# Poderes Letra a Letra — Backend Completo + Plano Godot Funcional

> **Sem código** — só especificação funcional. Referências absolutas para rastreio em `AGENTS.md:41`.
> Backend: `Letra-a-Letra-API` Spring Boot `PowerType.java:3` `PlayerActionActorCommand.java:108` `PlayerActionRequest.java:6`
> Godot: `game/features/game/` `game_viewmodel.gd:126` `remote_game_repository.gd:143` `game_power_catalog.gd:125`

## 1. Catálogo de 10 Poderes

**Fonte backend** `src/main/java/com/letraaletra/api/features/game/domain/board/power/PowerType.java:3`

- **COMMON** `PowerRarity COMMON`: `BLOCK` — bloqueia célula com 3 tentativas, `UNBLOCK` — remove bloqueio instantâneo, `TRAP` — armadilha (dono revela e continua, oponente trava), `DETECT_TRAPS` — revela armadilhas oponentes por 10 turnos
- **RARE** `RARE`: `SPY` — espiona letra de célula por 6 turnos, `FREEZE` — congela oponente 6 turnos (ofensivo player), `UNFREEZE` — descongela a si mesmo (defesa, usável congelado)
- **EPIC** `EPIC`: `BLIND` — cega oponente 6 turnos (ofensivo player), `LANTERN` — cura cegueira (remove `BlindEffect`)
- **LEGENDARY** `LEGENDARY`: `IMMUNITY` — cura `Freeze+Blind` + concede imunidade 10 turnos, usável congelado

**Geração** `CellFactory.java:11 selectDrop` `GameMode.java:7` `CATACLYSM chance 1.0 COMMON 0.0375 RARE 0.5875 EPIC 0.375 LEGENDARY 0.0` default matchmaking. `Cell.java:19` cada célula pode ter `drop` sorteado ao revelar.

**Inventário** `Player.java:39 LinkedHashMap<String,PowerType>` `max 5` `Map.copyOf` exposto no WS `data.players[].inventory [{id,name}]` `GamePlayerState.from_dictionary`. Se cheio, novo drop é ignorado silenciosamente — é preciso descartar via `DISCARD_POWER` `DiscardPowerActorCommand.java:41`.

## 2. Efeitos e Duração

**Interface** `PlayerEffect.java:3 getDuration/onTurnPassed/canRemove` effetiva via `GameState.nextTurn:81 decrementEffectDuration`

- `FreezeEffect.java:3 duration 6` — bloqueia qualquer ação exceto `UNFREEZE`/`IMMUNITY` `Player.isFrozen:18` `canNotPlay:88 isFrozen && !hasFreezeDefense`
- `BlindEffect.java:3 duration 6` — debuff visual, curado por `LANTERN` ou `IMMUNITY`
- `ImmunityEffect.java:3 duration 10` — defensivo, faz `FREEZE`/`BLIND` atacantes retornarem `PLAYER_ARE_IMMUNE` sem efeito
- `DetectTrapsEffect.java:8 duration 10 + List<Position> traps` snapshot `Board.getOpponentTraps:37` no momento do cast
- `SpyEffect.java:5 duration 6 + Position position` — uma célula espiada
- `BlockEffect.java:14 remainingAttempts 3 ownerId` `onInteract` só aceita `RevealCellAction` senão `InvalidPlayerAction`, decrementa tentativas: `>0 → CELL_STILL_BLOCKED canContinue false`, `0 → clearEffect + CELL_UNBLOCKED canContinue true`
- `TrapEffect.java:13 ownerId` sempre `clearEffect` depois, `isOwner ? canContinue true : false` — dono ganha letra, oponente perde turno

**Turno** `GameState.java:73 nextTurn` rotaciona `turnOrder`, `GameTurn.java:15 DelayQueueTurnTimeoutManager.java:41` `turnEndsAt = now + 45 + qtyEvents*2 sec` `PlayerActionActorCommand:115`, se `canNotPlay` loop adiciona `TURN_PASSED` e avança até achar jogável, `3 passedTurn` → `REMOVED_BECAUSE_INACTIVITY`.

## 3. Matriz de Defesa — Como um Poder Defende do Outro

- **Ataque `FREEZE 6` → defesa `IMMUNITY 10` prévio** `FreezePlayerAction:44 isImmune check ImmunityEffect` → `PLAYER_ARE_IMMUNE` sucesso sem congelar, mas atacante perde a carta `removeFromInventory` antes do check `FreezePlayerAction:42`. `Blind` idem `BlindPlayerAction:44`.
- **Já congelado → só `UNFREEZE` ou `IMMUNITY`** `PlayerActionActorCommand:108 if isFrozen && !(Unfreeze||Immunity) throw FROZEN_CANNOT_ACT = "player is frozen and cannot perform this action"` `PlayerMessages:12`. Todas outras `REVEAL,BLOCK,TRAP,BLIND,FREEZE,SPY,LANTERN,DETECT,UNBLOCK` dão `FROZEN_CANNOT_ACT`.
- **Efeito `BLIND` em si → `LANTERN` remove `BlindEffect`** `LanternAction:37` `Immunity` também cura `ImmunityPlayerAction:39`.
- **Efeito `FREEZE` em si → `UNFREEZE` remove `FreezeEffect`** `UnfreezeAction:38` `Immunity` também `ImmunityPlayerAction:40`.
- **Ataque `BLOCK 3 attempts` → `UNBLOCK` clear instant `UnblockCellAction:42` ou 3 `REVEAL` na mesma célula bloqueada `BlockEffect:36` vira `CELL_UNBLOCKED` + `CELL_REVEALED` no 3º.
- **Ataque `TRAP` → `DETECT_TRAPS` revela posições 10 turnos `DetectTrapsAction:38 getOpponentTraps`** ou evitar clicar suspeito.
- **Defesa preventiva:** `IMMUNITY` antes de levar `FREEZE/BLIND` garante `PLAYER_ARE_IMMUNE`.

## 4. Como Usar Cada Poder Corretamente Sem Erro

**Pré-requisitos para QUALQUER `PLAYER_ACTION` `PlayerActionWsRequest.java:9` `WsRequest type PLAYER_ACTION` `PlayerActionRequest.java:6 sealed 11 subtypes`:**

1. `gameId` UUID de jogo `RUNNING` onde você é `PLAYER` não `SPECTATOR` senão `PLAYER_NOT_IN_GAME`/`GAME_NOT_RUNNING` `PlayerActionActorCommand:46/104`.
2. Ser **sua vez** `state.currentPlayerTurn == yourId` senão `NotYourTurnException` `*Action:60`. Conferir `PLAYER_ACTION_RESULT turnEndsAt + currentTurnPlayerId`.
3. Se `isFrozen` true, só `UNFREEZE` ou `IMMUNITY` `PlayerActionActorCommand:108`.
4. `actionId` deve ser chave exata do seu `inventory Map<String,PowerType>` e `PowerType` deve ser o esperado para aquele `type` senão `INVALID_PLAYER_ACTION = "the requested player action is invalid"` `PlayerMessages:10`.
5. `position {x:0-9,y:0-9}` `PositionRequest 7-17` existente e `!revealed` para `BLOCK,TRAP,SPY,UNBLOCK` senão `CELL_ALREADY_REVEALED` `Cell:52`/`BlockCellAction:86`.
6. `FREEZE`/`BLIND` `targetId` deve ser UUID oponente ainda no jogo `getPlayerOrThrow` senão `PLAYER_NOT_IN_GAME`, carta consumida mesmo se `PLAYER_ARE_IMMUNE` `FreezePlayerAction:79`.
7. `REVEAL` não tem `actionId`, só `position`.
8. Erro retorna `ERROR {"event":"ERROR","message":"...","data":{}}` `ErrorWsResponse:5` `MessageCode.getCode()` — cliente branch na string `AGENTS.md` `remote_game_repository:345`.

**Sequências corretas por poder (descrição do envelope, não código):**

- **REVEAL (não poder, jogada base)** — envelope `PLAYER_ACTION` com `action type REVEAL` + `position`. Em `BlockEffect` pode dar `CELL_STILL_BLOCKED` nas 2 primeiras tentativas sem revelar, 3ª libera. Em `TrapEffect` oponente `TRAP_TRIGGERED canContinue false`.
- **BLOCK (ofensivo célula)** — `type BLOCK` precisa `actionId` que no inventário é de tipo `BLOCK` + `position` não revelada vazia, sem efeito `BlockEffect` já, senão `InvalidPlayerAction`. Cria `BlockEffect 3` `CELL_BLOCKED`.
- **UNBLOCK (counter BLOCK)** — `type UNBLOCK` `actionId UNBLOCK` + `position` não revelada, faz `clearEffect` instant `CELL_UNBLOCKED` independente do efeito atual.
- **TRAP (ofensivo célula)** — `type TRAP` `actionId TRAP` + `position` não revelada, se alvo tem `TrapEffect` de oponente já, `activateEffect` trata, cria `TrapEffect` `CELL_TRAPPED`.
- **DETECT_TRAPS (utilitário próprio)** — `type DETECT_TRAPS` só `actionId DETECT_TRAPS`, snapshot `getOpponentTraps` 10 turnos `TRAPS_DETECTED`.
- **SPY (utilitário célula)** — `type SPY` `actionId SPY` + `position` não revelada, `apply SpyEffect 6` `PLAYER_SPIED`.
- **FREEZE (ofensivo player)** — `type FREEZE` `actionId FREEZE` + `targetId opponent UUID`, consome mesmo se `PLAYER_ARE_IMMUNE` imune 10, senão `PLAYER_FROZEN 6` `effects [{duration:5}]`.
- **UNFREEZE (defesa própria, usável congelado)** — `type UNFREEZE` só `actionId UNFREEZE`, sem `targetId` nem `position`, `removeEffect FreezeEffect` `PLAYER_UNFREEZE`. Só funciona se `isFrozen` true e você tem a carta.
- **BLIND (ofensivo player)** — `type BLIND` `actionId BLIND` + `targetId opponent`, idem `FREEZE` mas `PLAYER_BLINDED 6`.
- **LANTERN (counter BLIND)** — `type LANTERN` só `actionId LANTERN`, `remove BlindEffect` `PLAYER_USE_LANTERN`, não remove `Freeze`.
- **IMMUNITY (ultimate próprio, usável congelado)** — `type IMMUNITY` só `actionId IMMUNITY`, `remove Blind+Freeze` + `apply Immunity 10` `PLAYER_USE_IMMUNITY`.

**Tratamento de resposta sucesso** `PlayerActionResponse` `turnEndsAt Instant + events List<Event> + data GameState`: inspecionar `events[].event StateEvent.java:3` `CELL_REVEALED,WORD_FOUNDED,CELL_BLOCKED,CELL_STILL_BLOCKED,CELL_UNBLOCKED,CELL_TRAPPED,TRAP_TRIGGERED,TRAPS_DETECTED,PLAYER_SPIED,PLAYER_FROZEN,PLAYER_UNFREEZE,PLAYER_BLINDED,PLAYER_USE_LANTERN,PLAYER_USE_IMMUNITY,PLAYER_ARE_IMMUNE,TURN_PASSED` para saber defesa.

## 5. Plano Godot Correto e Funcional

**Escopos já no catálogo Godot** `game/domain/game_power_catalog.gd:92 get_scope` `SCOPE_CELL` `BLOCK,TRAP,SPY,UNBLOCK` aguardam clique célula com `board pulse` `game_screen.gd:500`, `SCOPE_GLOBAL` `FREEZE,UNFREEZE,BLIND,LANTERN,IMMUNITY,DETECT_TRAPS` aguardam gesto swipe 40px `GLOBAL_SWIPE_THRESHOLD_PX` `game_screen.gd:22` confirmação inventário.

**Fluxo Godot alinhado ao backend:**

- Armar: toque `on_power_clicked powerId` `game_viewmodel.gd:126` verifica `isFrozen && !can_use_while_frozen type → block` `catalog can_use_while_frozen true só UNFREEZE/IMMUNITY` `catalog:110`, e `is_action_locked && !can_use_while_frozen → block` `bypass catalog` `game_viewmodel.gd:127` permite `UNFREEZE` mesmo com `lock 3s`.
- Disparo `GLOBAL`: `confirm_armed_global_power game_viewmodel.gd:159` checa `isFrozen && !can_use_while_frozen → clear` só `UNFREEZE/IMMUNITY` passam congelado, então `usecase use_global_power` `game_usecase.gd:65` `is_offensive false UNFREEZE self targetId=currentUser` `remote_game_repository.gd:105` envelope `PLAYER_ACTION targetId` correto, `is_offensive true FREEZE opponent`.
- Disparo `CELL`: `on_cell_clicked game_viewmodel.gd:94` se `SCOPE_CELL armado → use_power_on_cell id type x y` `remote_game_repository.gd:83` `position`, senão `reveal_cell x y` `usecase reveal_cell` `REVEAL` sem `actionId`.
- Validações Godot espelham backend: `SCOPE_CELL só position não revelada` `get_cell_visual_state HIDDEN` `game_viewmodel.gd:231` `CELL_SIZE 30` `BOARD_SIZE 10`, `SCOPE_GLOBAL só GLOBAL armado` `game_screen.gd:542`, `fora da vez tremida scale 1.06 0.25s sem position` `game_screen.gd:249` evita `GridContainer` quebra.
- Inventário 5 `GamePlayerState.INVENTORY_SIZE 5` `Player.java:39`, cache `_cached_my_inventory` `game_screen.gd:68` `power_granted pulse` `game_screen.gd:420`, sincronizado via `remote_game_repository _pending_*` `GameBoardMapper`.

**Erros mapeados Godot já:** `action_rejected game_viewmodel.gd:474 stepped_on_trap → trap_animation_requested` `player_are_immune → notification bloqueado` `player_not_in_game → game_over` `already been revealed → pass silencioso` `frozen cannot perform → unknown code log` `websocket_client DEBUG_RAW_WS true` `WS IN texto` preservado.

**Defesa prática no jogo:** Levar `FREEZE` → usar `UNFREEZE` imediato no seu turno (swipe), prevenir com `IMMUNITY` 10 antes, `BLIND` cura `LANTERN`, `BLOCK` 3 reveals ou `UNBLOCK`, `TRAP` evitar via `DETECT_TRAPS` 10.

## 6. Próximos Passos Funcionais

- Validar `PowerType.name` backend exatamente `BLOCK,UNBLOCK,TRAP,DETECT_TRAPS,SPY,FREEZE,UNFREEZE,BLIND,LANTERN,IMMUNITY` vs Godot `game_power_catalog` já alinhado `UNFREEZE` 500 recente era `hasDrop` `CATACLYSM` não mapeamento, aguardar fix server `UnfreezeAction:38 removeEffect`.
- Manter `API_BASE_URL/WS_BASE_URL` env fallback `global_environment.gd:3` `DEFAULT_API` para APK hospedado `docs/plano-apk.md:3`.
