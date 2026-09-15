# Plano de Refatoração — GameScreen Orquestrador

> **Fonte:** plano final ajustado aprovado (correções 1-13). `game/features/game/presentation/views/game_screen.gd` ~2176 linhas → orquestrador. Preservar comportamento pixel/behavior identical, sem alterar `GameViewModel`/`GameUseCase`/repositories/API/WS/`GameFactory.bind()` salvo justificativa técnica.

## 0. Correções Normativas (1-13)

1. `_power_seen_seq` (e ordenação/cache visual) permanece em `InventoryPanel` (apresentação), não vai ao `GameViewModel`.
2. `WordsContainerView` não recebe `Callable`; `GameScreen` resolve `owner` via `vm.classify_word_owner()` e passa `Array[Dictionary{text,owner}]` pronto; componente desacoplado do VM.
3. Sem shadowing/feature-flag por padrão. Migração incremental: criar → integrar `.tscn` → conectar → validar → remover código antigo daquela responsabilidade → próximo. Coexistência só se necessidade técnica concreta.
4. `GlobalArrow` preservado idêntico (`top_level=true`, `global_position`, bounce) nesta refatoração; correção de posicionamento fica para depois.
5. Sem redesign/UX: mesmos tamanhos, cores, timings, tweens, thresholds, interações, estados, responsividade.
6. Não mover lógica para `GameViewModel` para facilitar extração; VM permanece como está, salvo alteração mínima justificada.
7. `game_screen.gd <= 320 linhas` não é requisito rígido; critério é responsabilidade clara e orquestração.
8. Componentes visuais NÃO conhecem `GameUseCase`/repositories/serviços; trabalham com dados recebidos e emitem eventos UI.
9. Board: `BoardView` = grid/coordenação/responsividade/pulse/interação; `CellView` = aparência/animação 1 célula; `CellView` não consulta VM.
10. Inventory: `InventoryPanel` = 5 slots + sync armed/defense; `InventorySlot` = aparência/drag-anims; `InventoryPanel` pode consultar `GamePowerCatalog` só se estritamente necessário para apresentação existente.
11. Não extrair só para reduzir linhas; toda cena/script precisa responsabilidade real reutilizável.
12. Manter contratos `GameViewModel` e `GameFactory.bind()` exatamente.
13. Ordem 1→9 abaixo é a ordem exata; ao final de cada etapa validar e parar aguardando autorização.

## 1. Árvore Final

```
assets/components/game/
├── board/
│   ├── board_view.tscn          # PanelContainer wrapper .tres + GridContainer 10 cols
│   ├── board_view.gd
│   ├── cell_view.tscn           # Button 30x30 + InnerBorder/DiagonalSplit/TrapIcon/BlockBar pré-criados
│   ├── cell_view.gd
│   └── cell_diagonal.gdshader   # extraído de _diagonal_split_material() (~l.1907)
├── inventory/
│   ├── inventory_panel.tscn     # PanelContainer + HBox 5x InventorySlot
│   ├── inventory_panel.gd       # detém _power_seen_seq/_power_seq_counter (regra 1)
│   ├── inventory_slot.tscn      # PanelContainer 52 + TextureButton + Label GlobalArrow ▲
│   ├── inventory_slot.gd
│   └── rounded_icon.gdshader    # extraído de _rounded_icon_material() (~l.1456)
├── words/
│   ├── words_container_view.tscn # PanelContainer wrapper .tres + HFlowContainer
│   ├── words_container_view.gd
│   ├── word_pill.tscn
│   └── word_pill.gd
├── player/
│   ├── player_info_bar.tscn     # VBox CardsCenter + TurnLabel + dots (reusa PlayerCard.tscn)
│   └── player_info_bar.gd
└── overlays/
    ├── effect_overlay.tscn      # ColorRect z50 FULL_RECT
    ├── effect_overlay.gd
    ├── blind_vignette.tscn      # Control z51 + TextureRect Gradient radial já no .tscn
    ├── blind_vignette.gd
    ├── game_over_overlay.tscn   # ColorRect 0.85 z100 + Panel 320
    └── game_over_overlay.gd
assets/styles/game/panels/
├── board_wrapper.tres
└── words_wrapper.tres
```

## 2. Responsabilidade de Cada Componente

