# LEVANTAMENTO COMPLETO — FEATURE GAME (Letra a Letra)

> **Data:** 2026-08-23  
> **Projeto:** Letra a Letra — Godot 4.7 Client (GDScript)  
> **Backend:** Spring Boot API (`http://127.0.0.1:8080`) + WebSocket (`ws://127.0.0.1:8080/ws/game`)  
> **Arquitetura:** Clean Architecture + Feature-First  
> **Nenhum arquivo foi alterado durante este levantamento.**

---

## 1. Estado Geral

O projeto segue **Clean Architecture** com separação por features (`game/features/<name>/`). Cada feature contém:
- `domain/` — entidades, modelos, regras puras
- `application/usecases/` — orquestração, sinais de domínio
- `infrastructure/repositories/` — implementações concretas (HTTP/WS)
- `infrastructure/mappers/` — conversão API ↔ Domain
- `presentation/views/` — `.tscn` + `.gd` (UI passiva, reativa a sinais)
- `presentation/viewmodels/` — extende `BaseViewModel`, gerencia estado UI
- `main/factory/` — `static bind(view)` ou `create()` injeta dependências via `ServiceRegistry`

**Dependências (confirmadas no código):**
```
View → ViewModel → UseCase → Repository Contract → RemoteRepository → WebSocketClient (autoload)
```

Não há testes, linters, CI ou package manager. Validação apenas rodando o jogo (F5 no editor Godot).

---

## 2. Alterações Recentes (Git Status/Diff)

| Arquivo | Linhas +/- | Resumo |
|---------|------------|--------|
| `game/core/application/contracts/repositories/game_repository.gd` | +4 | Contrato: adicionado `use_power_on_cell()` |
| `game/features/game/application/usecases/game_usecase.gd` | +4 | Repasse `use_power_on_cell()` |
| `game/features/game/domain/models/game_internal_event.gd` | 0 | Apenas EOL |
| `game/features/game/infrastructure/repositories/remote_game_repository.gd` | +16 | `use_power_on_cell()` + log debug temporário |
| `game/features/game/presentation/viewmodels/game_viewmodel.gd` | +47 | `armed_power_changed` signal, `on_power_clicked()` com bloqueio congelado + split GLOBAL/CELL |
| `game/features/game/presentation/views/game_screen.gd` | +250 | Inventory slots → TextureButton, `_update_inventory_panel()` reescrito, highlight armado, Game Over overlay, **wrappers WordsContainer/BoardGrid, Game Over centralizado** |
| `game/features/game/presentation/views/game_screen.tscn` | +33/-2 | TextureRect → TextureButton (5 slots), novos StyleBoxFlat |
| `game/features/matchmaking/infrastructure/repositories/remote_matchmaking_repository.gd` | 0 | `DEFAULT_GAME_MODE := "CATACLYSM"` |
| `game/project.godot` | -1 | Removido `window/stretch/aspect="keep"` |

---

## 3. Arquitetura e Fluxo Atual

### Fluxo IDA (Matchmaking → Game)

1. `RemoteMatchmakingRepository` recebe `MATCHMAKING_GAME` / `FOUNDED` → emite `match_found(MatchmakingFoundEvent)`
2. `MatchmakingViewModel` → `PendingNavigationPayload.set_payload(event)` → `NavigationService.go_to(AppRoutes.GAME)`
3. `GameFactory.bind(view)` → `take_payload()` → cria `GameUseCase` + `GameViewModel` → `view.setup(vm, game_id, opponent_id, me_nickname, opponent_nickname)`
4. `GameScreen.setup()` → conecta sinais do ViewModel → `_view_model.start(game_id, opponent_id)`
5. `GameUseCase.start()` → `RemoteGameRepository.start(game_id)` → `_flush_pending_state()` reemite board/words/players/turn que chegaram durante matchmaking

### Fluxo VOLTA (Backend → View)

