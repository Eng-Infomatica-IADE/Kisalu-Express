# Contrato de integração: app Flutter ↔ kisalu-api

Este documento define como a app (`kissalu-app/app`) fala com esta API. Cada método do `KisaluRepository` corresponde a um endpoint, e cada modelo Dart corresponde a uma forma JSON. Quem mudar um dos lados tem de atualizar este documento.

## 0. Convenções

### Respostas e identificadores

- Base: `http://<host>:3000/api`. A resposta vem sempre como `{title,status,detail,instance,data}`; a app lê só `data`.
- Nos erros, `detail` traz a mensagem em português e `data` traz `{codigo, detalhes?}`. Nos erros de validação (400 `DADOS_INVALIDOS`), `detail` é a mensagem do primeiro problema, com o texto do catálogo da app (`kissalu-app/docs/frontend/VALIDACOES.md`), e `data.detalhes` traz a lista completa `[{campo, mensagem}]`.
- Os ids no servidor são `int`. No Dart são `String` (`json['id'].toString()`).
- Num `GET` por id, se o id não for só dígitos, o repositório REST devolve `null` sem chamar a API.
- Categorias: a app usa chaves de texto (`canalizador`, `ar_cond`…). Todas as respostas trazem `categoria_chave`, e os endpoints aceitam `categoria_chave` ou `categorias` (lista de chaves).

### Tipos de dados

- Booleanos: o mysql2 devolve `0/1`, por isso os serializadores emitem `true/false` (`!!v`). No `fromJson`, por defesa: `v == true || v == 1`.
- Valores em Kz: inteiros (`Math.round`). No Dart, `(json as num).round()`.
- Datas: ISO 8601 em UTC. No Dart, `DateTime.parse(s).toLocal()`.
- Fuso: o pool MySQL usa `timezone: 'Z'` e cada ligação faz `SET time_zone = '+00:00'`.

### Erros HTTP → exceções Dart (no `RestKisaluRepository`)

| Situação | Exceção |
|---|---|
| Sem ligação ou timeout | `SemRedeException` |
| 401 | `SessaoExpiradaException`: limpa o token e volta ao `/login` |
| 403 | `SemPermissaoException` |
| 404 | `null` nos métodos `T?`; nos outros, `NaoEncontradoException` |
| 400, 409, 422 ou 429 | `ValidacaoException(detail)` |
| 5xx | `ServidorException` |

### Estado do pedido

| Servidor | Dart |
|---|---|
| `rascunho`, `publicado`, `com_propostas` | `novo` |
| `aceite`, `a_caminho`, `em_curso` | `emCurso` |
| `concluido` | `concluido` |
| `cancelado` | `cancelado` |

Para o profissional, o nome do cliente aparece sempre abreviado: `nomeCurto("Maria Kiala") = "Maria K."`. Este formato é usado em `cliente_curto` e no `autor` das avaliações.

## 1. Formas JSON

**ProfissionalResumo**

```json
{ "id": 2, "nome": "Joaquim Manuel", "foto_url": null, "categoria": "Canalizador", "categoria_chave": "canalizador",
  "zona": "Talatona, Luanda", "distancia_km": 1.2, "rating": 4.8, "num_avaliacoes": 126, "servicos_confirmados": 126,
  "anos_experiencia": 6, "verificado": true, "mao_de_obra_desde": 8000 }
```

- `categoria` é a categoria principal: a que tem menor `categoria.ordem`.
- `distancia_km`, `anos_experiencia` e `mao_de_obra_desde` podem vir `null`; o Dart usa `0` nesses casos.

**ProfissionalDetalhe** é o `ProfissionalResumo` com mais estes campos, e mantém os que já existiam:

```json
{ "especialidades": ["Fugas de água"], "trabalhos_feitos": [{ "id": 1, "legenda": "Antes/depois", "url": "/uploads/trabalhos/x.jpg" }],
  "total_trabalhos_feitos": 41, "avaliacoes": [{ "autor": "Maria K.", "estrelas": 5, "comentario": "…", "etiquetas": ["pontual","preco_justo"] }] }
```

**PropostaJSON**

```json
{ "id": 1, "proposta_id": 1, "estado": "enviada", "valor_total": 12500,
  "componentes": { "mao_de_obra": 8000, "material": 3500, "deslocacao": 1000 },
  "material_detalhe": "sifão e vedante", "tempo_chegada_min": 40, "na_hora_pedida": false,
  "chegada_prevista": "ISO", "estimativa_chegada": EstimativaChegada|null, "profissional": ProfissionalResumo }
```

`estimativa_chegada` só vem preenchida para o cliente do pedido (`GET /pedidos/:id`, `GET /pedidos/:id/propostas`) e quando há distância e minutos prometidos; nos outros casos é `null`. Ver secção 6, "Matemática".

