# Kisalu Express · API

API REST do marketplace de serviços informais **Kisalu Express** ("Quem sabe, resolve."), feita com **Node.js, Express 5, TypeScript e MySQL 8**.
Implementa os requisitos do Relatório da Fase 1 (G05) e o contrato com a app Flutter (`docs/CONTRATO-APP.md`): entrada com código por SMS (ou por email), perfil de cliente e de profissional na mesma conta, pedidos, propostas com preço fechado em Kz, confirmação por QR Code com código alternativo, comprovativo, garantia de 7 dias, avaliações, chat e notificações.

## Arranque rápido

Precisa de **Node.js 20+** e **MySQL 8** (ou MariaDB 10.6+).

```bash
npm install
cp .env.example .env          # preencha DB_USER, DB_PASSWORD e JWT_SECRET
npm run db:reset              # cria a base kisalu_express: create.sql + populate.sql
npm run dev                   # http://localhost:3000/api
```

Abra **http://localhost:3000/docs** para ver e testar todos os endpoints no Swagger.

### Com Docker

Só precisa do **Docker**. O MySQL corre num contentor e, no primeiro arranque, corre `database/create.sql` e depois `database/populate.sql`.

```bash
cp .env.example .env          # defina DB_PASSWORD (obrigatória) e JWT_SECRET
docker compose up -d --build  # API em http://localhost:3000/api
```

| Comando | O que faz |
| --- | --- |
| `docker compose logs -f api` | Ver os logs da API |
| `docker compose down` | Parar (os dados ficam guardados) |
| `docker compose down -v` | Parar e apagar a base, os uploads e as imagens privadas (o próximo `up` recria os dados de exemplo) |
| `docker compose up -d --build` | Reconstruir depois de mudar o código |

O MySQL do contentor fica acessível no seu computador na porta **3307** (mude com `DB_HOST_PORT` no `.env`).

Os emails enviados pela API (códigos de entrada) aparecem no **Mailpit**: http://localhost:8025.

Também pode correr só o MySQL no Docker e a API com `npm run dev`: `docker compose up -d db` e, no `.env`, `DB_PORT=3307`.

### Entrar e criar conta (desenvolvimento)

A entrada é feita com um código de 6 dígitos enviado por **SMS**. Não há passwords. O SMS é simulado (`src/services/sms.ts`): o texto aparece no terminal da API e, fora de produção, o código vem também em `codigo_dev`.

1. `POST /api/auth/sms/pedir` com `{ "telemovel": "+244923000000", "perfil": "cliente" }` → `codigo_dev`. Só se pode pedir outro código passado 1 minuto.
2. `POST /api/auth/sms/verificar` com o telemóvel, o código e o perfil → devolve `token`, `perfil_ativo` e o utilizador.
3. No Swagger, carregue em **Authorize** e cole o token.

**Criar conta:** com um número novo, o passo 2 cria a conta se enviar `aceita_privacidade: true`. Com `perfil: "profissional"` cria também o perfil profissional por completar (`precisa_registo: true`), que se completa com `PUT /api/profissionais/eu`.

**Cliente e profissional:** a mesma pessoa pode usar a app nos dois modos. O modo vem da sessão (`perfil_ativo`) e muda com `PUT /api/eu/perfil-ativo`.

**Por email** (alternativa, mantém-se): `POST /api/auth/codigo/pedir` com `{ "email": "maria@exemplo.com" }` e depois `POST /api/auth/codigo/verificar`. Um email novo precisa de `nome`, `telemovel`, `tipo_perfil` e `aceita_privacidade: true`.

Utilizadores de exemplo (dados fictícios, iguais ao mock da app):

| Telemóvel | Email | Nome | Perfil |
| --- | --- | --- | --- |
| +244923000000 | maria@exemplo.com | Maria Kiala | cliente (Talatona, 2 moradas, 3 favoritos, pedido 1 com 3 propostas) |
| +244923000002 | joaquim@exemplo.com | Joaquim Manuel | profissional: canalizador e pedreiro, verificado, 4.8 em 126 avaliações, a 1,2 km da Maria |
| +244923000003 | rui@exemplo.com | Rui Santos | profissional: canalizador e pedreiro |
| +244923000005 a 09 | paulo@, ana.cardoso@, carlos@, nuno@, helder@exemplo.com | Paulo Neto, Ana Cardoso, Carlos Dias, Nuno Ferreira, Hélder Tavares | profissionais |
| +244923000010 a 14 | (ver `populate.sql`) | Maria Sebastião, Pedro Kiluange, Ana Paulo, Rui Bento, Teresa Mbala | clientes |
| +244923000099 | admin@exemplo.com | Administrador Kisalu | admin |