```
WS event → RemoteGameRepository._on_message_received()
  → _handle_turn_update / _handle_state_sync / _handle_internal_events
  → emite sinais do contrato (turn_updated, board_updated, words_updated, players_updated, internal_event_received, game_over, opponent_disconnected, removed_for_inactivity, connection_lost, error)
  → GameUseCase recebe e traduz para sinais de domínio (turn_changed, board_updated, words_updated, my_inventory_updated, opponent_inventory_updated, word_found, trap_event, my_effect_event, game_over, connection_lost, action_rejected)
  → GameViewModel recebe, atualiza estado interno, emite sinais de UI (board_changed, words_changed, my_inventory_changed, opponent_inventory_changed, turn_state_changed, turn_timer_updated, action_lock_changed, effect_state_changed, word_found_feedback, trap_event_feedback, trap_animation_requested, notification_requested, selected_power_changed, armed_power_changed, game_ended)
  → GameScreen conecta e reage (atualiza células, palavras, inventário, timer, PlayerCards, Power Dots, overlay Game Over)
```

**Nenhuma divergência da regra View → ViewModel → UseCase → Repository → WSClient.**

---

## 4. Estado por Fase

| Fase | Descrição | Status |
|------|-----------|--------|
| **Fases 1–3** | Login, Register, Home, Matchmaking (busca, found, navegação) | ✅ Implementado |
| **Fase 4** | Game screen básica: tabuleiro 10×10, revelar célula, turno, timer, WS sync | ✅ Implementado |
| **Fase 5A** | Domínio: `GameBoard`, `GameCell`, `GameWord`, `GamePower`, `GamePlayerState`, `GameInternalEvent`, `GamePowerCatalog` (10 poderes, scope, offensive, frozen) | ✅ Implementado |
| **Fase 5B** | Infra: `RemoteGameRepository` com buffering de estado inicial (`_pending_*`), `use_cell_power`, `use_global_power`, `discard_power`, `leave_game`, `_clear_game_state`, `_leave_started` | ✅ Implementado |
| **Fase 5C** | Ver seção 6 detalhada | 🟡 Parcial |

---

## 5. Estado Detalhado da Fase 5C

| Item | Existe? | Onde | Conectado? | Notas |
|------|---------|------|------------|-------|
| **Inventário (modelo)** | ✅ | `GamePlayerState.inventory: Array[GamePower]` (size=5) | Sim | Array com `null` para slots vazios |
| **5 slots (UI)** | ✅ | `game_screen.tscn`: `InventorySlot1..5` → `Icon` (TextureButton) | Sim | `ignore_texture_size=true`, `STRETCH_KEEP_ASPECT_CENTERED` |
| **Ícones de poder** | ✅ | `PlayerCard.POWER_ICON_PATHS` (10 paths) + `_power_icon()` com cache | Sim | Carregamento `load()` sob demanda |
| **Contagem de poderes** | ✅ | `_count_occupied()` usado em `_update_power_dots()` | Sim | Power Dots (TopBar) mostram quantidade |
| **Power Dots** | ✅ | `MyPowerDots` / `OpponentPowerDots` (5 Panels cada) | Sim | Verde/branco = ocupado, cinza = vazio |
| **Seleção de poder (armar)** | ✅ | `GameViewModel.on_power_clicked()` + `armed_power_changed` | Sim | Amarelo (`modulate = Color(1,1,0.2,1)`) = armado |
| **clear_selected_power** | ✅ | `GameViewModel.clear_selected_power()` | Sim | Emite `selected_power_changed("")` + `armed_power_changed("")` |
| **Uso de poder CELL** | ✅ | `on_cell_clicked()` → `use_power_on_cell()` + desarma | Sim | Payload WS: `{"type": power_type, "actionId": power_id, "position": {"x":x,"y":y}}` |
| **Uso de poder GLOBAL** | ✅ | `on_power_clicked()` → `use_global_power()` + `_lock_action()` | Sim | `target_id` resolvido no UseCase (oponente se ofensivo, self se defensivo) |
| **armed_power_id / armed_power_type** | ✅ | `GameViewModel` variáveis privadas | Sim | Expostos via `selected_power_id()` getter |
| **Payload PLAYER_ACTION p/ poderes** | ✅ | `RemoteGameRepository._send_action()` | Sim | Wrapper `{"type":"PLAYER_ACTION","gameId":...,"action":{...}}` |
| **DISCARD_POWER** | ✅ | `GameViewModel.discard_power()` → UseCase → Repository | Sim | WS message type `DISCARD_POWER` com `gameId` + `powerId` |
| **Efeitos de poder** | 🟡 | `GameViewModel._on_my_effect_event()` mapeia 12 eventos | Parcial | `effect_state_changed` emitido, View **não conecta** |
| **Notificações** | 🟡 | `GameViewModel.notification_requested` signal | Signal existe | View **não conecta** |
| **trap_animation_requested** | ✅ | `GameViewModel.trap_animation_requested(x,y)` | Signal existe | View **não conecta** |
| **game_ended** | ✅ | `GameViewModel.game_ended(is_winner, title, subtitle)` | Sim | View `_on_game_ended` → `_show_game_over_overlay()` |
| **Overlay fim de jogo** | ✅ | `GameScreen._show_game_over_overlay()` | Sim | ColorRect(0.85) → PanelContainer(320×0, rounded 12, border) → MarginContainer(20) → VBox(sep=20) → Labels(autowrap WORD_SMART) + Button(SHRINK_CENTER) |
| **Botão/fluxo sair fim de jogo** | ✅ | Button "Voltar ao Início" → `_navigate_home()` | Sim | Flag `_navigation_started` anti-duplo clique |