**EstimativaChegada** (Monte Carlo, docs/MATEMATICA.md)

```json
{ "simulacoes": 10000, "media_min": 19, "p50_min": 16.6, "p90_min": 32.8, "prob_cumprir": 0.98 }
```

**EstatisticasAvaliacoes** (`GET /profissionais/:id/estatisticas`)

```json
{ "n": 126, "media": 4.79, "mediana": 5, "moda": 5, "desvio_padrao": 0.6, "variancia": 0.357,
  "ic95": { "inferior": 4.69, "superior": 4.9, "metodo": "z" }|null,
  "distribuicao": { "1": 1, "2": 1, "3": 3, "4": 13, "5": 108 }, "media_bayesiana": 4.79 }
```

`chegada_prevista` calcula-se assim:

- se `na_hora_pedida`: `pedido.data_pretendida`;
- se a proposta já foi aceite: `respondida_em + tempo_chegada_min`;
- nos outros casos: `NOW() + tempo_chegada_min`.

**PedidoJSON**

```json
{ "id": 1, "titulo": "…", "descricao": "…", "categoria_chave": "canalizador", "estado": "com_propostas",
  "criado_em": "ISO", "data_pretendida": "ISO|null", "zona": "Talatona", "num_fotos": 1,
  "profissional": ProfissionalResumo|null, "valor_acordado": 12500|null, "proposta_aceite_id": 1|null,
  "cliente_curto": "Maria K."|null, "avaliado": false, "pode_reclamar": true, "propostas": [PropostaJSON] }
```

- `zona = morada.bairro ?? morada.municipio`.
- `cliente_curto` só vem quando quem pede é profissional.
- Na lista de pedidos, `propostas` vem como `[]`.
- `avaliado`: o cliente já avaliou o serviço.
- `pode_reclamar`: há proposta aceite e o pedido está `aceite`, `a_caminho` ou `em_curso`, ou foi concluído há menos de 7 dias (RF11; a base de dados repete a regra no trigger `trg_reclamacao_garantia`).

**PedidoPertoJSON**

```json
{ "id": 7, "titulo": "Reparar muro do quintal", "descricao": "…", "categoria_chave": "pedreiro", "zona": "Viana",
  "distancia_km": 1.8, "data_pretendida": "ISO|null", "publicado_em": "ISO", "novo": true }
```

`novo` é verdadeiro quando o profissional ainda não enviou proposta e o pedido foi publicado há menos de uma hora.

**ComprovativoJSON**

```json
{ "numero_comprovativo": "KX-2026-000001", "pedido_id": 1, "titulo": "…", "cliente": "Maria Kiala", "cliente_curto": "Maria K.",
  "profissional": ProfissionalResumo, "valor_kz": 12500, "metodo_pagamento": "dinheiro", "metodo_confirmacao": "codigo",
  "confirmado_em": "ISO", "valor_formatado": "12 500 Kz", "partilha_whatsapp": "…" }
```

**MensagemJSON**

```json
{ "id": 3, "texto": "…", "foto_url": null, "minha": false, "enviada_em": "ISO", "lida": false }
```

`lida = minha && lida_em IS NOT NULL`.

**ConversaJSON**

```json
{ "id": 1, "pedido_id": 1, "pedido_titulo": "…", "categoria_chave": "canalizador", "valor": 12500, "nao_lidas": 2,
  "interlocutor": ProfissionalResumo | { "id": 1, "nome": "Maria K.", "foto_url": null, "e_cliente": true },
  "mensagens": [MensagemJSON] }
```

- `valor = COALESCE(valor_acordado, proposta.valor_total)` da proposta desse profissional.
- Na lista, `mensagens` traz só a última. No detalhe traz as últimas 50, por ordem ascendente.

**EuJSON**

```json
{ "id": 1, "nome": "Maria Kiala"|null, "telemovel": "+244923000000", "email": null, "foto_url": null,
  "tipo_perfil": "cliente", "perfil_ativo": "cliente", "zona": "Talatona, Luanda"|null, "tem_novidades": true,
  "moradas_guardadas": 2, "favoritos": 3,
  "profissional": null | { "categorias": ["canalizador"], "anos_experiencia": 10, "zona": "Talatona, Luanda",
     "raio_atuacao_km": 10, "disponivel": true, "verificado": true, "media_avaliacao": 4.8, "total_avaliacoes": 126,
     "total_servicos": 126, "registo_completo": true } }
```

- `zona`: no perfil profissional vem de `profissional.zona`; no cliente vem da morada predefinida, como `"${bairro ?? municipio}, ${provincia}"`.
- `tem_novidades`: há notificações por ler.
- `registo_completo`: o profissional tem pelo menos uma categoria e uma zona.

## 2. Métodos do repositório e endpoints

