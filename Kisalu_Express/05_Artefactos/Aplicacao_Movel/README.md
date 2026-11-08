# Kisalu Express — Protótipo da aplicação

Unidade curricular: Programação de Dispositivos Móveis · 2026/27 · Grupo 05

## Elementos do grupo
- Álvaro da Silva (20252049)
- Adilson Yango (20252312)
- Milton Malavo (20252099)

## Tema do projeto
Marketplace móvel que liga clientes a prestadores de serviços informais (biscateiros) em Angola. O cliente publica um pedido, compara propostas com preço fechado em kwanzas, aceita, confirma o serviço por QR Code e avalia.

## Ecrãs disponíveis
| N.º | Ecrã | Como chegar |
|---|---|---|
| 01 | Login / Registo | Ecrã inicial |
| 02 | Início e pesquisa | Depois do código SMS (cliente); separador Início |
| 03 | Perfil do profissional | Cartão ou "Ver" em "Perto de si"; "Ver" no mapa |
| 04 | Pedido e propostas | Separador Pedidos → pedido em curso; depois de publicar um pedido |
| 05 | Confirmação por QR Code | Separador QR (cliente) |
| 06 | Avaliação do serviço | Sozinho, quando o profissional confirma (ecrã 05); "Avaliar" num pedido concluído do 07; nos dados fictícios, toque no QR |
| 07 | Histórico de pedidos | Separador Pedidos (no modo profissional mostra os trabalhos do profissional) |
| 08 | Confirmar a proposta | "Ver e aceitar" no ecrã 04 |
| 09 | QR sem serviço em curso | Separador QR, quando não há serviço em curso |
| 10 | Novo pedido (com passos e estado sem rede) | "Pedir serviço", categorias ou pesquisa |
| 11 | Código SMS (com o estado 11b, código errado) | "Receber código SMS" ou "Criar conta" no Login; o código `000000` mostra o 11b |
| 12 | Criar perfil (profissional) | "Criar conta" como profissional, depois do código |
| 13 | Verificar identidade | "Continuar" no ecrã 12 |
| 14 | Início do profissional | Código SMS como profissional; "Mudar para profissional" no Perfil; separador Início |
| 15 | Enviar proposta | "Ver pedido" no ecrã 14 |
| 16 | Confirmar serviço (ler o QR do cliente) | Separador QR no modo profissional |
| 17 | Serviço confirmado | "Confirmar serviço" no ecrã 16 |
| 18 | Conversas | Separador Conversas |
| 19 | Conversa do pedido | Uma linha do ecrã 18 |
| 20 | Perfil (com a folha 20b, terminar sessão) | Separador Perfil; "Terminar sessão" abre a 20b |
| 21 | Todos os serviços | "Ver todos" no Início |
| 22 | Mapa "Perto de si" | Chip "Mapa" no Início |
| — | Notificações | Sino dos ecrãs 02 e 14; Perfil → "Notificações" |
| — | Ajuda (perguntas frequentes) | "Precisa de ajuda? Fale connosco" no Login; Perfil → "Ajuda e apoio" |
| — | O trabalho (profissional) | Separador Pedidos em modo profissional → um trabalho |

Os três últimos não estão no Figma: foram acrescentados depois do QA (ver `docs/design/SCREENS.md`, "Ecrãs e ações acrescentados depois do QA").

O perfil ativo (cliente ou profissional) decide o Início, o QR e os Pedidos. Troca-se em Perfil → "Mudar para profissional" / "Mudar para cliente".

## Instruções de execução
Requer o Flutter 3.47 ou superior (Dart 3.13).

```bash
flutter pub get
flutter run
```

O ponto de entrada é `lib/main.dart`. A primeira execução precisa de internet para descarregar a fonte Sora.

Assim, sem mais nada, a app usa os dados fictícios (secção seguinte).