---

## 6. Game Screen / Layout Atual (game_screen.tscn)

```
GameScreen (Control, full-screen, script=game_screen.gd)
├── BackgroundGame (TextureRect, full-screen, stretch_mode=6)
├── MarginContainer (margins 12px)
│   └── MainLayout (VBoxContainer, alignment=CENTER)
│       ├── TopBar (VBoxContainer)
│       │   └── CardsCenter (CenterContainer)
│       │       ├── MyCardWrapper (Control, 250×80)
│       │       │   ├── MyPlayerCard (PlayerCard instance)
│       │       │   └── MyPowerDots (HBoxContainer, 5 Panels 10×10, sep=4, align=CENTER)
│       │       └── OpponentCardWrapper (Control, 250×80)
│       │           ├── OpponentPlayerCard (PlayerCard instance)
│       │           └── OpponentPowerDots (HBoxContainer, 5 Panels 10×10, sep=4, align=CENTER)
│       ├── TurnLabel (Label, h_align=CENTER)
│       ├── WordsWrapper (PanelContainer, criado em runtime) — bg Color(0.1,0.1,0.1), rounded 8, margins 12, SIZE_SHRINK_CENTER
│       │   └── WordsContainer (HFlowContainer) — alignment=CENTER setado em _ready()
│       ├── BoardWrapper (PanelContainer, criado em runtime) — bg COLOR_WHITE, borda preta 4px, rounded 12, margins 8, SIZE_SHRINK_CENTER
│       │   └── BoardGrid (GridContainer, 10 cols, h/v_sep=1)
│       │       └── 100 Buttons criados em runtime (_build_board_buttons)
│       ├── InventoryPanel (PanelContainer, StyleBoxFlat_inv_panel: bg #0000004D, rounded 12, margins 8)
│       │   └── InventoryContainer (HBoxContainer, sep=6, align=CENTER)
│       │       ├── InventorySlot1 (PanelContainer, 24×24, StyleBoxFlat_slot)
│       │       │   └── Icon (TextureButton, stretch_mode=5)
│       │       ├── InventorySlot2..5 (estrutura idêntica)
│       └── BottomBar (HBoxContainer)
           ├── LeaveButton (Button)
           └── StatusLabel (Label)
```

### Elementos fixos na cena (.tscn):
- Background, MarginContainer, MainLayout, TopBar, CardsCenter, Wrappers, PlayerCards, Power Dots, TurnLabel, WordsContainer, BoardGrid (container vazio), InventoryPanel+Container+5 Slots+Icons, BottomBar, LeaveButton, StatusLabel

### Criados em runtime:
- 100 Botões do tabuleiro (`_build_board_buttons`)
- Pills das palavras (`_rebuild_words` → `PanelContainer` + `Label`)
- Wrapper preto do WordsContainer (`_wrap_words_container` → PanelContainer bg Color(0.1,0.1,0.1), rounded 8, margins 12)
- Wrapper branco do BoardGrid (`_wrap_board_grid` → PanelContainer bg COLOR_WHITE, borda preta 4px, rounded 12, margins 8)
- Game Over overlay (`_show_game_over_overlay` → ColorRect + PanelContainer + MarginContainer + VBoxContainer + Labels + Button)

