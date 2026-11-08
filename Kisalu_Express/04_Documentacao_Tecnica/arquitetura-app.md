# Arquitetura

Visão do repositório. A documentação detalhada do front-end está em [`docs/frontend/`](https://github.com/Eng-Infomatica-IADE/kissalu-app/blob/main/docs/frontend/README.md): [arquitetura](https://github.com/Eng-Infomatica-IADE/kissalu-app/blob/main/docs/frontend/ARQUITETURA.md), [nomenclatura](https://github.com/Eng-Infomatica-IADE/kissalu-app/blob/main/docs/frontend/NOMENCLATURA.md), [segurança](https://github.com/Eng-Infomatica-IADE/kissalu-app/blob/main/docs/frontend/SEGURANCA.md) e [validações](https://github.com/Eng-Infomatica-IADE/kissalu-app/blob/main/docs/frontend/VALIDACOES.md).

## Visão geral (briefing: MVC + REST, Flutter/Dart, Node.js, MySQL)

```
projeto/                    ← raiz do repositório GitHub
├── app/                    ← Flutter (Android + iOS + web para pré-visualização)
├── docs/                   ← arquitetura, specs das telas, milestones, CONTRATO-API.md
│   ├── design/             ← SCREENS.md · STYLE_GUIDE.md · screens/*.png
│   └── frontend/           ← arquitetura, nomenclatura, segurança, validações da app
├── Documentos/             ← PDFs entregues (briefing, relatório, style guide)
└── .claude/                ← agentes, comandos e definições do Claude Code
```

O back-end (Node.js + Express) e a base de dados MySQL vivem noutro repositório: [kisalu-api](https://github.com/Eng-Infomatica-IADE/kisalu-api). O acordo entre os dois lados está em [`contrato-api.md`](contrato-api.md).

A app tem duas implementações do repositório: `MockKisaluRepository` (dados fictícios, por omissão) e `RestKisaluRepository` (fala com a kisalu-api quando se arranca com `--dart-define=KISALU_API=...`). Views e controllers são os mesmos nos dois casos.

## App Flutter — MVC por funcionalidade

Árvore definida em [`frontend/NOMENCLATURA.md`](https://github.com/Eng-Infomatica-IADE/kissalu-app/blob/main/docs/frontend/NOMENCLATURA.md). **A renomeação foi aplicada ao código**; as tabelas atual → novo desse documento ficam como registo da migração.

```
app/lib/
├── main.dart                 → runApp(KisaluApp)
├── kisalu_app.dart           → MaterialApp.router + tema + Provider<KisaluRepository>
├── core/
│   ├── theme/                → KColors, KTypography, K (tokens), KTheme, KIcons  ← Style Guide
│   ├── router/               → AppRoutes (constantes) + createRouter (go_router)
│   ├── widgets/              → um componente K* por ficheiro + AppShell
│   ├── utils/                → KFormat (k_format.dart: Kz, horas, km, código)
│   ├── validators/           → KValidators (por implementar)
│   └── state/                → EstadoUi (carregar, sucesso, vazio, erro; por implementar)
├── models/                   → MODEL: entidades (Pedido, Proposta, Profissional, Avaliacao, Categoria, EstadoPedido)
├── data/
│   ├── repositories/         → MODEL (acesso a dados): KisaluRepository (contrato) + MockKisaluRepository + RestKisaluRepository
│   └── mock/                 → MockCategorias, MockPedidos, MockProfissionais, MockSessao (dados fictícios)
├── services/                 → api_client.dart (http, envelope e erros → KisaluException) e armazenamento_local.dart (TokenStorage, RascunhoStorage)
└── features/<funcionalidade>/
    ├── views/                → VIEW: <nome>_view.dart, um por ecrã do Figma
    ├── widgets/              → VIEW: peças só desta funcionalidade
    └── controllers/          → CONTROLLER: <nome>_controller.dart, ChangeNotifier com estado de UI e ações
```

Funcionalidades: `autenticacao` (01) · `inicio` (02) · `profissional` (03) · `pedidos` (04, 07, 08) · `confirmacao_qr` (05, 09) · `avaliacao` (06) · `novo_pedido` (10) · `conversas` e `perfil` (placeholders) · `trabalho` (detalhe do trabalho do profissional) · `notificacoes` · `ajuda` · `dev` (galeria de ecrãs).

### Regras de dependência
- `views` → `controllers` → `data/repositories` → `models`. Nunca o contrário.
- `views` não importam `data/mock` diretamente: leem via controller/repositório (`context.read<KisaluRepository>()`).
  Exceção tolerada nas telas estáticas: constantes de UI que não são dados (ex. lista de etiquetas da avaliação) podem vir de `MockData` através do controller.
- `core/` não importa nada de `features/`.
- Uma funcionalidade não importa `views` de outra — navega por rota (`context.go/push(AppRoutes.x)`).

### Estado
- `provider` + `ChangeNotifier` (controllers). Estado efémero de um só widget (ex. banner fechado) pode ficar num `StatefulWidget`.
- Controllers recebem o repositório no construtor (testáveis com o mock).

### Navegação (`go_router`)
- `StatefulShellRoute.indexedStack` com 5 ramos = 5 separadores (Início, Pedidos, QR, Conversas, Perfil).
- Ecrãs de fluxo (Login, Perfil do profissional, Avaliar, Novo pedido) usam o navigator raiz (sem barra inferior).
- Rota inicial: `/login`. A galeria abre-se à mão pelo URL `/dev`, em debug. `/dev` e `/qr?vazio=1` não podem existir em produção ([`frontend/SEGURANCA.md`](https://github.com/Eng-Infomatica-IADE/kissalu-app/blob/main/docs/frontend/SEGURANCA.md)).

### Dependências
| Pacote | Para quê |
|---|---|
| `go_router` | navegação declarativa + separadores |
| `provider` | injeção do repositório e controllers (MVC) |
| `google_fonts` | Sora e DM Sans (Style Guide). Pode-se empacotar os .ttf em `assets/google_fonts/` para funcionar offline |
| `flutter_svg` | ícones e logótipo SVG quando forem exportados do Figma |
| `qr_flutter` | QR do ecrã 05 |
| `lucide_icons_flutter` | Ícones do Figma v2 (Lucide) |
| `http` | pedidos à kisalu-api (`ApiClient`); `MockClient` nos testes |
| `flutter_secure_storage` | token de sessão no Keystore/Keychain (RF01 "sessão mantida", STORAGE-1 em `frontend/SEGURANCA.md`) |
| `shared_preferences` | rascunho do novo pedido em JSON (RM07); não guarda dados sensíveis |

Não adicionar pacotes sem necessidade clara (RM03: app leve).

## Ligação à API (REST)
1. `services/api_client.dart`: endereço de `KISALU_API`, token só em memória (`Authorization: Bearer`), timeout, lê `data` do envelope `{title, status, detail, instance, data}` e converte os erros HTTP em `KisaluException` (tabela na secção 0 do contrato).
2. `data/repositories/rest_kisalu_repository.dart` implementa `KisaluRepository` endpoint a endpoint (secção 2 do contrato).
3. `models/*` têm `fromJson` (e `toJson` nos que se enviam); a leitura defensiva está em `models/json_leitura.dart`.
4. `main.dart` escolhe o repositório: com `KISALU_API` usa o REST, sem ele o mock. Um 401 limpa a sessão e `kisalu_app.dart` volta a `/login`.
5. API Node.js (Express) e MySQL: repositório [kisalu-api](https://github.com/Eng-Infomatica-IADE/kisalu-api).
