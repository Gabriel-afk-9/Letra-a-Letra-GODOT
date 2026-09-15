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

Não há linters, CI ou package manager. **102 testes 258 asserts GUT 9.7.1 `game/tests/unit`** — ver `docs/testing-plan.md:6`; validação também via `F5` no editor Godot.

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

## 5. Estado Detalhado da Fase 5C (pós-refatoração GameScreen → orquestrador)

> **Refatoração concluída (Etapas 1–9):** `game/features/game/presentation/views/game_screen.gd` 2176→381 linhas, orquestrador puro. Lógica visual migrada para `assets/components/game/` editável em `.tscn`. `GameViewModel` e `GameFactory.bind()` **permaneceram inalterados** — contratos preservados. Testes atuais: **GUT 197/198 `1568/1569` asserts**, falha única pré-existente `test_inventory_screen.gd:34 [6] vs [7]` (já existia em `develop` antes da refatoração).

| Item | Existe? | Onde | Conectado? | Notas |
|------|---------|------|------------|-------|
| **Inventário (modelo)** | ✅ | `GamePlayerState.inventory: Array[GamePower]` (size=5) | Sim | Array com `null` para slots vazios; ordenação estável por `_power_seen_seq` agora em `InventoryPanel` (apresentação, não ViewModel) |
| **5 slots (UI)** | ✅ | `assets/components/game/inventory/inventory_panel.tscn` → 5× `inventory_slot.tscn` (`PanelContainer 52` + `TextureButton Icon`) instanciado como `InventoryPanel` em `game_screen.tscn` (`id 10_inv`) | Sim | `InventoryPanel` detém `_power_seen_seq/_power_seq_counter`, `update_inventory(inventory,is_frozen)`, `set_armed()`, `set_defense_pulse()`, `flash_grant()`; `InventorySlot` detém `rounded_icon.gdshader`, `GlobalArrow ▲ top_level/global_position` bounce, drag `±40px` (`slot_drag_launch/discard`) |
| **Ícones de poder** | ✅ | `PlayerCard.POWER_ICON_PATHS` (10 paths) + `InventorySlot._power_icon()` com `_icon_cache` + `rounded_icon.gdshader` (desaturation quando `is_frozen && !can_use_while_frozen`) | Sim | `load()` sob demanda; shader `radius 8` co-localizado em `inventory/` |
| **Contagem de poderes** | ✅ | `PlayerInfoBar._count_occupied()` → `_update_power_dots()` | Sim | Power Dots agora em `PlayerInfoBar` (não mais em `GameScreen`) |
| **Power Dots** | ✅ | `assets/components/game/player/player_info_bar.tscn`: `MyPowerDots` / `OpponentPowerDots` (5 `Panel 16×16` cada, `sep 6`) | Sim | `DOT_FILLED 1,1,1,0.95` / `DOT_EMPTY 0.5,0.5,0.5,0.6`, `pulse 1.45 0.16/0.22` / `fade 0.18/0.12` dentro de `PlayerInfoBar` |
| **Seleção de poder (armar)** | ✅ | `GameViewModel.on_power_clicked()` / `select_power()` + `armed_power_changed` + `selected_power_changed` → `GameScreen._on_armed_power_changed/_on_selected_power_changed` → `InventoryPanel.set_armed(id,scope,is_frozen,is_blinded)` → `InventorySlot.set_armed()` + `GlobalArrow ▲` (`top_level`) se `SCOPE_GLOBAL` | Sim | Lift `scale ONE`, borda `WHITE 2px` ou `NEON_GREEN 3px` quando defesa (`UNFREEZE/IMMUNITY`/`LANTERN`), `shadow 4` |
| **clear_selected_power** | ✅ | `GameViewModel.clear_selected_power()` | Sim | Emite `selected_power_changed("")` + `armed_power_changed("", "", "")` → `InventoryPanel` limpa destaque |
| **Uso de poder CELL** | ✅ | `GameScreen._on_cell_pressed()` → `ViewModel.on_cell_clicked()` → `use_power_on_cell()` + desarma | Sim | `BoardView` emite `cell_pressed(Vector2i)`; `GameScreen` decide `shake` vs `on_cell_clicked`; `BoardView.set_board_pulse(true)` quando `SCOPE_CELL` armado |
| **Uso de poder GLOBAL** | ✅ | `InventorySlot` drag `delta < -40` → `slot_drag_launch` → `GameScreen` → `ViewModel.confirm_armed_global_power()` → `use_global_power()` + `_lock_action(0.7s)` | Sim | `target_id` resolvido no UseCase (oponente se ofensivo, self se defensivo); anim `scale 1.18→1.5 / -120px / 0.3s` em `InventorySlot._animate_launch_slot()` |
| **armed_power_id / armed_power_type** | ✅ | `GameViewModel` variáveis privadas | Sim | Expostos via `selected_power_id()`; `GameScreen` cache `_armed_scope/_my_inventory_cache` para `board_interactivity` sem consultar ViewModel desnecessariamente |
| **Payload PLAYER_ACTION p/ poderes** | ✅ | `RemoteGameRepository._send_action()` | Sim | Wrapper `{"type":"PLAYER_ACTION","gameId":...,"action":{...}}` |
| **DISCARD_POWER** | ✅ | `InventorySlot` drag `delta > +40` → `slot_drag_discard` → `GameScreen` → `ViewModel.discard_armed_power()` → UseCase → Repository | Sim | Bloqueado se `is_frozen && counters_for_debuff(PLAYER_FROZEN).has(type)`; anim `scale 0.3 / +80px / 0.3s` em `_animate_discard_slot()`; preview vermelho `#ff4757` vs verde `#2ecc71` |
| **Efeitos de poder** | ✅ | `GameViewModel._on_my_effect_event()` mapeia 12 eventos → `effect_state_changed` → `GameScreen._on_effect_state_changed` → orquestra `EffectOverlay`/`BlindVignette` + `InventoryPanel.refresh_for_effect()` + `_refresh_all_cell_styles()` + `_update_board_interactivity()` | Sim | **Agora conectado** (antes não). `FREEZE 0.2,0.5,1,0.25` / `IMMUNITY 1,0.55,0.1,0.35` / `BLIND` via `BlindVignette`, `LANTERN flash 1,1,1,0.6 hold0.5` / `UNFREEZE flash 1,0.45,0.15 hold2.0` |
| **Notificações** | 🟡 | `GameViewModel.notification_requested` signal | Signal existe | View **ainda não conecta** (fora do escopo da refatoração; toast/snackbar pendente) |
| **trap_animation_requested** | ✅ | `GameViewModel.trap_animation_requested(x,y)` → `GameScreen._on_trap_animation_requested` → `_shake_cell + _pop_trap_cell` → `CellView.shake()/pop_trap()` | Sim | **Agora conectado** |
| **game_ended** | ✅ | `GameViewModel.game_ended(is_winner, title, subtitle)` → `GameScreen._on_game_ended` → `GameOverOverlay.show_result()` | Sim | `GameOverOverlay` (`ColorRect 0.85 z100 + Panel 320 corner12 Margin20 VBox20 Title24 Subtitle16 Button200×50`) em `assets/components/game/overlays/game_over_overlay.tscn` |
| **Overlay fim de jogo** | ✅ | `assets/components/game/overlays/game_over_overlay.tscn` (`id 7_overlay`, `uid://2903eab57f86`) + `game_over_overlay.gd` (`signal home_requested`) | Sim | Instanciado em `game_screen.tscn`; `home_requested → _navigate_home()` |
| **Botão/fluxo sair fim de jogo** | ✅ | `TopBarLeaveButton` (`Button 20×16 max50`) + `GameOverOverlay` Button "Voltar ao Início" → `_navigate_home()` | Sim | Flag `_navigation_started` anti-duplo clique; `GameViewModel.go_to_home() → AppRoutes.SHELL` |

