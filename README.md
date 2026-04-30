# Letra a Letra - Godot Client

> **Letra a Letra** é um jogo multiplayer competitivo que combina caça-palavras com mecânicas inspiradas em batalha naval, criando partidas estratégicas e dinâmicas em tempo real. Este repositório contém a implementação do **cliente** desenvolvido na engine **Godot**, projetado para oferecer uma experiência de jogo fluida, animada e multiplataforma.

![Godot Engine](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godot-engine&logoColor=white) ![GDScript](https://img.shields.io/badge/GDScript-100%25-478cbf) ![License](https://img.shields.io/badge/license-Proprietary-red)

---

## 📝 Sobre o Projeto

Este cliente é parte do ecossistema **Letra a Letra**, um projeto que desafia os jogadores a encontrarem palavras em uma grade compartilhada enquanto utilizam poderes para sabotar seus oponentes.

Desenvolvido em Godot para oferecer uma experiência moderna, fluida e multiplataforma, consumindo a [Letra-a-Letra-API](https://github.com/Zidan-09/Letra-a-Letra-API) do jogo em tempo real.

###  Diferenciais desta Versão

- **Performance Nativa:** Execução leve com renderização otimizada da Godot 4.
- **Interface Reativa:** Feedback visual imediato para ações do jogador e eventos de jogo.
- **Comunicação em Tempo Real:** Sincronização via WebSockets para partidas multiplayer.

---

## 🛠 Tecnologias Utilizadas

- **Engine:** [Godot 4.x](https://godotengine.org/)

- **Linguagem:** GDScript

- **Comunicação:**
  - HTTP (REST) para autenticação e dados persistentes.
  - WebSockets para gameplay em tempo real.

- **Backend:** [Letra-a-Letra-API](https://github.com/Zidan-09/Letra-a-Letra-API) (Spring Boot)

---

## 🧠 Arquitetura

O projeto segue princípios de Domain-Driven Design (DDD), garantindo organização, escalabilidade e separação clara de responsabilidades:

- **Domain:** Regras de negócio e entidades
- **Application:** Casos de uso
- **Infrastructure:** Comunicação externa (API, WebSockets)

---

## 🏗 Estrutura do Projeto

```
game/
├── application/        # Casos de uso e lógica de aplicação
├── domain/             # Entidades e regras de negócio (Domain-Driven Design)
├── infrastructure/     # Implementações técnicas (API, Persistência)
├── scenes/             # Cenas da interface (Login, Lobby, Game)
├── scripts/            # Scripts de suporte e animações
├── assets/             # Sprites, fontes e recursos visuais
├── project.godot       # Arquivo principal do projeto Godot
└── .editorconfig       # Configurações do editor
```

---

## ⚙️ Como Executar

1. **Pré-requisitos:**
  - Ter a [Godot Engine 4.x](https://godotengine.org/download) instalada.
  - Certificar-se de que a [Letra-a-Letra-API](https://github.com/Zidan-09/Letra-a-Letra-API) está rodando localmente ou acessível via rede.

2. **Configuração:**
  - Clone este repositório:
    
       ```bash
       git clone https://github.com/Gabriel-afk-9/Letra-a-Letra-GODOT.git
       ```
  - Abra o projeto na Godot.
  - Ajuste a URL da API no script de configuração se necessário.

3. **Execução:**
  - Pressione `F5` para iniciar o projeto.

---


## 📄 Licença e Uso

**Copyright © 2026 Gabriel-afk-9. Todos os direitos reservados.**

Este software é proprietário. Não é permitida a cópia, modificação, distribuição ou uso do código-fonte para qualquer finalidade sem a autorização expressa do autor. O acesso público ao repositório é apenas para fins de visualização e portfólio.

---

## 👥 Créditos

- **Desenvolvedor Frontend (Godot):** [Gabriel-afk-9](https://github.com/Gabriel-afk-9)

- **Desenvolvedor da API:** [Zidan-09](https://github.com/Zidan-09)