| Componente | Responsabilidade |
|---|---|
| **BoardView** | Grid 10x10, 100 CellView, `_cell_buttons/_last_cell_state`, responsividade 90% (`chrome 16+8+9`, `clamp 30-96`, `font cell*0.42`), pulse wrapper neon, coordenação `mouse_filter`. |
| **CellView** | 1 célula: `apply_state(state,letter)` 14 estados, inner_border/diagonal/trap/block_bar, tweens `reveal 0.075s/shake/pulse/pop/break`. Recebe dados prontos, não consulta VM. |
| **WordsContainerView** | Cache `_last_words_signature`, `update_words(viewData)` onde `viewData: Array[Dictionary{text,owner}]` já resolvido pelo GameScreen; cria `WordPill`. Sem Callable/VM. |
| **WordPill** | Pill `corner10` padding `8/2`, bg `COLOR_BLUE/COLOR_ORANGE/#333`. |
| **InventoryPanel** | 5 slots, `_power_seen_seq/_cached_my_inventory` (regra 1), `set_inventory/set_armed/set_defense_pulse/apply_responsive`, coordena slots. Consulta `GamePowerCatalog` só se necessário para disabled. |
| **InventorySlot** | 1 slot: ícone, `rounded_icon` desaturado, `DashedSlotFrame`, drag `gui_input` threshold 40px, previews verde `#2ecc71`/vermelho `#ff4757`, `snap_back/launch/discard`, `GlobalArrow` `top_level/global_position` preservado. |
| **PlayerInfoBar** | 2 `PlayerCard` + 2×5 dots `16x16 sep6` + `TurnLabel`, `set_turn` fade `0.2s`, `set_turn_label`, `set_dots` pulse/fade. |
| **EffectOverlay** | `show(color)/hide()/flash(color,hold)` fade `0.3s`, hold lantern `0.5s`/unfreeze `2.0s`. |
| **BlindVignette** | Gradiente radial `0.12/0.32/0.62/0.9`, `show()/hide()` fade `0.3s`. |
| **GameOverOverlay** | `show_result(is_winner,title,subtitle)`, `signal home_requested`. |

Cores/tamanhos/timings/thresholds/responsividade idênticos (regra 5). Componentes não conhecem UseCase/repo (regra 8).

## 3. Mapa Função Atual → Destino

```
_wrap_words_container()                → WordsContainerView wrapper .tres
_wrap_board_grid()                     → BoardView wrapper .tres
_ensure_board_inventory_spacer()       → game_screen.tscn Control 24px (remover func)
_shrink_game_cards()                   → PlayerInfoBar sizing no .tscn
_apply_board_90_percent()              → BoardView.apply_responsive()
_apply_inventory_responsive()          → InventoryPanel.apply_responsive()
_build_board_buttons() + _cell_buttons → BoardView
_on_board_changed/_refresh_all         → BoardView.update_board()
_apply_cell_style/_style_cell/_update_cell_* → CellView
_diagonal_split_material Shader.new()  → cell_diagonal.gdshader → CellView
_trap_cell_texture/TRAP_ICON           → CellView preload
_update_cell_block_bar                 → CellView.update_block_bar(colors:Array)
_on_cell_pressed (is_hidden guard)    → GameScreen decide shake vs vm.on_cell_clicked(); BoardView só emite cell_pressed
_shake/_reveal/_pulse/_pop/_break     → CellView
_words_signature/_rebuild_words        → WordsContainerView (GameScreen resolve owner antes)
_on_my_inventory_changed + _power_seen_seq → InventoryPanel (apresentação)
_on_opponent_inventory_changed         → PlayerInfoBar
_update_inventory_panel/_animate_slot_lift/_ensure_global_arrow → InventorySlot/Panel
_on_defense_pulse_changed             → InventoryPanel → InventorySlot
_on_inventory_icon_gui_input + previews→ InventorySlot
_power_icon/_rounded_icon_material    → rounded_icon.gdshader → InventorySlot
_on_power_slot_pressed/_on_power_granted → InventoryPanel/Slot
_on_armed_power_changed/_start/_stop_board_pulse → BoardView.set_pulse() + Panel.set_armed()
_count_occupied/_update_power_dots    → PlayerInfoBar
_update_player_cards/_on_turn_*       → PlayerInfoBar
_on_effect_state_changed              → GameScreen orquestra → EffectOverlay/BlindVignette
_ensure/_show/_hide_effect/blind     → EffectOverlay/BlindVignette
_on_game_ended/_show_game_over_overlay→ GameOverOverlay
_icon_cache global                    → particionado CellView + Slot locais
```

GameScreen retém: `setup()`, `GameFactory.bind()`, `_connect_view_model()` 15 sinais, caches `_my/_opponent_nickname/_armed_scope/_action_locked/_was_*_navigation_started`, `_on_cell_pressed` guard, `_update_board_interactivity()` calcula `disabled` e repassa, `leave/navigate/_notification/_exit_tree`, `resized` repasse.

## 4. Sinais/Contratos GameScreen ↔ Componentes (push, sem VM nos componentes)