Os caminhos são relativos a `/api`. Os endpoints com rota literal (`/profissionais/perto`, `/profissionais/mapa`, `/profissionais/eu/painel`, `/pedidos/em-curso`, `/pedidos/em-curso/lista`, `/pedidos/por-confirmar`, `/pedidos/por-confirmar/lista`) têm de ser registados **antes** de `/:id`.

| Método | Endpoint | Auth |
|---|---|---|
| `mudarPerfil` | `PUT /eu/perfil-ativo` `{perfil}` → `{perfil_ativo, utilizador: EuJSON}` | sim |
| `utilizador` | `GET /eu` → EuJSON | sim |
| `pedirCodigoSms` | `POST /auth/sms/pedir` | não |
| `validarCodigoSms` | `POST /auth/sms/verificar` | não |
| `terminarSessao` | `POST /auth/sair` | sim |
| `categorias` | `GET /categorias` → `[{id, chave, nome, plural, em_destaque, icone, profissionais_disponiveis}]` (13) | não |
| `profissionaisPertoDeSi` | `GET /profissionais/perto?limit=20` → `[ProfissionalResumo]` | sim |
| `profissional(id)` | `GET /profissionais/:id` → ProfissionalDetalhe | não |
| `estatisticasAvaliacoes(id)` | `GET /profissionais/:id/estatisticas` → EstatisticasAvaliacoes (404 → `null`) | não |
| `pedido(id)` | `GET /pedidos/:id` → PedidoJSON | sim |
| `cancelarPedido` | `POST /pedidos/:id/cancelar` | sim |
| `aceitarProposta` | `POST /propostas/:id/aceitar`, depois `GET /pedidos/:pedidoId` | sim |
| `desfazerAceitacao` | `POST /pedidos/:id/desfazer-aceitacao` → PedidoJSON | sim (cliente) |
| `servicoEmCurso` | `GET /pedidos/em-curso` → PedidoJSON ou `null` | sim (cliente) |
| `codigoConfirmacao` | `GET /pedidos/:id/qr` → `{pedido_id, token, codigo, valido_ate, valor_acordado, profissional, categoria, categoria_chave}` | sim |
| `reportarProblema` | `POST /pedidos/:id/reclamacoes` `{tipo:"outro", descricao}` | sim |
| `comprovativo` | `GET /pedidos/:id/comprovativo` → ComprovativoJSON | sim |
| `enviarAvaliacao` | `POST /pedidos/:id/avaliacao` `{estrelas, etiquetas:[chaves], comentario}` | sim |
| `historico` | `GET /pedidos?limit=100` → `[PedidoJSON]` | sim |
| `verificarLigacao` | `GET /saude` | não |
| `publicarPedido` | `POST /pedidos` `{categoria_chave, titulo, descricao, zona, ponto_referencia, quando, publicar:true}` → `{id, estado, pedido: PedidoJSON, profissionais_avisados, categoria_plural}` | sim |
| `guardarRegistoProfissional` | `PUT /profissionais/eu` `{nome_completo, categorias, anos_experiencia, zona, raio_atuacao_km}` → `{perfil_ativo, utilizador}` | sim |
| `definirDisponibilidade` | `PUT /profissionais/eu` `{disponivel}` | sim |
| `verificacaoIdentidade` | `GET /profissionais/eu/verificacao` → `{estado, documento_enviado, rosto_enviado, motivo_rejeicao}` | sim |
| `adicionarDocumento` | `PUT /profissionais/eu/verificacao/documento` (JSON `{}` ou multipart com `documento`) | sim |
| `adicionarFotoRosto` | `PUT /profissionais/eu/verificacao/rosto` (JSON `{}` ou multipart com `rosto`) | sim |
| `enviarParaVerificacao` | `POST /profissionais/eu/verificacao/enviar` | sim |
| `painelProfissional` | `GET /profissionais/eu/painel` → `{nome, zona, raio_km, pedidos_novos, rating, servicos, disponivel, pedidos:[PedidoPertoJSON]}` | sim (profissional) |
| `pedidoPerto(id)` | `GET /pedidos/:id`, com `zona`, `distancia_km` e `categoria_chave` | sim |
| `enviarProposta` | `POST /pedidos/:id/propostas` `{valor_mao_obra, valor_material, valor_deslocacao, tempo_chegada_min \| na_hora_pedida}` → PropostaJSON | sim |
| `trabalhoPorConfirmar` | `GET /pedidos/por-confirmar` → `{pedido_id, servico, cliente, valor}` ou `null` (o mais recente) | sim (profissional) |
| `trabalhosPorConfirmar` | `GET /pedidos/por-confirmar/lista` → `[{pedido_id, servico, cliente, valor}]` | sim (profissional) |
| `confirmarServicoComCodigo` | `POST /pedidos/confirmar` `{codigo, metodo_pagamento: 'dinheiro'}` → ComprovativoJSON; a API encontra o pedido pelo código (secção 6) | sim (profissional) |
| `servicoConfirmado(id)` | `GET /pedidos/:id/comprovativo` | sim |
| `conversas` | `GET /conversas` → `[ConversaJSON]` | sim |
| `conversa(id)` | `GET /conversas/:id` → ConversaJSON (não marca como lida) | sim |
| `enviarMensagem` | `POST /conversas/:id/mensagens` `{texto}` (até 1000) → MensagemJSON | sim |
| `marcarConversaLida` | `POST /conversas/:id/lida` | sim |
| `pinsMapa` | `GET /profissionais/mapa?raio_km=5` → `[{x, y, profissional}]` | sim |