### Ligar à API
O back-end e a base de dados estão no repositório [kisalu-api](https://github.com/Eng-Infomatica-IADE/kisalu-api). Com a API a correr na porta 3000:

```bash
# emulador Android (10.0.2.2 é o computador visto do emulador)
flutter run --dart-define=KISALU_API=http://10.0.2.2:3000/api

# browser ou desktop, na mesma máquina
flutter run -d chrome --dart-define=KISALU_API=http://localhost:3000/api
```

Num telemóvel físico, usa-se o IP do computador na rede local (`http://192.168.x.x:3000/api`). Em debug, o Android aceita HTTP sem TLS (`android/app/src/debug/AndroidManifest.xml`).

Utilizadores de exemplo (dados fictícios da API):

| Pessoa | Telemóvel | Perfil |
|---|---|---|
| Maria Kiala | +244 923 000 000 | cliente |
| Joaquim Manuel | +244 923 000 002 | profissional |

O SMS não é enviado: o código aparece no terminal onde corre a API. Em modo debug, a app recebe-o na resposta e o ecrã 11 já abre preenchido. No ecrã 16, o código do cliente de exemplo é `482173`.

A sessão fica guardada no aparelho (`flutter_secure_storage`; no Chrome, cifrada pelo próprio pacote): ao abrir a app outra vez, se o token ainda for aceite, entra direto no Início do perfil ativo. "Terminar sessão" apaga-o. Se a API responder 401 (sessão expirada), a app volta ao Login. O rascunho do novo pedido também fica guardado (`shared_preferences`) até ser publicado. A forma de cada pedido e resposta está em [`docs/CONTRATO-API.md`](https://github.com/Eng-Infomatica-IADE/kissalu-app/blob/main/docs/CONTRATO-API.md).

## Funcionalidades simuladas
Sem `KISALU_API` não há base de dados, API nem armazenamento persistente. Os dados são objetos Dart em `lib/data/mock/`, servidos por `MockKisaluRepository`, e reiniciam ao fechar a app.

- Autenticação: o SMS não é enviado. No ecrã 11 qualquer código de 6 dígitos confirma, exceto `000000`. O reenvio é simulado com uma contagem decrescente de 42 s. O número vive só em memória, no repositório (nunca na rota).
- Perfil ativo: cliente ou profissional, guardado em memória. O profissional vê pedidos e trabalhos fictícios, só com zona e distância (nunca a morada nem o contacto do cliente).
- Registo e verificação do profissional (12 e 13): nada é enviado; o documento, a fotografia do rosto e a fotografia de perfil são simulados (tocar na linha marca-os como enviados).
- Proposta (15): o valor fechado é a soma de três componentes editáveis; ao enviar, fica guardada em memória.
- Confirmação por QR (16): não há leitura por câmara nem pacote de câmara; o visor é um desenho. Qualquer código de 6 dígitos confirma o trabalho, exceto `000000`. No ecrã 05 (cliente) o QR continua fictício e tocar nele avança para a avaliação (só nos dados fictícios; com a API, o ecrã avança sozinho quando o profissional confirma).
- Notificações, ajuda, recusar propostas, editar pedidos, etapas do trabalho e reportar problemas: tudo em memória, com dados fictícios (`lib/data/mock/mock_avisos.dart`).
- Conversas (18 e 19): as mensagens enviadas ficam só em memória; a foto mostra "Em breve".
- Pedidos, propostas e avaliações: alteram apenas o estado em memória.
- Falta de rede: o ecrã 10 simula a ausência de ligação.
- Fotografias: apenas um contador ou uma mensagem; não abre a galeria nem a câmara.
- Mapa (22): desenho estático com `CustomPaint`, sem pacote de mapas nem localização real.
- Ações com a mensagem "Em breve": ligar (19 e detalhe do trabalho), a faixa do pedido na conversa (19), centrar no meu local (22), "Ver todos" no Início do profissional, as linhas do menu do Perfil sem ecrã (dados, moradas, favoritos, privacidade), "Adicionar fotografia" (12), foto na conversa e partilhar o comprovativo.

## Organização do código
```
lib/
├── main.dart         ponto de entrada
├── kisalu_app.dart   MaterialApp, tema e repositório
├── core/             tema, rotas, validações e widgets reutilizáveis (K*)
├── data/             repositório (mock e REST) e dados de exemplo
├── models/           entidades, com fromJson
├── services/         ApiClient (http) e armazenamento local (token, rascunho)
└── features/         uma pasta por funcionalidade: views, controllers, widgets
```