### Wrappers visuais (reparenting em `_ready()`):
- `_wrap_words_container()` e `_wrap_board_grid()`: removem o nó original do pai, inserem o wrapper na **posição original** e recolocam o nó dentro do wrapper
- Posição original obtida com `var idx: int = parent.get_children().find(node)` — API real do Godot 4; **`get_child_index` não existe** em `Node`/`Container` (causava runtime error `Nonexistent function 'get_child_index' in base 'VBoxContainer'`)
- Sequência: `remove_child(no)` → `add_child(wrapper)` → `move_child(wrapper, idx)` → `wrapper.add_child(no)`
- Wrappers com `set_anchors_preset(PRESET_FULL_RECT)` + `SIZE_SHRINK_CENTER`; StyleBox via `add_theme_stylebox_override("panel", style)`

### Alternância de PlayerCards:
- `_on_turn_state_changed()` → `_update_player_cards()`:
  - Minha vez: `MyPlayerCard.show_local(nickname)`, `MyPowerDots.show()`, `OpponentPlayerCard.clear()`, `OpponentPowerDots.hide()`
  - Vez do oponente: inverso

### Atualização de inventário:
- `_on_my_inventory_changed()` → `_update_inventory_panel()`:
  - Para cada slot (0..4): `TextureButton.texture_normal = _power_icon(type)` se `GamePower`, senão `null`
  - StyleBoxes normal/hover/pressed via `_make_slot_stylebox(border_color)`
  - Frame (PanelContainer pai) recebe StyleBoxFlat bg #00000033 rounded 6
  - `_update_armed_power_highlight()` → `modulate` amarelo se armado
  - `_update_power_dots(_my_dots, _cached_my_inventory)`

### Power Dots:
- 5 Panels fixos no .tscn (Dot1..Dot5) com StyleBoxFlat_dot (cinza 0.6)
- `_update_power_dots()` conta ocupados → primeiros N ficam brancos (0.95), resto cinza (0.6)

### Mobile:
- Viewport 360×640, `stretch_mode="canvas_items"`, `orientation=portrait`
- Board 10×10 com `CELL_SIZE=30` → 300px + gaps ≈ 310px; wrapper branco adiciona borda+margens (~24px) → ~334px (cabe em 360)
- WordsWrapper adiciona margens 12px de cada lado ao WordsContainer
- Inventory slots 24×24 + gaps ≈ 150px

---

## 7. Player Card (Componente Compartilhado)

### `player_card.gd` — Responsabilidades:
- **Estados**: `CLEAR` (escondido), `SEARCHING` (spinner), `LOCAL` (azul), `OPPONENT` (laranja)
- **Métodos públicos**:
  - `clear()` → `CLEAR`
  - `show_searching()` → `SEARCHING`
  - `show_local(name, avatar?)` → `LOCAL`
  - `show_opponent(name, avatar?)` → `OPPONENT`
  - `set_inventory(Array)` → monta `_inventory_row` (HBoxContainer) em runtime, cria 5 `TextureRect` slots, mostra ícone + tooltip se `GamePower`, esconde se null
- **Interno**: `_ensure_inventory_row()` injeta `VBoxContainer` + `HBoxContainer` no `MarginContainer` da cena (preserva Home/Matchmaking que usam a mesma cena)
- **POWER_ICON_PATHS**: 10 paths confirmados (ver seção 9)

### `PlayerCard.tscn`:
- PanelContainer raiz (250×80 min)
- MarginContainer(5) → HBoxContainer(sep=15)
  - AvatarFrame (PanelContainer) → AvatarTexture (TextureRect 70×70) + Spinner (Range custom, 70×70, z_index=0)
  - NameBackground (PanelContainer) → NicknameLabel (Label, outline 3, font 15, center)

### Uso:
- **Home**: usa `PlayerCard` para mostrar usuário logado
- **Matchmaking**: usa 2 instâncias — `MyPlayerCard` (local) + `OpponentPlayerCard` (oponente), alterna via `show_local`/`show_opponent`/`show_searching`/`clear`
- **Game**: usa as mesmas 2 instâncias, alterna a cada turno (`_update_player_cards`)