```
GameScreen → BoardView
  update_board(board:GameBoard, states:Dictionary<Vector2i,String>, letters:Dictionary)
  set_interactivity(disabled:bool), set_pulse(bool), pulse_cells(Array[Vector2i]), apply_responsive(layoutW:float)
BoardView → GameScreen
  cell_pressed(pos:Vector2i)

GameScreen → WordsContainerView
  update_words(items:Array[Dictionary{text:String, owner:String}])  # GameScreen: words.map(vm.classify_word_owner)
WordsContainerView → GameScreen : (nenhum)

GameScreen → InventoryPanel
  set_inventory(inventory:Array), set_armed(powerId:String, scope:String), set_defense_pulse(ids:Array), set_frozen_disabled(bool), apply_responsive(layoutW:float), flash_grant(powerId:String)
InventoryPanel → GameScreen
  slot_pressed(idx:int), global_use_confirmed, discard_confirmed  # GameScreen → vm.on_power_clicked/confirm/discard
InventorySlot → InventoryPanel (interno)
  pressed, drag_threshold_exceeded(dir:"up"/"down")

GameScreen → PlayerInfoBar
  set_players(myNick,oppNick), set_turn(isMyTurn:bool), set_turn_label(text:String), set_my_dots(Array), set_opponent_dots(Array)
GameScreen → EffectOverlay / BlindVignette
  show(color:Color)/hide()/flash(color,hold:float)
GameScreen → GameOverOverlay
  show_result(is_winner,title,subtitle)
GameOverOverlay → GameScreen
  home_requested → vm.go_to_home()
```

Contratos VM/Factory inalterados.

## 5. Ordem Exata de Migração (incremental, sem shadowing por padrão)

1. **EffectOverlay + BlindVignette** — `.tscn/.gd`, mover `ensure/show/hide/flash` + Gradient, instanciar em `game_screen.tscn`, GameScreen delega.
2. **GameOverOverlay** — extrair `_show_game_over_overlay` + preload styles → `.tscn`, `home_requested`.
3. **WordPill + WordsContainerView** — wrapper `.tres`, cache assinatura, GameScreen resolve owner.
4. **CellView + shaders** — 2 `Shader.new()` → `.gdshader`, `cell_view.tscn` layers pré-criados, migrar `_style_cell`.
5. **BoardView** — wrapper `.tres`, 100 CellView, `_last_cell_state`, responsividade, pulse, `pulse_cells`.
6. **InventorySlot** — `rounded_icon.gdshader` + `DashedSlotFrame`, drag 40px, previews, launch/discard, `GlobalArrow` idêntico.
7. **InventoryPanel** — 5 Slots, `_power_seen_seq`+ordenação, armed/defense, `power_granted`, responsivo 68%.
8. **PlayerInfoBar** — cards sizing, fade 0.2s, TurnLabel, dots pulse/fade.
9. **GameScreen limpeza + TSCN wiring final** — trocar `@onready` antigos por refs componentes, remover `_wrap_*`, mover `StyleBoxFlat_inv_panel` → `.tres`, `godot --import` limpo, atualizar `docs/game-feature-analysis.md §5C`.

Coexistência temporária só se validação exigir comparar pixel/tween específico.

## 6. Validação por Etapa (após cada 1-9)

**Automático:**
```bash
godot --headless --path game --import
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gexit
```
Manter 198/198; observar `test_power_drag_preview`, `test_game_viewmodel_visual_state`, `test_websocket_contract_fixtures`.

**Manual F5 (480x854 portrait, canvas_items/expand, touch+mouse):**
- Board: 14 estados, `CLAIMED_BOTH` diagonal, block 3 segmentos cor/jogador, trap, spy/blind.
- Reveal 0.075s, shake quando `!is_my_turn`/`is_frozen`/`!is_hidden`.
- Words: cores BLUE/ORANGE/cinza, rebuild só assinatura mudou, pulse 0.18s.
- Inventory: GLOBAL drag -40 launch/+40 discard, CELL pulse neon, freeze disable cinza, `UNFREEZE/IMMUNITY` liberados, defense pulse loop, grant 0.16/0.24.
- Turnos: `Sua vez — %ds` tick 0.5s, fade cartas, `action_lock 0.7s` dim sem bloquear defesa.
- Effects: freeze `0.2,0.5,1,0.25`/immunity `1,0.55,0.1,0.35`/blind `0.5`/lantern `0.6 0.5s`/unfreeze `2s`.
- GameOver: win verde/loss vermelho, `Voltar ao Início` → `SHELL`.
- Responsivo: Board 90% `clamp 30-96`, Inventory 280-340, spacer 24.

## 7. Critério de Conclusão

Cada classe com responsabilidade clara, GameScreen orquestrador (sem teto rígido de linhas), 0 `StyleBoxFlat.new()/Shader.new()` dinâmicos fora de componentes, `game_screen.tscn` instancia sub-cenas editáveis, 2 `.gdshader` + wrappers `.tres`, timings idênticos, contratos VM/Factory intactos, `godot --import` + GUT 198/198 + F5 sem regressão.

## 8. Execução

- Uma etapa por vez; após cada: `godot --import` + `gut` + revisão regressão + relatório (criados/alterados/removido GameScreen/contratos/testes/riscos).
- Parar e aguardar autorização antes da próxima etapa.