Em desenvolvimento, `CODIGO_QR_FIXO_DEV=482173` faz com que o código alternativo ao QR seja sempre 482173 (útil para demonstrar o ecrã 16). Se o mesmo profissional tiver vários serviços por confirmar, `POST /pedidos/confirmar` confirma o que o cliente abriu no ecrã do QR mais recentemente.

Os telemóveis têm de ser angolanos: `+244` e 9 dígitos começados por 9 (aceita `923 000 000`, `00244…` e `244…`).

## Scripts

| Comando | O que faz |
| --- | --- |
| `npm run dev` | Servidor com recarga automática |
| `npm run build` / `npm start` | Compila para `dist/` e arranca em produção |
| `npm run db:reset` | Apaga e recria a base de dados: `create.sql` + `populate.sql` |
| `npm run db:reset -- --consultas` | O mesmo e corre também `queries.sql` (altera alguns dados de exemplo) |
| `npm test` | Corre os 66 testes automáticos (cria a base `kisalu_express_test`) |
| `npm run typecheck` | Verifica os tipos TypeScript |

## Estrutura

```
database/
  create.sql            Tabelas, índices, triggers e vistas
  populate.sql          Dados de exemplo (os mesmos do mock da app)
  queries.sql           Consultas de exemplo comentadas, por ecrã (login, categorias, painel, QR…)
docs/CONTRATO-APP.md    Contrato de integração com a app Flutter (formas JSON e endpoints)
src/
  app.ts                Monta o Express, o CORS, o Swagger (/docs) e os uploads (/uploads)
  config/               Variáveis de ambiente e ligação MySQL (pool + transações)
  routes/               Rotas (route(...)): caminho, acesso e schemas Zod de pedidos e profissionais
  controllers/          Handlers: regras de negócio e resposta (pedidos, profissionais, confirmação por QR)
  models/               Acesso a dados: o SQL por entidade (pedido, proposta, profissional, conversa, utilizador, confirmação)
  services/             Formatos JSON do contrato (a "vista" da API), conta, notificações, SMS, email
  modules/              Restantes áreas ainda no formato rota + handler no mesmo ficheiro (auth, servico, conversas…)
  middlewares/          JWT, erros, upload e compressão de imagens
  utils/route.ts        Uma definição por rota → Express + validação Zod + Swagger
  utils/validacoes.ts   Telemóvel angolano, códigos de 6 dígitos e mensagens do Zod em português
tests/                  Testes com Vitest + Supertest contra MySQL real
uploads/                Imagens públicas (comprimidas para 1280 px, JPEG)
privado/                Documentos de identidade e fotos de reclamações: fora de /uploads, só o admin as vê pela API
```

### Model, View, Controller

A API segue a separação MVC pedida na cadeira. A separação está completa nos pedidos, nos profissionais e na confirmação por QR; os restantes módulos já usam os models para propostas, conversas e utilizadores, mas ainda guardam parte do seu SQL junto das rotas.

| Camada | Pasta | O que faz | Exemplo |
| --- | --- | --- | --- |
| Model | `src/models/` | Todo o SQL de uma entidade; não sabe nada de HTTP | `pedidoModel.trabalhosPorConfirmar()` |
| View | `src/services/formatos.ts` | Converte linhas da base nas formas JSON do contrato (PedidoJSON, PropostaJSON…) | `pedidoJSON()` |
| Controller | `src/controllers/` | Lê `req.valid`, aplica as regras e chama models e views | `pedidosController.editar()` |
| Rotas | `src/routes/` | Liga caminho + acesso + schema Zod ao controller | `route(router, { path: '/pedidos/:id' … }, C.detalhe)` |

| Antes | Agora |
| --- | --- |
| `modules/pedidos.ts` | `routes/pedidos.ts` → `controllers/pedidosController.ts` → `models/pedidoModel.ts`, `propostaModel.ts`, `conversaModel.ts`, `profissionalModel.ts`, `confirmacaoModel.ts` |
| `modules/profissionais.ts` | `routes/profissionais.ts` → `controllers/profissionaisController.ts` → `models/profissionalModel.ts` |
| confirmação em `modules/servico.ts` | rotas em `modules/servico.ts` → `controllers/confirmacaoController.ts` → `models/confirmacaoModel.ts`, `propostaModel.ts` |
| contactos e conversas em `modules/servico.ts` e `modules/conversas.ts` | `models/utilizadorModel.ts`, `models/conversaModel.ts` |
| `modules/auth.ts`, `catalogo.ts`, `moradas.ts`, `conversas.ts`, `admin.ts`, `servico.ts` | Mantêm rota e handler no mesmo ficheiro; passam para `routes/` + `controllers/` + `models/` da mesma forma |

