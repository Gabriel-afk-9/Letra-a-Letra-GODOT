# Plano de Testes — Letra a Letra Godot Client

> **Data:** 2026-09-04
> **Engine:** Godot 4.7, GDScript, `renderer="mobile"` viewport 360x640
> **Arquitetura:** Clean Architecture + Feature-First (`game/features/<nome>/`)
> **Estado atual:** 0 testes, 0 linter, 0 CI — validação só via F5

## 1. Objetivo

Estabelecer pirâmide de testes automatizados sem quebrar regras do projeto (`View→ViewModel→UseCase→Repository`, `ServiceRegistry` singleton, tab indentação). Fase 1 foca em **unitários puros sem mocks** (mappers/catalog/serializers) — maior ROI, menor risco.

## 2. Ferramenta

**GUT 9.7.1** (`addons/gut`) — `class_name GutTest`, asserts `assert_eq/assert_true`, `watch_signals`, suporte `await`, CLI `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gexit`. Escolhido vs GdUnit4/WAT por maturidade GDScript 4.7 e docs PT-BR. Compatível Godot 4.7.1 (9.6.1 mostrava `GUT (Indefinido)` e `WARNING uid://`).

Instalação:
1. `game/addons/gut` via `git clone --branch v9.7.1 --depth 1 https://github.com/bitwes/Gut.git` → copiar `addons/gut` para `game/addons/gut`
2. Ativar `Project > Project Settings > Plugins > GUT Enabled` (deve mostrar `Gut 9.7.1`, não `(Indefinido)`)
3. CLI: `godot --headless --path game --import` (primeira vez) depois `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit` (usa `game/.gutconfig.json`)

## 3. Pirâmide

| Tipo | Alvo neste projeto | Exemplos | Quando |
|------|-------------------|----------|--------|
| **Unit (70%)** | Mappers puros, `GamePowerCatalog`, `GameInternalEvent`, `JsonSerializer`, `WebSocketMessage` | `GameBoardMapper.to_domain([])`, `GamePowerCatalog.is_offensive("FREEZE")` | Fase 1 (agora) |
| **Integração (20%)** | `RemoteGameRepository` buffering `_pending_*`, `_first_string` root-vs-data, `RemoteMatchmakingRepository` FOUNDED | Mock `WebSocketClient` emit `message_received` | Fase 2 |
| **Contrato WS (10%)** | Fixtures JSON `PLAYER_ACTION_RESULT`, `MATCHMAKING_GAME FOUNDED` vs `docs/websocket-events-contract.md` | `WebSocketMessage.from_dictionary(fixture).event=="PLAYER_ACTION_RESULT"` | Fase 2 |
| **UI Smoke (seletivo)** | `GameScreen._update_board_interactivity`, `PlayerCard` estados | `add_child_autofree` + `assert_eq(button.mouse_filter, ...)` | Fase 3 se dor |

Não testar: `AnimatedBtn`, `Spinner` addon, layout `.tscn` pixel-perfect.

## 4. Estrutura

```
game/
  addons/gut/                 # plugin GUT
  tests/
    unit/
      mappers/test_game_board_mapper.gd
      mappers/test_game_cell_mapper.gd
      mappers/test_game_word_mapper.gd
      mappers/test_game_power_mapper.gd
      mappers/test_game_player_state_mapper.gd
      domain/test_game_power_catalog.gd
      domain/test_game_internal_event.gd
      infra/test_json_serializer.gd
      infra/test_websocket_message.gd
    integration/              # Fase 2
    fixtures/                 # JSON WS reais
```

Convenção: `extends GutTest`, `func test_*`, AAA, tab indentação, sem `print`, file `*.gd` espelha `*.gd` de produção.

## 5. Fase 1 — 15 Testes Unit Sem Mocks

| # | Arquivo | Caso | Assert |
|---|---------|------|--------|
| 1 | `test_game_board_mapper` | `to_domain([])` vazio | `board.rows.size()==0` |
| 2 | `test_game_board_mapper` | `1x1` revelada `letter:"A" revealed:true revealedBy:"id1"` | `get_cell(0,0).letter=="A" && revealed` |
| 3 | `test_game_board_mapper` | `2x2` com `effect` BLOCK em (0,1) | `get_cell(0,1).effect_type=="BLOCK"` |
| 4 | `test_game_cell_mapper` | `effect=null` sem efeito | `effect_type==""` |
| 5 | `test_game_cell_mapper` | `letter null` → `""` | `letter==""` |
| 6 | `test_game_word_mapper` | `found:true foundById:"p1"` | `found==true && found_by=="p1"` |
| 7 | `test_game_power_mapper` | `FREEZE` sem `rarity` → fallback `RARE` via catalog | `type=="FREEZE" && rarity=="RARE"` |
| 8 | `test_game_player_state_mapper` | `inventory:[null,{"id":"a","name":"TRAP"}]` size 5 | `inventory[0]==null && inventory[1].type=="TRAP"` |
| 9 | `test_game_power_catalog` | `FREEZE` offensive+GLOBAL | `is_offensive==true && get_scope=="GLOBAL"` |
|10 | `test_game_power_catalog` | `UNFREEZE/IMMUNITY can_use_while_frozen` vs `BLIND` | `UNFREEZE true`, `IMMUNITY true`, `BLIND false` |
|11 | `test_game_power_catalog` | Tipo desconhecido → `SCOPE_GLOBAL` fallback | `get_scope("UNKNOWN")=="GLOBAL"` |
|12 | `test_game_internal_event` | `WORD_FOUNDED` cells `[{x:1,y:2},{x:1,y:3}]` | `get_founded_cells()==[V(1,2),V(1,3)]` |
|13 | `test_game_internal_event` | `contains_player_id` | `contains("id1")==true` |
|14 | `test_json_serializer` | roundtrip `{"a":1,"b":[2]}` | `decode(encode(dict))["a"]==1` |
|15 | `test_websocket_message` | `from_dictionary` ERROR com `data.y` | `event=="ERROR" && data["y"]==1 && raw.has("event")` |

## 6. Fase 2 (próxima)

* `GameViewModel.get_cell_visual_state` com `FakeGameRepository` (claimed vs revealed), `_parse_turn_deadline` trim `Z`, `action_lock` geração.
* `RemoteGameRepository` buffering `_pending_*` antes de `start(game_id)`, `_first_string` root-vs-data.
* Contrato WS fixtures `docs/websocket-events-contract.md`.

## 7. Execução

Editor: `Project > Tools > GUT > Run` (usa `game/.gutconfig.json`)  
CLI (recomendado): `godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gprefix=test_ -gexit`  
CLI via `.gutconfig.json` (sem args): `godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit`  
CI futuro: `windows-latest` + `godot --headless` step

> Godot 4.7.1 requer ` --import` na primeira execução após instalar GUT (`godot --headless --path game --import`).

## 8. Critérios de Aceite Fase 1

* 37/37 verdes (15 casos → 37 asserts), <1s, sem `push_error` em `GameRepository` — verificado 2026-09-04: `37 passed` `All tests passed!`
* Nenhuma alteração em `game/features/game/` (só `tests/` + `addons/gut` + `project.godot` + `.gutconfig.json`)
* `project.godot` habilita GUT sem quebrar autoloads `GlobalEnvironment/ServiceRegistry/SessionStore`

## 9. Hardening Futuro

* `encrypt_pck=true` em `export_presets.cfg` não afeta testes headless
* `log_debug=false` em prod — testes verificam `AppLogger` desligado via provider