---

## 6. Game Screen / Layout Atual (game_screen.tscn) — pós-refatoração (Etapa 9 concluída)

> **GameScreen como orquestrador:** `game/features/game/presentation/views/game_screen.gd` 381 linhas (2176→381). Não contém `StyleBoxFlat.new()`/`Shader.new()` nem lógica visual de célula/slot/dot/pills. Responsabilidades: `setup()` + `GameFactory.bind()`, conexão de 15 sinais do ViewModel, `guard` em `_on_cell_pressed` (hidden/spy/blind/trap/block), `shake` vs `on_cell_clicked`, delegação para componentes, responsividade `board 90%` + `inventory 280-340`, ciclo `leave/navigate`. Contratos `GameViewModel` e `GameFactory.bind()` **inalterados** — ver §5C.

```
GameScreen (Control, full-screen, script=game_screen.gd 381 linhas)
├── BackgroundGame (TextureRect, full-screen, stretch_mode=6)
├── MarginContainer (margins 12px)
│   └── MainLayout (VBoxContainer, alignment=CENTER, sep 12)
│       ├── PlayerInfoBar (instance 11_player) — assets/components/game/player/player_info_bar.tscn
│       │   ├── CardsCenter (CenterContainer)
│       │   │   ├── MyCardWrapper (Control 220×70) → MyPlayerCard (PlayerCard) + MyPowerDots (5× Panel 16×16 sep6)
│       │   │   └── OpponentCardWrapper (Control 220×70) → OpponentPlayerCard + OpponentPowerDots
│       │   └── TurnLabel (Label, center) — "Sua vez — %ds" / "Vez do oponente — %ds"
│       ├── WordsContainerView (instance 8_words) — PanelContainer bg 0.1,0.1,0.1 corner8 border2 + HFlowContainer (WordPill)
│       ├── BoardView (instance 9_board) — PanelContainer WHITE border4 corner12 + BoardGrid (GridContainer 10 cols h/v 1) → 100× CellView
│       ├── BoardInventorySpacer (Control 0×24, SHRINK_CENTER, IGNORE) — estático no .tscn (antes criado em _ready)
│       ├── InventoryPanel (instance 10_inv) — PanelContainer bg 0.08,0.08,0.08 corner15 + HBox sep9 → 5× InventorySlot (Panel 52 + Icon + GlobalArrow ▲ top_level)
│       └── BottomBar (HBoxContainer, visible=false)
├── EffectOverlay (instance 5_overlay, z50) — ColorRect freeze/immunity/lantern/unfreeze flash
├── BlindVignette (instance 6_overlay, z51) — Control + TextureRect radial gradient
├── GameOverOverlay (instance 7_overlay, z100) — ColorRect 0.85 + Panel 320 corner12
└── TopBarLeaveButton (Button 20×16 max50, red_button_default.tres)
```