Alguns métodos não chamam a API:

- Ficam só na app: `alteracoes`, `agora`, `perfilAtivo` (cache), `codigoSmsPendente` (memória), `telemovelPredefinido`, `rascunhoAvaliacao`, `rascunhoProposta`, `codigoClientePredefinido` e `rascunhoPedido`.
- `codigoSmsPredefinido` devolve o `codigo_dev`, só em `kDebugMode`.
- `rascunhoRegistoProfissional` é derivado de `GET /eu`.

## 3. Autenticação por telemóvel

### `POST /auth/sms/pedir`

**Corpo:** `{telemovel, perfil, criar_conta}`.

**Resposta (`data`):** `{mensagem, expira_em_min: 5, reenviar_em_s: 60, codigo_dev?}`.

- A resposta é igual para números novos e existentes.
- O SMS é simulado em `services/sms.ts`: o texto aparece no terminal.

**Erros 429:**

- se o último pedido foi há menos de 60 s: `"Pode pedir um novo código daqui a N segundos."`;
- se já passou o limite em 10 minutos (`CODIGO_MAX_POR_10MIN`).

### `POST /auth/sms/verificar`

**Corpo:** `{telemovel, codigo, perfil, aceita_privacidade}`.

**Resposta (`data`):** `{token, novo, perfil_ativo, precisa_registo, utilizador: EuJSON}`.

**Comportamento:**

- Se ainda não existe conta para o telemóvel, cria-a.
- Com `perfil = profissional`, cria a linha `profissional` incompleta.
- A sessão guarda `perfil_ativo`.

**Erros:**

- 400 `CODIGO_ERRADO`: "O código não está certo. Confirme o SMS e tente outra vez."
- 400 `CODIGO_EXPIRADO`;
- 429 depois de 5 tentativas;
- 400 `PRIVACIDADE_EM_FALTA` numa conta nova sem `aceita_privacidade: true`;
- 403 se a conta estiver desativada.

### Perfil ativo e destino depois do ecrã 11

O perfil ativo vive em `sessao.perfil_ativo`. O middleware usa-o como `req.user.tipo_perfil` (o admin fica sempre admin). A entrada por email mantém-se.

`validarCodigoSms` devolve `Future<bool>` = "precisa de registo profissional". É verdadeiro quando o perfil é `profissional` e se verifica uma destas condições: a conta é nova, `criarConta` é verdadeiro, ou o registo não está completo.

### Token

- O token fica só em memória (`lib/services/api_client.dart`) e vai no cabeçalho `Authorization: Bearer`.
- O endereço da API é definido com `--dart-define=KISALU_API=http://10.0.2.2:3000/api` (emulador Android).
- Sem esse valor, a app usa o `MockKisaluRepository`.

## 4. Base de dados (separada como pede o professor)

O antigo `database/schema.sql` dá lugar a três ficheiros:

- `database/create.sql`: tabelas, triggers, vistas;
- `database/populate.sql`: dados de exemplo;
- `database/queries.sql`: consultas de exemplo, uma ou mais por funcionalidade (ecrãs). Seguem uma história (proposta, aceitação, confirmação e avaliação do pedido 10) e alteram dados, por isso não fazem parte do arranque normal.

Ordem: `create.sql` → `populate.sql` (→ `queries.sql`). O `docker-compose` monta os dois primeiros como `01-create.sql` e `02-populate.sql`; `npm run db:reset` faz o mesmo (com `-- --consultas` corre também o terceiro).

### Alterações ao esquema