Cada rota é declarada uma só vez em `route(...)` com os seus schemas Zod. Desta definição saem a validação dos dados e a documentação Swagger, por isso a documentação acompanha sempre o código.

## Regras de negócio

| Regra | Onde está | Requisito |
| --- | --- | --- |
| Morada exata e telemóvel só depois de aceitar a proposta | `GET /pedidos/:id` | RNF10 |
| Uma proposta por profissional; total = mão de obra + material + deslocação | BD (UNIQUE + coluna gerada) | RF04, RF15 |
| Aceitar é atómico: aceita, recusa as outras, gera QR + código, abre o chat | `POST /propostas/:id/aceitar` (transação) | RF05 |
| O preço só muda com aprovação; com alteração pendente não se confirma | `alteracoes-preco` | RF08, O4 |
| "Concluído" só pela leitura do QR ou do código de 6 dígitos | `POST /pedidos/confirmar` e `POST /pedidos/:id/confirmar` + trigger | RF10 |
| Só se avalia um serviço confirmado, uma vez | trigger `trg_avaliacao_valida` | RF12 |
| Reclamações até 7 dias depois de concluído | trigger `trg_reclamacao_garantia` | RF11 |
| Média de estrelas e n.º de serviços atualizados automaticamente | triggers | RF06 |
| Imagens redimensionadas e comprimidas antes de gravar | `middlewares/upload.ts` | RM03 |

Todas as respostas em `/api` (sucesso e erro) têm a mesma forma:

```json
{ "title": "...", "status": 200, "detail": "...", "instance": "/api/...", "data": ... }
```

- **Sucesso:** o conteúdo vai em `data` (`null` quando não há nada a devolver, ex.: apagar).
- **Erro:** `detail` traz a mensagem em português pronta a mostrar na app e `data` traz `{ "codigo", "detalhes?" }` (RNF07). Nos dados inválidos, `detail` é a mensagem do primeiro problema (com o texto do catálogo de validações da app) e `detalhes` traz todos.

## Pontos de integração

- **SMS** (`src/services/sms.ts`): simulado, escreve no terminal. Para enviar a sério, liga-se aqui um fornecedor de SMS sem mexer no resto.
- **Email** (`src/services/email.ts`): envia por SMTP (variáveis `SMTP_*` e `EMAIL_FROM` no `.env`; serve Gmail, Brevo, Resend, etc.). Sem `SMTP_HOST`, o email só aparece no terminal. Fora de produção, o código vem também em `codigo_dev`.
- **Push** (`src/services/notificacoes.ts`): ligar o Firebase Cloud Messaging. As notificações já ficam gravadas e são devolvidas em `GET /notificacoes`.
- **CORS**: `CORS_ORIGINS` no `.env`, com as origens separadas por vírgulas. Vazio aceita qualquer origem, mas só em desenvolvimento: em produção a API não arranca sem a lista.
- **Imagens privadas**: documentos de identidade, fotografias do rosto e fotos de reclamações são gravados em `PRIVADO_DIR` (por omissão `privado/`, volume `privado` no Docker) e nunca em `/uploads`. O admin vê-os em `GET /admin/verificacoes/{id}/documento`, `/selfie` e `GET /admin/reclamacoes/{id}/foto`.
- **QR Code**: a API devolve um `token` opaco (`kx_qr_…`, válido 10 minutos) e o código de 6 dígitos. A app desenha o token (ex.: pacote `qr_flutter`) e o profissional lê-o (ex.: `mobile_scanner`) ou escreve o código. Cinco códigos errados bloqueiam até o cliente abrir de novo o QR.
- **Datas e tipos**: as datas saem em ISO 8601 UTC (o pool liga com `time_zone = '+00:00'`), os booleanos como `true/false` e os valores em Kz como inteiros nas formas do contrato.

## Endpoints

Base: `/api`. "Token" indica se o endpoint precisa de `Authorization: Bearer <token>`.

