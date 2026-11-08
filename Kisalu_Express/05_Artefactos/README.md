# Artefactos

## Código e dados do projeto

| Pasta | O que é | Origem | Como correr |
|---|---|---|---|
| [Aplicacao_Movel](Aplicacao_Movel) | App Flutter/Dart (cliente e prestador, 30 ecrãs e folhas, v3; 703 testes) | Conteúdo de `app/` do repositório [kissalu-app](https://github.com/Eng-Infomatica-IADE/kissalu-app) | `flutter run --dart-define=KISALU_API=http://10.0.2.2:3000/api` (10.0.2.2 é o endereço do computador visto pelo emulador Android) |
| [Backend](Backend) | API REST em Node.js, Express 5 e TypeScript (82 endpoints, 83 testes) | Repositório [kisalu-api](https://github.com/Eng-Infomatica-IADE/kisalu-api), sem segredos nem SQL | `docker compose up -d --build` (ou `docker compose up -d db` e `npm run dev`) (ver [LEIA-ME](Backend/LEIA-ME.md)) |
| [Base_Dados](Base_Dados) | Base de dados MySQL 8: `create.sql`, `populate.sql`, `queries.sql` | `database/` do repositório kisalu-api | Executados na criação do contentor da BD (docker compose) |
| [Apresentacoes](Apresentacoes) | Slides de cada apresentação (`apresentacao-01`, ...) | Pasta de trabalho do grupo | – |

Nota: o Gradle (Android) não aceita caminhos com caracteres como "º". Para compilar a app, copie a pasta para um caminho simples (por exemplo `C:\kisalu\`).

As pastas de código são geradas por um script a partir dos repositórios de origem, por isso não se editam aqui.

## Documentos e identidade visual

| Artefacto | Localização |
|---|---|
| Relatório intermédio (2.ª entrega) | [g05-relatorio-intermedio.pdf](../../Documentos/g05-relatorio-intermedio.pdf) · [versão Markdown](../../Documentos/g05-relatorio-intermedio.md) |
| Relatório de Base de Dados (2.ª entrega) | [g05-bd-report.pdf](../../Documentos/g05-bd-report.pdf) · [versão Markdown](../../Documentos/g05-bd-report.md) |
| Proposta de projeto v2 (2.ª entrega) | [g05-proposta-v2.pdf](g05-proposta-v2.pdf) · [versão Markdown](../../Documentos/g05-proposta-v2.md) |
| Mobile App Style Guide | [g05-mobile-style-guide.pdf](g05-mobile-style-guide.pdf) |
| Proposta de projeto (1.ª entrega) | [g05-proposta-v1.pdf](g05-proposta-v1.pdf) · [versão Markdown](../../Documentos/g05-proposta-v1.md) |
| Identidade visual – brand book | [identidade-visual/01_Brand-Book](identidade-visual/01_Brand-Book) |
| Logótipos (SVG e PNG) e ícone da app | [identidade-visual/02_Logos](identidade-visual/02_Logos) |
| Ícones de serviços e de interface (SVG e PNG) | [identidade-visual/03_Icones](identidade-visual/03_Icones) |
| Ficheiro de design (Figma) | [Kisalu Express — Mockups (G05)](https://www.figma.com/design/y6x5pO2mwQpoiF5ep18mSl/Kisalu-Express-%E2%80%94-Mockups--G05-?node-id=68-2) (frame v3.1) |
| Repositório principal | <https://github.com/Eng-Infomatica-IADE/Kisalu-Express> |