| Tabela ou objeto | Alteração |
|---|---|
| `utilizador` | `email` e `nome` passam a `NULL` |
| `codigo_login` | `email` passa a `NULL`; nova coluna `telemovel`, índice `(telemovel, criado_em)`, `CHECK` de email ou telemóvel |
| `sessao` | nova coluna `perfil_ativo` |
| `categoria` | novas colunas `chave UNIQUE`, `plural`, `em_destaque`; passa a ter 13 linhas (ids 1 a 8 mantêm-se) |
| `profissional` | novas colunas `zona`, `mao_obra_desde`, `especialidades JSON` |
| `verificacao_identidade` | as colunas de ficheiro e documento passam a `NULL`; `estado` aceita `'rascunho'` |
| `proposta` | novas colunas `na_hora_pedida`, `material_detalhe` |
| `confirmacao_servico` | novas colunas `tentativas`, `expira_em` e `qr_aberto_em` (última vez que o cliente abriu o QR; desempata códigos iguais em `POST /pedidos/confirmar`) |
| `etiqueta` | nova coluna `chave`; as etiquetas passam a ser as da app: pontual, preco_justo, simpatico, trabalho_limpo, rapido |
| `vw_comprovativo` | passa a mostrar `profissional_id` e `cliente_id` |
| `profissional` | novas colunas `avaliacoes_1` … `avaliacoes_5`: distribuição das avaliações por estrelas (inclui o histórico dos dados de exemplo) |
| `trg_avaliacao_media` | soma 1 à coluna `avaliacoes_<estrelas>` e recalcula `total_avaliacoes` e `media_avaliacao` a partir da distribuição, para não apagar o histórico de exemplo |
| `vw_media_categoria` | vista nova: média global das avaliações por categoria (prior da média bayesiana) |

### Dados de exemplo, alinhados com o mock da app

| Pessoa | Telemóvel | Notas |
|---|---|---|
| Maria Kiala, cliente | +244923000000 | Talatona; 2 moradas e 3 favoritos |
| Joaquim Manuel, profissional | +244923000002 | canalizador e pedreiro, verificado; 4.8 de média, 126 avaliações e 126 serviços, Talatona; a 1,2 km da casa da Maria (o primeiro em "Perto de si", como no Figma) |
| Rui Santos, Paulo Neto, Ana Cardoso, Carlos Dias, Nuno Ferreira, Hélder Tavares | +244923000003, +2449230000(05 a 09) | os outros profissionais do mock, com as mesmas médias e zonas |
| Maria Sebastião, Pedro Kiluange, Ana Paulo, Rui Bento, Teresa Mbala | +2449230000(10 a 14) | clientes do histórico do Joaquim e do pedido do muro |
| Administrador | +244923000099 | admin |

- O pedido 1, "Fuga de água na cozinha", fica `com_propostas` e tem 3 propostas. A do Joaquim vale 12 500 Kz (8 000 + 3 500 + 1 000).
- O histórico da Maria tem os pedidos 2 a 5 do mock (Tomada sem luz, Limpeza de AC, Pastilhas de travão cancelado, Tranças); as conversas 1 a 3 têm as mensagens do mock (2 por ler na do Joaquim).
- O pedido 10, "Reparar muro do quintal" (pedreiro, Viana), aparece como novo no painel do Joaquim, a 1,8 km dele.
- Os quatro profissionais do mapa (Joaquim, Ana, Rui, Paulo) estão à volta da casa da Maria. O Joaquim ficou a 1,2 km, a noroeste, por isso o pino dele está mais perto do centro do que no mapa estático do Figma, que o punha a cerca de 2 km. Nas propostas do pedido 1 o Joaquim também aparece a 1,2 km.
- Em desenvolvimento, `CODIGO_QR_FIXO_DEV=482173` (no `.env`; os testes usam códigos aleatórios).

## 5. Decisões da implementação

O que o contrato deixava em aberto e ficou assim no servidor:

