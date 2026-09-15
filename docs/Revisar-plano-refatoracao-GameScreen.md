Revise o plano de implementação da refatoração da `Game Screen` que você acabou de elaborar.

Ainda NÃO implemente nada e NÃO altere nenhum arquivo. Quero somente que você atualize o plano com as decisões e melhorias abaixo.

### 1. Estrutura obrigatória dos componentes

Todos os componentes específicos da Game Screen devem ficar dentro desta estrutura:

```text
assets/
└── components/
    └── game/
        └── components/
            ├── board/
            ├── inventory/
            ├── overlays/
            ├── words/
            └── player/
```

Cada componente deve manter seu `.tscn` e `.gd` juntos.

Exemplo:

```text
assets/components/game/components/board/
├── board_view.tscn
├── board_view.gd
├── cell_view.tscn
└── cell_view.gd
```

Não criar uma pasta separada de `scripts` para esses componentes.

Essa estrutura deve ser considerada parte da arquitetura final e utilizada em todo o plano.

### 2. Responsabilidade dos componentes

Refine o plano para garantir que a refatoração não seja apenas uma divisão das 2.000+ linhas em vários arquivos.

Cada componente deve possuir responsabilidade própria e bem definida.

A regra deve ser:

**O componente é responsável pela própria apresentação visual, estilos, animações e comportamento diretamente relacionado à sua interface.**

Por exemplo:

- `BoardView` gerencia o tabuleiro e suas células.
- `CellView` gerencia a apresentação e as animações de uma célula.
- `InventoryPanel` gerencia o inventário.
- `InventorySlot` gerencia o próprio slot.
- `WordsContainer` gerencia as palavras exibidas.
- `WordPill` gerencia a própria aparência.
- `EffectOverlay`, `BlindVignette` e `GameOverOverlay` gerenciam seus próprios efeitos e estados visuais.
- `PlayerInfoBar` gerencia a apresentação das informações do jogador.

Evite que `game_screen.gd` continue manipulando diretamente propriedades internas desses componentes.

### 3. Papel do game_screen.gd

Defina claramente no plano que `game_screen.gd` será o coordenador/orquestrador da tela, e não o responsável por desenhar a interface.

Ele deve principalmente:

- coordenar os componentes;
- receber eventos do ViewModel/backend;
- encaminhar dados aos componentes;
- reagir aos sinais emitidos pelos componentes;
- controlar o fluxo da tela;
- tratar navegação;
- manter somente o estado que realmente pertence à Game Screen.

Ele não deve:

- criar manualmente a estrutura visual que pode existir na cena;
- aplicar estilos individuais nos componentes;
- controlar animações internas dos componentes;
- acessar diretamente nós internos de outros componentes;
- conhecer detalhes de implementação de `CellView`, `InventorySlot`, `WordPill`, etc.

### 4. Comunicação entre GameScreen e componentes

Defina no plano uma API pública clara para cada componente.

Prefira métodos e sinais de alto nível, por exemplo:

```gdscript
board_view.apply_state(...)
board_view.shake(...)
board_view.reveal(...)
inventory_panel.update(...)
words_container.update_words(...)
```

em vez de:

```gdscript
game_screen.some_child.some_nested_node.modulate = ...
```

Os componentes devem esconder seus detalhes internos.

Também revise a questão do `_cell_buttons`.

Evite manter estruturas internas do `BoardView` expostas ao `GameScreen` apenas para preservar a arquitetura antiga ou facilitar testes.

Os testes devem utilizar a API pública dos componentes sempre que possível.

### 5. Utilização da árvore de nós da Godot

A estrutura visual deve ser construída preferencialmente no `.tscn` e editável pelo editor da Godot.

Antes de criar qualquer lógica de posicionamento por código, verificar se o problema pode ser resolvido usando:

- `Container`;
- `VBoxContainer`;
- `HBoxContainer`;
- `CenterContainer`;
- `MarginContainer`;
- anchors;
- `size_flags`;
- `custom_minimum_size`;
- propriedades de tema;
- outras ferramentas nativas de layout da Godot.

Não recriar via código algo que a própria árvore de nós e os Containers podem resolver.

### 6. BoardView e CellView

Mantenha a decisão de utilizar:

```text
BoardView
└── CellView x100
```

com as células sendo criadas dinamicamente, já que o tabuleiro é 10×10 e seu estado vem do backend.

Porém, deixe claro no plano:

- `BoardView` controla a coleção e coordenação das células;
- `CellView` controla sua própria apresentação;
- `BoardView` não deve conhecer detalhes visuais internos da `CellView`;
- `GameScreen` não deve manipular diretamente as células.

### 7. Layout atual

A refatoração deve preservar o layout atual.

Não redesenhar a interface.

O objetivo é mudar a organização interna e a forma como a UI é construída, mantendo:

- posições;
- tamanhos;
- espaçamentos;
- hierarquia visual;
- estilos;
- animações;
- comportamento;
- responsividade;
- interações existentes.

Quando houver necessidade de alterar alguma estrutura visual para viabilizar a arquitetura, documente isso no plano e explique como garantir que o resultado visual permaneça equivalente.

### 8. Responsividade

Revise a etapa de `BoardWrapper`, `WordsWrapper` e `BoardInventorySpacer`.

Antes de manter esses wrappers, verifique se a mesma estrutura pode ser obtida de forma mais simples utilizando os `Container` e recursos de layout da Godot.

Não crie wrappers apenas para reproduzir via código uma estrutura que pode ser declarada diretamente na cena.

### 9. Testes

Atualize o plano para que os testes validem comportamento e contratos dos componentes, e não detalhes da implementação.

Evite testes baseados em:

```gdscript
FileAccess.get_file_as_string(...)
```

ou procura de strings no código-fonte.

Prefira testar:

- sinais;
- estados;
- comportamento;
- chamadas da API pública;
- existência/configuração dos nós relevantes;
- interação entre `GameScreen` e componentes.

Mantenha os testes GUT existentes e indique quais precisarão ser adaptados.

### 10. Shaders e recursos visuais

Revise a organização dos shaders e recursos utilizados exclusivamente por um componente.

Sempre que um recurso for específico de um componente, prefira mantê-lo próximo daquele componente ou dentro do domínio correspondente.

Não deixe detalhes puramente visuais dentro do `game_screen.gd`.

### 11. Evitar overengineering

Não adicione camadas, managers, controllers, services, presenters ou abstrações apenas por aplicar um padrão arquitetural.

Toda nova classe deve existir porque possui uma responsabilidade concreta.

A prioridade é:

**simplicidade + baixo acoplamento + responsabilidade única + facilidade de edição pelo Godot Editor + manutenção futura.**

### 12. Resultado esperado

Depois dessas alterações, apresente novamente o plano completo de implementação, já revisado.

Quero que o plano final contenha:

1. arquitetura atual identificada;
2. arquitetura proposta;
3. árvore de nós proposta para `game_screen.tscn`;
4. estrutura final de pastas;
5. componentes que serão criados;
6. responsabilidade de cada componente;
7. API pública e sinais de cada componente;
8. responsabilidades que permanecerão no `game_screen.gd`;
9. responsabilidades que serão removidas dele;
10. ordem incremental de implementação;
11. estratégia de migração;
12. estratégia de testes;
13. riscos e mitigação;
14. critérios para considerar cada etapa concluída.

A estrutura de pastas abaixo é obrigatória no plano:

```text
assets/components/game/components/
├── board/
├── inventory/
├── overlays/
├── words/
└── player/
```

Não implemente nada ainda. Apenas revise e apresente o plano final atualizado.