#### Autenticação e conta

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| POST | `/auth/sms/pedir` | Enviar código de entrada por SMS (RF01, ecrã 01) | — |
| POST | `/auth/sms/verificar` | Entrar ou criar conta com o código do SMS (ecrã 11) | — |
| POST | `/auth/codigo/pedir` | Enviar código de entrada por email (RF01) | — |
| POST | `/auth/codigo/verificar` | Entrar ou criar conta com o código do email (RF01) | — |
| POST | `/auth/sair` | Terminar a sessão neste dispositivo | sim |
| GET | `/eu` | Dados da minha conta (EuJSON) | sim |
| PUT | `/eu/perfil-ativo` | Mudar para cliente ou para profissional (ecrã 20) | sim |
| PATCH | `/eu` | Atualizar nome, telemóvel, email ou token de push | sim |
| DELETE | `/eu` | Desativar a minha conta (RGPD) | sim |
| PUT | `/eu/foto` | Mudar a foto de perfil | sim |

#### Catálogo e ajuda

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| GET | `/categorias` | As 13 categorias, com chave, plural e destaque (RF02) | — |
| GET | `/etiquetas` | Etiquetas rápidas para avaliar (RF12) | — |
| GET | `/ajuda/perguntas` | Perguntas frequentes (RF16) | — |

#### Profissionais

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| GET | `/profissionais` | Pesquisar profissionais (RF02) | — |
| GET | `/profissionais/perto` | Profissionais perto de si, por distância (ecrã 02) | sim |
| GET | `/profissionais/mapa` | Pinos do mapa estático (ecrã 22) | sim |
| GET | `/profissionais/eu/painel` | Início do profissional com os pedidos perto (ecrã 14) | sim |
| GET | `/profissionais/{id}` | Perfil do profissional com trabalhos e avaliações (RF06, ecrã 03) | — |
| GET | `/profissionais/{id}/avaliacoes` | Todas as avaliações de um profissional | — |
| PUT | `/profissionais/eu` | Registo profissional (cria ou atualiza) e "Disponível para trabalhar" (ecrãs 12 e 14) | sim |
| PUT | `/profissionais/eu/disponibilidade` | Definir o horário semanal (RF15) | sim |
| GET | `/profissionais/eu/verificacao` | Estado da minha verificação (ecrã 13) | sim |
| PUT | `/profissionais/eu/verificacao/documento` | Juntar o documento de identidade | sim |
| PUT | `/profissionais/eu/verificacao/rosto` | Juntar a fotografia do rosto | sim |
| POST | `/profissionais/eu/verificacao/enviar` | Enviar para verificação | sim |
| POST | `/profissionais/eu/verificacao` | Pedir o selo de uma só vez: documento + fotografia (RF07) | sim |
| POST | `/profissionais/eu/trabalhos` | Adicionar fotos à galeria "Trabalhos feitos" (RF06) | sim |
| DELETE | `/profissionais/eu/trabalhos/{id}` | Remover foto da galeria | sim |

#### Moradas e favoritos

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| GET | `/moradas` | As minhas moradas | sim |
| POST | `/moradas` | Guardar morada (GPS + ponto de referência) | sim |
| PUT | `/moradas/{id}` | Editar morada | sim |
| DELETE | `/moradas/{id}` | Apagar morada (não usada em pedidos) | sim |
| GET | `/favoritos` | Profissionais favoritos | sim |
| PUT | `/favoritos/{profissionalId}` | Adicionar aos favoritos | sim |
| DELETE | `/favoritos/{profissionalId}` | Remover dos favoritos | sim |

#### Pedidos

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| POST | `/pedidos` | Criar pedido de serviço (RF03) | sim |
| GET | `/pedidos` | Os meus pedidos: em curso, concluídos, cancelados (RF13) | sim |
| GET | `/pedidos/em-curso` | Cliente: serviço à espera de confirmação, ou null (ecrãs 05 e 09) | sim |
| GET | `/pedidos/em-curso/lista` | Cliente: todos os serviços aceites, a caminho ou em curso | sim |
| GET | `/pedidos/por-confirmar` | Profissional: trabalho à espera do código do cliente (ecrã 16) | sim |
| GET | `/pedidos/por-confirmar/lista` | Profissional: todos os trabalhos à espera do código | sim |
| GET | `/pedidos/proximos` | Profissional: pedidos abertos perto de si (RF15) | sim |
| GET | `/pedidos/{id}` | Detalhe do pedido: estado, propostas, acordo, chat, comprovativo (RF08) | sim |
| PATCH | `/pedidos/{id}` | Editar pedido no formato da app (antes de aceitar uma proposta) (RF05) | sim |
| POST | `/pedidos/{id}/publicar` | Publicar um rascunho | sim |
| POST | `/pedidos/{id}/fotos` | Juntar fotos ao pedido (opcional, máx. 5) (RM04) | sim |
| POST | `/pedidos/{id}/cancelar` | Cancelar pedido (RF05) | sim |
| POST | `/pedidos/{id}/desfazer-aceitacao` | Cliente: desfazer a aceitação nos primeiros minutos (ecrã 08) | sim |
| PATCH | `/pedidos/{id}/estado` | Profissional: "A caminho" e "Em curso" (RF08) | sim |
| POST | `/pedidos/{id}/pedir-de-novo` | "Pedir de novo": cria um rascunho igual a um pedido anterior (RF13) | sim |