- **Telemóvel:** só números angolanos: `+244` e 9 dígitos começados por 9. Aceita espaços, hífenes e o indicativo como `+244`, `00244` ou `244`, e guarda sempre `+244923000000`. Vale em `/auth/sms/*`, `/auth/codigo/verificar` e `PATCH /eu`. As mensagens de erro são as do catálogo (ex.: "Faltam 4 números. Um número angolano tem 9 dígitos.", "O número começa por 9. Exemplo: 923 456 789."); um número estrangeiro dá "Use um número angolano (+244). Exemplo: 923 456 789.". Para mostrar: `+244 923 000 000`.
- **`tipo_perfil` e `perfil_ativo`:** `tipo_perfil` é o da conta (passa a `profissional` quando o registo do ecrã 12 é guardado); `perfil_ativo` é o da sessão. Entrar por email começa no `tipo_perfil`. O objeto `profissional` do EuJSON vem sempre que a pessoa tem perfil profissional, mesmo em modo cliente. `PUT /eu/perfil-ativo` para `profissional` cria o perfil por completar; para o admin devolve 403.
- **`PUT /profissionais/eu`:** aceita qualquer sessão (é um upsert) e põe a sessão em `profissional`. `categorias` aceita chaves ou ids (400 `CATEGORIA_INVALIDA` se não existir). Campos extra opcionais: `bio`, `latitude`, `longitude`, `mao_obra_desde`, `especialidades`.
- **Verificação:** `estado` é `nao_pedida`, `rascunho`, `pendente`, `aprovada` ou `rejeitada`. Sem ficheiro (corpo `{}`), fora de produção fica registada uma captura simulada; em produção é obrigatório o ficheiro. `enviar` sem os dois → 400 `VERIFICACAO_INCOMPLETA`; depois de enviado, mexer nos documentos → 409.
- **Painel:** traz também `verificado`. Os pedidos sem GPS (ou de profissionais sem GPS) aparecem com `distancia_km: null`.
- **`POST /pedidos` no formato da app:** sem `morada_id`, a morada sai da `zona` + `ponto_referencia`: reaproveita uma morada guardada com a mesma zona e referência; senão guarda uma nova (rótulo "Pedido"). `quando: null` = o mais cedo possível. O formato antigo (`categoria_id`, `morada_id`, `urgencia`, `data_pretendida`) continua a funcionar.
- **PedidoJSON** traz ainda `publicado_em`, `concluido_em`, `total_propostas` e `avaliado`; a PropostaJSON traz `pedido_id` e `inclui_descricao`. O `GET /pedidos/:id` junta ao PedidoJSON o detalhe antigo (`morada`, `acordo`, `historico`, `garantia`, `conversa_id`…) e, para um profissional, `distancia_km` e `novo`.
- **Propostas:** mínimo 500 Kz (400 `VALOR_MINIMO`). `na_hora_pedida` só em pedidos com hora marcada (400 `SEM_HORA_PEDIDA`); nesse caso `tempo_chegada_min` vem `null`.
- **Desfazer aceitação:** só com o pedido em `aceite` e nos primeiros 5 minutos (`DESFAZER_ACEITACAO_MIN`); fora disso 409 `DESFAZER_IMPOSSIVEL`. A proposta aceite e as que foram recusadas automaticamente voltam a `enviada`; o QR é anulado.
- **QR e confirmação:** o `token` (ex.: `kx_qr_…`) vale 10 minutos (`QR_VALIDADE_MIN`) e renova-se quando o cliente abre de novo o ecrã 05. A app do profissional usa `POST /pedidos/confirmar` (secção 6), que encontra o pedido pelo código; `POST /pedidos/:id/confirmar` (`{codigo}` ou `{token}`) mantém-se. `metodo_pagamento` é opcional (`dinheiro` por omissão). O código aceita `482 173` ou `482173`. Cada código errado conta: 400 `CODIGO_ERRADO` com as tentativas que restam; à sexta, 429. Abrir de novo o QR depois do bloqueio gera um código novo. QR expirado → 400 `QR_EXPIRADO`.
- **Imagens privadas:** os documentos de identidade, as fotografias do rosto e as fotos das reclamações ficam fora de `/uploads` (pasta `PRIVADO_DIR`) e só o admin as vê: `GET /admin/verificacoes/:id/documento`, `GET /admin/verificacoes/:id/selfie` e `GET /admin/reclamacoes/:id/foto` (imagem JPEG). Nas listas de admin, `documento_url`, `selfie_url` e `foto_url` já trazem esses caminhos (ou `null` numa captura simulada). Em `GET /reclamacoes`, o autor vê `tem_foto: true|false` em vez de `foto_url`.
- **Avaliação:** chaves desconhecidas → 400 `ETIQUETA_INVALIDA`. A resposta traz `etiquetas` (chaves), `nova_media_profissional` e `total_avaliacoes`.
- **Conversas:** a lista segue o perfil ativo (cliente: conversas dos seus pedidos; profissional: as dele). Trazem também `estado_pedido` e `ultima_em`. `POST /conversas/:id/lida` devolve `{id, nao_lidas: 0}`. Mensagem com mais de 1000 caracteres → 400.
- **ProfissionalDetalhe:** `total_trabalhos_feitos` é a contagem real da galeria (3 no Joaquim; o mock diz 41). Mantém `avaliacoes_recentes` (igual a `avaliacoes`) por compatibilidade.
- **Mapa:** quadrado centrado na morada predefinida (ou em Talatona, se não houver GPS) com `raio_km` para cada lado; `x` e `y` entre 0 e 1, com (0,0) no canto superior esquerdo. Os profissionais fora do quadrado não vêm.
- **Joaquim:** a zona é "Talatona, Luanda", como no ProfissionalResumo; o mock do painel diz "Viana".

## 6. Endpoints usados na Entrega 2b

Forma exata do campo `data` de cada resposta. Todos precisam de token, exceto a ajuda. Cobertos por `tests/entrega-2b.test.ts`.

### Confirmar o serviço sem indicar o pedido (ecrã 16)

`POST /pedidos/confirmar` (profissional)

```json
{ "codigo": "482173", "metodo_pagamento": "dinheiro" }
{ "token_qr": "kx_qr_…", "metodo_pagamento": "multicaixa_express" }
```