### Árvore de componentes (`assets/components/game/` — editáveis em .tscn)

```
assets/components/game/
├── board/
│   ├── board_view.tscn/.gd (BoardView) — Grid 10×10, 100 CellView, apply_responsive(90% chrome 16+8+9 clamp 30-96 font cell*0.42), set_board_pulse, set_interactivity, play_word_pulse_sequence
│   ├── cell_view.tscn/.gd (CellView extends Button 30×30) — apply_state 14 estados, inner_border/diagonal/trap/block_bar, shake/animate_reveal/pulse_word/pop_trap/break_block
│   └── cell_diagonal.gdshader — diagonal split rounded 5
├── inventory/
│   ├── inventory_panel.tscn/.gd (InventoryPanel) — 5 slots, _power_seen_seq, update_inventory/set_armed/set_defense_pulse/flash_grant/apply_responsive/refresh_for_effect/get_power_id_at
│   ├── inventory_slot.tscn/.gd (InventorySlot) — Icon, rounded_icon.gdshader desaturation, drag ±40px previews #2ecc71/#ff4757, launch/discard, GlobalArrow ▲ top_level bounce
│   └── rounded_icon.gdshader — corner 8 desaturation
├── words/
│   ├── words_container_view.tscn/.gd — Panel 72 clip SHRINK_CENTER, HFlow h12 v10, cache signature, update_words(Array{text,owner})
│   └── word_pill.tscn/.gd — Panel corner10 padding 8/2, BLUE/ORANGE/#333 Label14
├── player/
│   └── player_info_bar.tscn/.gd (PlayerInfoBar) — VBox, 2× PlayerCard 220×70 avatar60, dots 16×16 sep6 pulse 1.45/fade, TurnLabel, setup_players/set_turn/set_turn_seconds/set_my/opponent_inventory
└── overlays/
    ├── effect_overlay.tscn/.gd (z50) — show(color)/hide/flash(hold lantern 0.5 unfreeze 2.0) fade 0.3
    ├── blind_vignette.tscn/.gd (z51) — GradientTexture2D radial 0.12/0.32/0.62/0.9 show/hide fade 0.3
    └── game_over_overlay.tscn/.gd (z100) — show_result(is_winner,title,subtitle), signal home_requested
```