### **Mantido FORA do PlayerCard compartilhado (deliberado):**
- A **barra inferior de 5 slots grandes** (`InventoryPanel` em `GameScreen`) — exclusiva da Game
- Lógica de **armar/desarmar poder** (`armed_power_id`, `on_power_clicked`, highlight amarelo)
- **Game Over overlay** (programático)
- **Tabuleiro** e **WordsContainer**

---

## 8. Poderes

### `game_power.gd`:
- `id: String`, `type: String` (ex: "FREEZE", "UNBLOCK")
- `from_dictionary()` lê `id` e `name` do JSON

### `game_power_catalog.gd` — **10 poderes conhecidos (CONFIRMADOS no código):**

| Poder | Scope | is_offensive | can_use_while_frozen | CONFIRMADO |
|-------|-------|--------------|----------------------|------------|
| FREEZE | GLOBAL | true | false | ✅ |
| UNFREEZE | GLOBAL | false | **true** | ✅ |
| BLIND | GLOBAL | true | false | ✅ |
| LANTERN | GLOBAL | false | false | ✅ |
| IMMUNITY | GLOBAL | false | **true** | ✅ |
| DETECT_TRAPS | GLOBAL | false | false | ✅ |
| BLOCK | CELL | true | false | ✅ |
| UNBLOCK | CELL | false | false | ✅ |
| SPY | CELL | false | false | ✅ |
| TRAP | CELL | true | false | ✅ |

### Métodos do catálogo:
- `get_scope(type) → "GLOBAL" | "CELL"`
- `is_offensive(type) → bool`
- `can_use_while_frozen(type) → bool` — **usado em `GameViewModel.on_power_clicked()` para bloquear congelados**

### **INFERIDO / NÃO CONFIRMADO pelo backend real:**
- Pareamento BLIND/LANTERN (comentário TODO: "confirmar pareamento BLIND/LANTERN contra backend real")
- Efeitos visuais/client-side de cada poder (não há código de animação)
- Duração exata de FREEZE/IMMUNITY em turnos (constantes `FREEZE_TURNS_DEFAULT=3`, `IMMUNITY_TURNS_DEFAULT=5` no ViewModel, mas backend pode divergir)
- Se TRAP é armado na célula ou revela efeito imediato

---

## 9. Contratos de Backend

### ✅ CONFIRMADOS (presentes no código atual — constants, logs, handlers):

| Evento / Ação | Direção | Detalhes no código |
|---------------|---------|-------------------|
| `MATCHMAKING_GAME` | Client → WS | `{"type":"MATCHMAKING_GAME","gameMode":"CATACLYSM"}` |
| `MATCHMAKING_GAME` (response) | WS → Client | `status="FOUNDED"`, `data.players[]`, `data.currentTurnPlayerId`, `data.gameId` |
| `PLAYER_ACTION` | Client → WS | Wrapper: `{"type":"PLAYER_ACTION","gameId":...,"action":{...}}` |
| `PLAYER_ACTION` action types: | | |
|  - `REVEAL` | Client → WS | `{"type":"REVEAL","position":{"x":int,"y":int}}` |
|  - Poder CELL (BLOCK,UNBLOCK,SPY,TRAP) | Client → WS | `{"type":power_type,"actionId":power_id,"position":{"x":int,"y":int}}` |
|  - Poder GLOBAL (FREEZE,IMMUNITY,etc) | Client → WS | `{"type":power_type,"actionId":power_id,"targetId":player_id}` |
| `LEFT_GAME` | Client → WS | `{"type":"LEFT_GAME","gameId":...}` |
| `DISCARD_POWER` | Client → WS | `{"type":"DISCARD_POWER","gameId":...,"powerId":...}` |
| `PLAYER_ACTION_RESULT` | WS → Client | Evento ignorado (`pass`) — **payload não parseado** |
| `TURN_EXPIRED` | WS → Client | Evento ignorado (`pass`) — **payload não parseado** |
| `GAME_OVER` | WS → Client | `data.winner.id` → `game_over(winner_id)` |
| `PARTICIPANT_LEAVE` / `PARTICIPANT_DISCONNECTED` | WS → Client | `opponent_disconnected.emit()` → `game_over(true, "OPPONENT_LEFT")` |
| `REMOVED_BECAUSE_INACTIVITY` | WS → Client | `removed_for_inactivity.emit()` → `game_over(false, "INACTIVITY")` |
| `ERROR` | WS → Client | `message` = código erro (ex: "stepped_on_trap", "player_are_immune", "player_not_in_game"), `data.x`, `data.y` opcionais → `error(error_code, cell_x, cell_y)` |