- `codigo` (6 dígitos, aceita `482 173`) ou `token_qr`: um dos dois é obrigatório. `metodo_pagamento`: `dinheiro` (por omissão), `multicaixa_express` ou `transferencia`.
- A API procura, entre os pedidos `aceite`, `a_caminho` ou `em_curso` com a proposta **deste** profissional aceite e a confirmação pendente, aquele cujo código (ou QR) corresponde, e confirma esse.
- **200** → ComprovativoJSON, igual ao de `POST /pedidos/:id/confirmar`. O `pedido_id` diz que pedido ficou confirmado.
- **400 `DADOS_INVALIDOS`**: "Escreva o código que o cliente lhe disse.", "Faltam N números. O código tem 6 dígitos.", "Use só números. Exemplo: 482 173." ou "O código tem 6 dígitos. Confirme com o cliente.".
- **400 `CODIGO_ERRADO`**: "Este código não corresponde ao serviço. Confirme com o cliente. Restam N tentativas." A tentativa conta em todos os serviços pendentes do profissional, para não se poder adivinhar o código de um serviço a tentar nos outros.
- **400 `QR_EXPIRADO`**, **409 `ALTERACAO_PENDENTE`** e **429** (5 erros; o cliente tem de abrir de novo o QR): como no endpoint por id.
- **404 `SEM_SERVICO_POR_CONFIRMAR`**: o profissional não tem nenhum serviço à espera de código.
- **Códigos iguais (só em desenvolvimento):** com `CODIGO_QR_FIXO_DEV=482173`, todos os serviços têm o mesmo código. Confirma-se então o serviço cujo QR o cliente abriu (ou renovou) mais recentemente no ecrã 05 (coluna `confirmacao_servico.qr_aberto_em`; se o QR nunca foi aberto, conta a hora da aceitação). Em produção os códigos são aleatórios.

`GET /pedidos/por-confirmar/lista` (profissional) → todos os trabalhos à espera do código, o mais recente primeiro (`[]` se não houver):

```json
[{ "pedido_id": 31, "servico": "Torneira da cozinha", "cliente": "Helena C.", "valor": 7000 }]
```

`GET /pedidos/por-confirmar` mantém-se: devolve o primeiro desta lista, ou `null`. Do lado do cliente, `GET /pedidos/em-curso/lista` → `[PedidoJSON]` com todos os serviços aceites, a caminho ou em curso (`GET /pedidos/em-curso` continua a devolver só o mais recente).

### Pedido do cliente

`PATCH /pedidos/:id` (cliente) edita um pedido sem proposta aceite. Aceita o mesmo formato da app que `POST /pedidos` e só muda os campos enviados:

```json
{ "categoria_chave": "canalizador", "titulo": "…", "descricao": "…", "zona": "Talatona",
  "ponto_referencia": "Portão verde", "quando": "2026-11-10T09:00:00Z" }
```

- `quando: null` passa a "o mais cedo possível"; uma data passa a agendado. Também aceita `categoria_id`, `morada_id`, `urgencia` e `data_pretendida`.
- `zona` e `ponto_referencia` escolhem a morada como no `POST` (reaproveitam uma morada guardada igual ou criam uma nova). Só com `ponto_referencia`, mantém a zona atual.
- **200** → PedidoJSON (com `propostas`).
- **409 `PEDIDO_NAO_EDITAVEL`**: já há proposta aceite, ou o pedido está concluído ou cancelado.

`POST /pedidos/:id/pedir-de-novo` (cliente) → **201**:

```json
{ "id": 40, "estado": "rascunho", "mensagem": "Reveja o pedido e publique.", "pedido": PedidoJSON }
```

O rascunho copia a categoria, a morada, o título e a descrição, com "o mais cedo possível". Publica-se com `POST /pedidos/:id/publicar`; antes, pode editar-se com `PATCH /pedidos/:id`.

`POST /propostas/:id/recusar` (cliente) → **200** `{ "id": 7, "estado": "recusada" }`. **409** se a proposta já foi respondida ou não é de um pedido seu.

### Detalhe do pedido para o profissional escolhido (RNF10)

`GET /pedidos/:id` junta ao PedidoJSON o campo `contacto_cliente`. Vem preenchido só para o profissional da proposta aceite (e para o admin); para os outros é `null`:

```json
"contacto_cliente": { "nome": "Maria Kiala", "telemovel": "+244923000000", "morada": "Rua 21, Casa 14",
  "ponto_referencia": "Perto da cantina do Sr. Zé", "zona": "Talatona", "municipio": "Talatona", "provincia": "Luanda",
  "latitude": -8.92, "longitude": 13.185 }
```

Os campos antigos (`cliente.telemovel`, `morada.ponto_referencia`) mantêm-se. O PedidoJSON traz sempre `avaliado` e `pode_reclamar` (secção 1).

### Estados do serviço (profissional)

`PATCH /pedidos/:id/estado` `{ "estado": "a_caminho" | "em_curso" }` → **200** `{ "id": 31, "estado": "a_caminho" }`.