### Elementos fixos na cena (.tscn) — pós-refatoração
- `game_screen.tscn` 88 linhas: Background, MarginContainer, MainLayout, `PlayerInfoBar` instance, `WordsContainerView` instance, `BoardView` instance, `BoardInventorySpacer` Control estático 24px, `InventoryPanel` instance, `BottomBar` (hidden), `EffectOverlay`/`BlindVignette`/`GameOverOverlay` instances, `TopBarLeaveButton`. Sem `StyleBoxFlat_inv_panel` inline (movido para `inventory_panel.tscn`) nem `StyleBoxFlat_dot` inline (movido para `player_info_bar.tscn`).

### Criados em runtime — pós-refatoração
- **BoardView** cria 100 `CellView` em `_build_cells()` (não mais `GameScreen._build_board_buttons`).
- **WordsContainerView** cria `WordPill` em `update_words()` com cache `_last_signature` (antes `_rebuild_words` em GameScreen).
- **InventoryPanel** gerencia 5 `InventorySlot` + `_power_seen_seq` (antes em GameScreen).
- **PlayerInfoBar** gerencia `PlayerCard` sizing + dots pulse/fade (antes `GameScreen._shrink_game_cards/_update_power_dots`).
- Wrappers e shaders (`board_wrapper.tres`/`words_wrapper.tres` se existentes, `cell_diagonal.gdshader`/`rounded_icon.gdshader`) são estáticos nos `.tscn` dos componentes, não mais via `_wrap_*` reparenting em `_ready()`.

### Separação de responsabilidades (orquestrador vs componentes)
- **GameScreen (orquestrador):** `setup`/`bind`, conecta 15 sinais ViewModel (`board_changed/words_changed/my_inventory/opponent_inventory/power_granted/turn_state/turn_timer/action_lock/effect_state/game_ended/armed_power/defense_pulse/word_found/trap_event/trap_animation/selected_power`), decide `shake` vs `on_cell_clicked`, calcula `revealed_states` para `board_view.set_interactivity`, delega `apply_responsive` e `set_board_pulse`, orquestra `EffectOverlay`/`BlindVignette` por `is_frozen/is_immune/is_blinded`, mantém `BoardInventorySpacer` estático. **Não contém** `StyleBoxFlat.new`/`Shader.new` nem aparência de célula/slot/dot.

- **Componentes visuais:** não conhecem `GameViewModel`/`UseCase`/`Repository`; recebem dados prontos e emitem sinais UI (`BoardView.cell_pressed`, `InventoryPanel.slot_pressed/drag_launch/discard`, `GameOverOverlay.home_requested`).

### Mobile / Responsividade
- Viewport `480×854` `canvas_items/expand` portrait (`game/project.godot:32`), `game_screen.gd:73 _apply_board_90_percent` `avail=layout*0.90 chrome=33 cell=floor((avail-chrome)/10) clamp 30-96 font cell*0.42 wrapper_w=10*cell+chrome SHRINK_CENTER`; `InventoryPanel.apply_responsive` `panel_w=clamp(layout*0.68,280,340)`; spacer 24px. Timings preservados: `action_lock 0.7s`, `word pulse 0.18s`, `reveal 0.075s`, `lantern 0.5s`, `unfreeze 2.0s`.

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