### 🟡 INFERIDOS / NÃO CONFIRMADOS (MVP legado, não no código atual):

| Evento | Status |
|--------|--------|
| `currentTurnPlayerId` / `turnEndsAt` no root **ou** em `data` | Código usa `WebSocketMessage.raw` + `_first_string()` — **não confirmado qual o backend envia** |
| `data.board` shape exato | `GameBoard.from_array()` espera `Array[Array[Dict]]` — **não validado** |
| `data.words` shape | `GameWord.from_dictionary()` espera `word, found, foundById` — **não validado** |
| `data.players` shape | `GamePlayerState.from_dictionary()` espera `id, inventory[Dict{id,name}]` — log debug temporário presente |
| Eventos internos em `message.events[]` | `GameInternalEvent.from_dictionary(event_name, data)` — campos `cell{x,y}`, `cells[{x,y}]`, `foundedBy`, `revealedBy` — **não confirmados** |
| Códigos de erro exaustivos | Só "stepped_on_trap", "player_are_immune"/"imune", "player_not_in_game" vistos — **lista incompleta** |

---

## 10. Bugs, Correções e Workarounds Já Aplicados

| Item | Local | Descrição |
|------|-------|-----------|
| **Buffering de estado inicial** | `RemoteGameRepository._pending_*` + `_flush_pending_state()` | Matchmaking envia snapshot antes de `start(game_id)`; repository guarda e reemite |
| **`_leave_started` trava** | `RemoteGameRepository.leave_game()` + `_clear_game_state()` | Impede `LEFT_GAME` duplicado; resetado apenas no próximo `start()` |
| **Limpeza de `_game_id`** | `_clear_game_state()` | Zera `_game_id` e desconecta WS ao fim da partida |
| **Prevenção navegação duplicada** | `GameScreen._navigate_home()` | Flag `_navigation_started` impede múltiplos `go_to_home()` |
| **Timer de turno com geração** | `GameViewModel._turn_timer_generation` | Aborta loop anterior quando novo `turn_changed` chega |
| **Parse de deadline UTC** | `GameViewModel._parse_turn_deadline()` | Remove sufixo "Z" manualmente, usa `Time.get_unix_time_from_datetime_string` |
| **Trava otimista de ação** | `GameViewModel._lock_action()` + `_schedule_action_unlock()` (3s) | Trava no clique, solta em turno trocado / erro / timeout |
| **Correção x/y tabuleiro** | `GameBoard.get_cell(x,y)` usa `rows[x][y]` | Consistente com `from_array(row_index, column_index)` |
| **Layout mobile** | `project.godot` + `game_screen.tscn` | Viewport 360×640, stretch canvas_items, orientação portrait |
| **Power Dots** | `PlayerCard.set_inventory()` + `GameScreen._update_power_dots()` | Compartilhados entre Matchmaking/Game; mostram contagem |
| **TextureButton no inventário** | `game_screen.tscn` + `_ready()` | `ignore_texture_size=true`, `STRETCH_KEEP_ASPECT_CENTERED` |
| **WordsContainer centralizado** | `GameScreen._ready()` | `words_container.alignment = FlowContainer.ALIGNMENT_CENTER` |
| **Wrapper preto no WordsContainer** | `GameScreen._wrap_words_container()` | PanelContainer (bg Color(0.1,0.1,0.1), rounded 8, margens 12) envolve o HFlowContainer, preservando posição no pai |
| **Wrapper branco no BoardGrid** | `GameScreen._wrap_board_grid()` | PanelContainer (bg COLOR_WHITE, borda preta 4px, rounded 12, margens 8) envolve o GridContainer, preservando posição no pai |
| **Correção `get_child_index`** | `_wrap_words_container()` / `_wrap_board_grid()` | `get_child_index()` não existe no Godot 4 → runtime error `Nonexistent function 'get_child_index' in base 'VBoxContainer'`; substituído por `parent.get_children().find(node)` + tipagem explícita `var idx: int` (parse error de inferência) |
| **DEFAULT_GAME_MODE = CATACLYSM** | `RemoteMatchmakingRepository` | Alterado de "INSANE" |
| **Log debug temporário** | `RemoteGameRepository._handle_state_sync()` | `AppLogger.debug("🕵️ RAW PLAYERS DO BACKEND: " + str(raw_players))` — **remover** |
| **Comentário `# <--- ADICIONE O EVENTO AQUI`** | `RemoteGameRepository._on_message_received()` | Comentário deixado no código — **limpar** |