- Transições: `aceite → a_caminho`, `aceite → em_curso` e `a_caminho → em_curso`. Outra → **409**. `concluido` não é aceite (400): só se conclui pela confirmação.
- **403** "Este serviço não está associado à sua conta." se o pedido não é dele.
- O cliente recebe uma notificação (`estado_pedido`, ação `ver_pedido` ou `ver_qr`).

### Reportar problema (RF11)

`POST /pedidos/:id/reclamacoes` (cliente ou profissional escolhido), multipart com `tipo`, `descricao` (10 a 2000 caracteres) e `foto` opcional → **201**:

```json
{ "id": 3, "estado": "aberta", "mensagem": "Recebemos o seu problema. Respondemos em até 48 horas.",
  "contacto_profissional": { "nome": "Joaquim Manuel", "telemovel": "+244923000002" } }
```

- `tipo`: `trabalho_mal_feito`, `preco_diferente`, `nao_compareceu`, `atraso`, `comportamento` ou `outro`.
- `contacto_profissional` só vem quando quem reporta é o cliente.
- Mensagens: "Conte-nos o que aconteceu." e "Escreva um pouco mais para percebermos o problema.". Fora do prazo → **422** "A garantia de 7 dias já terminou.".
- A foto não fica pública: só o admin a vê.

### Notificações

`GET /notificacoes?limit=20&offset=0&so_nao_lidas=false`:

```json
{ "nao_lidas": 2, "notificacoes": [
  { "id": 9, "tipo": "nova_proposta", "titulo": "Recebeu 3 propostas", "corpo": "Compare preço, chegada e avaliações.",
    "pedido_id": 1, "acao": "ver_propostas", "lida": false, "criado_em": "ISO" } ] }
```

- `tipo`: `novo_pedido`, `nova_proposta`, `proposta_aceite`, `estado_pedido`, `alteracao_preco`, `nova_mensagem`, `lembrete_avaliacao`, `reclamacao` ou `sistema`. `acao` pode vir `null`.
- `POST /notificacoes/:id/lida` → `null` (marca uma).
- `POST /notificacoes/lidas` → `null` (marca todas).

### Ajuda

`GET /ajuda/perguntas?tema=&q=` (sem token):

```json
[{ "id": 1, "tema": "QR Code", "pergunta": "Quando devo mostrar o QR Code?", "resposta": "…" }]
```

## 6A. Matemática: estatística das avaliações e estimativa de chegada

Requisito de Matemática Discreta (método numérico + estatística). Fórmulas, parâmetros e exemplos em `kisalu-api/docs/MATEMATICA.md`.

### `GET /profissionais/:id/estatisticas` (sem token)

EstatisticasAvaliacoes (secção 1), calculada a partir da distribuição 1–5 estrelas do perfil: média, mediana, moda, desvio padrão e variância amostrais (divide por n − 1), intervalo de confiança a 95 % da média (`metodo: "t"` com t de Student e n − 1 graus de liberdade se n < 30; `"z"` com 1,96 se n ≥ 30; limites cortados a [1, 5]) e `media_bayesiana` = (10 · C + Σx) / (10 + n), com C a média da categoria principal. Sem avaliações, os valores vêm a `null` (`n: 0`); com uma só, `desvio_padrao`, `variancia` e `ic95` vêm a `null`. Profissional inexistente → 404.

A pesquisa `GET /profissionais?ordenar=avaliacao` ordena por verificado e depois pela média bayesiana (cada linha traz `media_bayesiana`).

### `GET /propostas/:id/estimativa-chegada` (token)

Só o cliente do pedido ou o profissional da proposta (ou o admin); os outros recebem 404.

```json
{ "proposta_id": 1, "distancia_km": 1.2, "tempo_prometido_min": 40,
  "simulacoes": 10000, "media_min": 19, "p50_min": 16.6, "p90_min": 32.8, "prob_cumprir": 0.98 }
```

10 000 simulações de tempo = preparação U(5, 15) + distância / velocidade (lognormal, mediana 18 km/h, σ = 0,5) + atraso U(5, 25) com probabilidade 0,3. `prob_cumprir` é a fração (0 a 1) que chega dentro de `tempo_prometido_min`. A semente vem do id da proposta: o resultado é sempre o mesmo e igual ao `estimativa_chegada` da PropostaJSON. Proposta "na hora pedida" → 400 `SEM_TEMPO_PROMETIDO`; sem GPS do profissional ou da morada → 400 `SEM_DISTANCIA`.

Na app: ecrã 03, bloco "Avaliações em números" (`estatisticasAvaliacoes`); ecrã 04, linha "Chega a tempo em ~N% dos casos" no cartão da proposta (N = `prob_cumprir` arredondado a 5 %), e a ordenação "Chegada" desempata por `p50_min`.