#### Propostas

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| POST | `/pedidos/{id}/propostas` | Profissional: enviar proposta com preço fechado (RF15) | sim |
| GET | `/pedidos/{id}/propostas` | Cliente: comparar propostas (RF04) | sim |
| PATCH | `/propostas/{id}` | Profissional: corrigir a proposta antes de ser aceite | sim |
| POST | `/propostas/{id}/retirar` | Profissional: retirar proposta | sim |
| POST | `/propostas/{id}/recusar` | Cliente: recusar proposta (RF05) | sim |
| POST | `/propostas/{id}/aceitar` | Cliente: aceitar proposta e fechar o acordo (RF05) | sim |
| POST | `/pedidos/{id}/alteracoes-preco` | Profissional: pedir alteração do preço combinado | sim |
| POST | `/alteracoes-preco/{id}/responder` | Cliente: aprovar ou recusar a alteração de preço | sim |

#### Confirmação por QR e comprovativo

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| GET | `/pedidos/{id}/qr` | Cliente: QR Code e código numérico do serviço em curso | sim |
| POST | `/pedidos/confirmar` | Profissional: confirmar só com o código ou o QR; a API encontra o pedido (RF10, ecrã 16) | sim |
| POST | `/pedidos/{id}/confirmar` | Profissional: confirmar o serviço lendo o QR ou com o código numérico (RF10) | sim |
| GET | `/pedidos/{id}/comprovativo` | Comprovativo digital: valor, data e profissional (RF10, RF17) | sim |

#### Garantia e avaliação

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| POST | `/pedidos/{id}/reclamacoes` | Reportar problema (antes de confirmar ou até 7 dias depois) (RF11) | sim |
| GET | `/reclamacoes` | As minhas reclamações | sim |
| POST | `/pedidos/{id}/avaliacao` | Avaliar com estrelas, etiquetas e comentário (RF12) | sim |

#### Conversas e notificações

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| GET | `/conversas` | Lista de conversas com a última mensagem (RF09, ecrã 18) | sim |
| GET | `/conversas/{id}` | Conversa com as últimas 50 mensagens, sem marcar como lida (ecrã 19) | sim |
| POST | `/conversas/{id}/lida` | Marcar a conversa como lida | sim |
| POST | `/pedidos/{id}/conversas` | Cliente: abrir conversa com um profissional que enviou proposta | sim |
| GET | `/conversas/{id}/mensagens` | Mensagens da conversa (marca como lidas) | sim |
| POST | `/conversas/{id}/mensagens` | Enviar mensagem com texto e/ou foto (RF09) | sim |
| GET | `/notificacoes` | As minhas notificações | sim |
| POST | `/notificacoes/{id}/lida` | Marcar notificação como lida | sim |
| POST | `/notificacoes/lidas` | Marcar todas como lidas | sim |

#### Administração

| Método | Caminho | O que faz | Token |
| --- | --- | --- | --- |
| GET | `/admin/verificacoes` | Pedidos de verificação de identidade | sim |
| GET | `/admin/verificacoes/{id}/documento` e `/selfie` | Ver o documento ou a fotografia do rosto (imagem) | sim |
| POST | `/admin/verificacoes/{id}/decidir` | Aprovar ou rejeitar verificação (atribui o selo Verificado) | sim |
| GET | `/admin/reclamacoes` | Reclamações para acompanhar (RF11) | sim |
| GET | `/admin/reclamacoes/{id}/foto` | Ver a foto junta a uma reclamação (imagem) | sim |
| PATCH | `/admin/reclamacoes/{id}` | Atualizar o estado de uma reclamação | sim |