---

## 11. Logs / Instrumentação

| Arquivo | Instrumentação |
|---------|----------------|
| `remote_game_repository.gd` | `[GAME][id] WS OUT PLAYER_ACTION type=... x= y=`, `[GAME][id] received event=...`, `🕵️ RAW PLAYERS DO BACKEND: ...` (**temporário**), `[GAME][id] WS OUT LEFT_GAME gameId=...` |
| `game_viewmodel.gd` | `AppLogger.debug("GameViewModel: efeito não mapeado: %s" % event_name)`, `AppLogger.debug("GameViewModel: código de erro desconhecido: %s" % error_code)` |
| `game_usecase.gd` | `AppLogger.debug("GameUseCase: unhandled internal event: %s" % event_name)` |
| `game_screen.gd` | Nenhum log direto |

**Logs temporários de diagnóstico:** `🕵️ RAW PLAYERS DO BACKEND` em `remote_game_repository.gd:280` — deve ser removido antes de produção.

---

## 12. Pendências Identificadas

| Item | Status | Detalhes |
|------|--------|----------|
| **Efeitos visuais de poderes** | ❌ | `effect_state_changed` emitido, mas `GameScreen` **não conecta** |
| **Notificações (toast/snackbar)** | ❌ | `notification_requested` signal existe, View **não conecta** |
| **Animação de trap** | ❌ | `trap_animation_requested(x,y)` signal existe, View **não conecta** |
| **Descarte de poder (UI)** | 🟡 | `discard_power()` existe no ViewModel/UseCase/Repository, mas **nenhum botão/gesto na UI** |
| **Validação backend real** | 🟡 | Pareamento BLIND/LANTERN, shape exato de `data.board/words/players`, códigos de erro, duração de efeitos — **não confirmados** |
| **Limpeza de logs/debug** | 🟡 | Remover `🕵️ RAW PLAYERS...` e comentário `# <--- ADICIONE O EVENTO AQUI` |
| **PLAYER_ACTION_RESULT / TURN_EXPIRED** | 🟡 | Eventos recebidos mas **ignorados** (`pass`) — podem conter dados úteis |
| **Reconexão WS** | ❌ | `WebSocketClient.reconnect()` existe mas **não integrado** no fluxo de Game |
| **Persistência de partida** | ❌ | Se app fechar mid-game, `_clear_game_state()` limpa tudo — sem restore |

---

## 13. Próximo Passo Único Recomendado

**Conectar os sinais de feedback visual já existentes no ViewModel à GameScreen:**

1. `GameViewModel.effect_state_changed` → `GameScreen` para atualizar UI de efeitos ativos (freeze, blind, immunity, spy, detect_traps)
2. `GameViewModel.notification_requested` → `GameScreen` para mostrar toast/snackbar temporário
3. `GameViewModel.trap_animation_requested(x,y)` → `GameScreen` para animar célula (shake, flash, partículas)

**Justificativa:**
- Toda a infraestrutura (signals, mapeamento de eventos WS → ViewModel) **já existe e está conectada**
- Falta apenas a **camada de apresentação** reagir a esses sinais
- Desbloqueia validação visual de poderes GLOBAL (FREEZE, IMMUNITY, BLIND, LANTERN, DETECT_TRAPS) e CELL (TRAP, SPY, BLOCK, UNBLOCK)
- Baixo risco, alta visibilidade, prepara para testes de integração com backend real

---

## 14. Conclusão

**LEVANTAMENTO CONCLUÍDO — nenhum arquivo foi alterado.**

A Feature Game está em estado **funcional para o loop básico** (matchmaking → tabuleiro → revelar células → turno → fim de jogo). A Fase 5C tem a **infraestrutura completa** para poderes CELL e GLOBAL, mas a **camada visual de feedback** (efeitos, notificações, animações de trap) ainda não está conectada. O próximo passo natural é conectar os 3 sinais listados na seção 13.