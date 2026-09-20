# Organização de Assets

## Decisão
- **Assets compartilhados** → `assets/components/<feature>/`
- **Assets específicos de uma feature** → `features/<feature>/assets/`

## Critérios
- **Compartilhados** (reutilizáveis por múltiplas features): `assets/components/game/`
- **Específicos de uma feature** (únicos para aquela feature): `features/<name>/assets/`
- Evitar duplicação e manter caminhos estáveis para `preload()`

## Inventário Atual

### Assets Compartilhados (em `assets/components/game/`)
- Board systems (board_view.gd, board_view.tscn)
- Inventory system (inventory_panel.gd, inventory_panel.tscn, inventory_slot.gd, inventory_slot.tscn)
- Overlays (blind_vignette, effect_overlay)
- Player info (player_info_bar.gd, player_info_bar.tscn)
- Words container (words_container_view.gd, words_container_view.tscn)
- Buttons (orange_btn, link_btn_blue, password_input, transparent_btn)
- Game modes (home_mode_button.gd, home_mode_button.tscn)
- Game overlays (game_over_overlay)
- Powerup icons (rounded_icon.gdshader)
- Fonts (assets/components/fonts/)

### Assets Específicos de Feature
- **home/**: home_mode_button.gd/tscn, mode_description_popup.tscn
- **login/**: (currently empty)
- **inventory/**: inventory_panel.gd/tscn, inventory_slot.gd/tscn
- **new/**: PlayerCard.tscn
- **game/**: (already consolidated in assets/components/game/)

## Recomendações
1. Manter `assets/components/game/` como central de componentes reutilizáveis
2. Manter `features/<name>/assets/` para assets exclusivos de cada feature
3. Quando mover algo de `features/<name>/assets/` para `assets/components/<feature>/`, atualizar:
   - `preload()` nas cenas
   - Referências em `.tscn` (paths)
   - Documentar a mudança

## Próximos Passos
- [ ] Verificar se há assets duplicados entre `assets/components/` e `features/*/assets/`
- [ ] Atualizar preload() e .tscn onde necessário
- [ ] Criar scripts de migração se houver muitos assets para mover
- [ ] Testar no Godot após reorganização
