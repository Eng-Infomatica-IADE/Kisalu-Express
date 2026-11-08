# Kisalu Express · Documentação da API REST

> Gerado automaticamente por `npm run docs:api` (`scripts/gerar-docs-api.ts`) a partir da especificação OpenAPI. Não editar à mão: alterar as rotas em `src/modules/**` e voltar a gerar.

Formato baseado em [bocoup/api-docs-template](https://github.com/bocoup/api-docs-template). Versão da API: 1.0.0. Total: **82 endpoints** em 10 grupos.

* **Base URL:** `http://localhost:3000/api`
* **Swagger interativo:** `http://localhost:3000/docs` · **OpenAPI JSON:** `http://localhost:3000/docs.json`
* **Autenticação:** JWT em `Authorization: Bearer <token>`. O token obtém-se em `POST /auth/sms/verificar` ou `POST /auth/codigo/verificar`.
* **Formato:** JSON (UTF-8), exceto os endpoints de upload (`multipart/form-data`). Valores em kwanzas (Kz); datas em UTC (ISO 8601).

## Formato das respostas

Todas as respostas em `/api`, de sucesso ou de erro, seguem o mesmo envelope. O conteúdo específico de cada endpoint vem sempre em `data`; nos erros, `data` traz `{ "codigo": "...", "detalhes": ... }`.

| Campo | Tipo | Descrição |
|---|---|---|
| `title` | string | Título curto do estado HTTP |
| `status` | number | Código HTTP |
| `detail` | string | Mensagem legível, em português |
| `instance` | string | Caminho do pedido |
| `data` | any \| null | Conteúdo da resposta (ou `{ codigo, detalhes? }` nos erros) |

Sucesso:

```json
{
  "title": "Sucesso",
  "status": 200,
  "detail": "Pedido processado.",
  "instance": "/api/categorias",
  "data": {
    "…": "…"
  }
}
```

Erro:

```json
{
  "title": "Falha na autenticação",
  "status": 401,
  "detail": "Falta o token de acesso.",
  "instance": "/api/admin/verificacoes",
  "data": {
    "codigo": "NAO_AUTENTICADO"
  }
}
```

Nos blocos abaixo, o corpo de sucesso mostra o envelope; o conteúdo exato de `data` pode ver-se no Swagger ou experimentando a Sample Call.

| Código HTTP | Significado |
|---|---|
| 200 | Sucesso |
| 201 | Criado com sucesso |
| 400 | Dados inválidos |
| 401 | Falha na autenticação |
| 403 | Acesso negado |
| 404 | Não encontrado |
| 409 | Conflito |
| 422 | Regra de negócio violada |

## Índice

* [Autenticação e conta](#autenticacao-e-conta) (10)
  * `POST /api/auth/sms/pedir` — Enviar código de entrada por SMS (RF01)
  * `POST /api/auth/sms/verificar` — Entrar ou criar conta com o código do SMS (RF01)
  * `POST /api/auth/codigo/pedir` — Enviar código de entrada por email (RF01)
  * `POST /api/auth/codigo/verificar` — Entrar ou criar conta com o código do email (RF01)
  * `POST /api/auth/sair` — Terminar a sessão neste dispositivo
  * `GET /api/eu` — Dados da minha conta (EuJSON)
  * `PATCH /api/eu` — Atualizar nome, telemóvel, email ou token de push
  * `DELETE /api/eu` — Desativar a minha conta (RGPD)
  * `PUT /api/eu/perfil-ativo` — Mudar para cliente ou para profissional (ecrã 20)
  * `PUT /api/eu/foto` — Mudar a foto de perfil
* [Catálogo e ajuda](#catalogo-e-ajuda) (3)
  * `GET /api/categorias` — Categorias de serviço com ícone e rótulo (RF02)
  * `GET /api/etiquetas` — Etiquetas rápidas para avaliar (RF12)
  * `GET /api/ajuda/perguntas` — Perguntas frequentes (RF16)
* [Profissionais](#profissionais) (16)
  * `GET /api/profissionais` — Pesquisar profissionais (RF02)
  * `GET /api/profissionais/perto` — Profissionais perto de si (ecrã 02)
  * `GET /api/profissionais/mapa` — Pinos do mapa (ecrã 22)
  * `GET /api/profissionais/eu/painel` — Início do profissional (ecrã 14)
  * `PUT /api/profissionais/eu` — Registo profissional e disponibilidade (ecrãs 12 e 14)
  * `PUT /api/profissionais/eu/disponibilidade` — Definir o horário semanal (RF15)
  * `GET /api/profissionais/eu/verificacao` — Estado da minha verificação (ecrã 13)
  * `POST /api/profissionais/eu/verificacao` — Pedir o selo Verificado de uma só vez: documento + fotografia (RF07)
  * `PUT /api/profissionais/eu/verificacao/documento` — Juntar a foto do documento de identidade (ecrã 13)
  * `PUT /api/profissionais/eu/verificacao/rosto` — Juntar a fotografia do rosto (ecrã 13)
  * `POST /api/profissionais/eu/verificacao/enviar` — Enviar para verificação (ecrã 13)
  * `POST /api/profissionais/eu/trabalhos` — Adicionar fotos à galeria "Trabalhos feitos" (RF06)
  * `DELETE /api/profissionais/eu/trabalhos/{id}` — Remover foto da galeria
  * `GET /api/profissionais/{id}` — Perfil do profissional com trabalhos feitos (RF06)
  * `GET /api/profissionais/{id}/avaliacoes` — Todas as avaliações de um profissional
  * `GET /api/profissionais/{id}/estatisticas` — Estatística das avaliações (ecrã 03, "Avaliações em números")
* [Moradas e favoritos](#moradas-e-favoritos) (7)
  * `GET /api/moradas` — As minhas moradas
  * `POST /api/moradas` — Guardar morada (GPS + ponto de referência)
  * `PUT /api/moradas/{id}` — Editar morada
  * `DELETE /api/moradas/{id}` — Apagar morada (não usada em pedidos)
  * `GET /api/favoritos` — Profissionais favoritos
  * `PUT /api/favoritos/{profissionalId}` — Adicionar aos favoritos
  * `DELETE /api/favoritos/{profissionalId}` — Remover dos favoritos
* [Pedidos](#pedidos) (15)
  * `GET /api/pedidos` — Os meus pedidos: em curso, concluídos, cancelados (RF13, ecrã 07)
  * `POST /api/pedidos` — Criar pedido de serviço (RF03, ecrã 10)
  * `GET /api/pedidos/em-curso` — Cliente: serviço à espera de confirmação (ecrãs 05 e 09)
  * `GET /api/pedidos/em-curso/lista` — Cliente: todos os serviços aceites, a caminho ou em curso
  * `GET /api/pedidos/por-confirmar` — Profissional: trabalho à espera do código do cliente (ecrã 16)
  * `GET /api/pedidos/por-confirmar/lista` — Profissional: todos os trabalhos à espera do código do cliente
  * `GET /api/pedidos/proximos` — Profissional: pedidos abertos perto de si (RF15)
  * `GET /api/pedidos/{id}` — Detalhe do pedido: estado, propostas, acordo, chat, comprovativo (RF08)
  * `PATCH /api/pedidos/{id}` — Cliente: editar pedido antes de aceitar uma proposta (RF05, ecrã 04)
  * `POST /api/pedidos/{id}/desfazer-aceitacao` — Cliente: desfazer a aceitação de uma proposta (ecrã 08)
  * `POST /api/pedidos/{id}/publicar` — Publicar um rascunho
  * `POST /api/pedidos/{id}/fotos` — Juntar fotos ao pedido (opcional, máx. 5) (RM04)
  * `POST /api/pedidos/{id}/cancelar` — Cancelar pedido (RF05)
  * `PATCH /api/pedidos/{id}/estado` — Profissional: "A caminho" e "Em curso" (RF08)
  * `POST /api/pedidos/{id}/pedir-de-novo` — "Pedir de novo": cria um rascunho igual a um pedido anterior (RF13)
* [Propostas](#propostas) (9)
  * `GET /api/propostas/{id}/estimativa-chegada` — Probabilidade de chegar a tempo (Monte Carlo, ecrã 04)
  * `GET /api/pedidos/{id}/propostas` — Cliente: comparar propostas (RF04)
  * `POST /api/pedidos/{id}/propostas` — Profissional: enviar proposta com preço fechado (RF15, ecrã 15)
  * `PATCH /api/propostas/{id}` — Profissional: corrigir a proposta antes de ser aceite
  * `POST /api/propostas/{id}/retirar` — Profissional: retirar proposta
  * `POST /api/propostas/{id}/recusar` — Cliente: recusar proposta (RF05)
  * `POST /api/propostas/{id}/aceitar` — Cliente: aceitar proposta e fechar o acordo (RF05)
  * `POST /api/pedidos/{id}/alteracoes-preco` — Profissional: pedir alteração do preço combinado
  * `POST /api/alteracoes-preco/{id}/responder` — Cliente: aprovar ou recusar a alteração de preço
* [Confirmação por QR e comprovativo](#confirmacao-por-qr-e-comprovativo) (4)
  * `GET /api/pedidos/{id}/qr` — Cliente: QR Code e código numérico do serviço em curso (ecrã 05)
  * `POST /api/pedidos/confirmar` — Profissional: confirmar o serviço só com o código (ou o QR), sem indicar o pedido (RF10, ecrã 16)
  * `POST /api/pedidos/{id}/confirmar` — Profissional: confirmar o serviço lendo o QR ou com o código numérico (RF10, ecrã 16)
  * `GET /api/pedidos/{id}/comprovativo` — Comprovativo digital: valor, data e profissional (RF10, RF17)
* [Garantia e avaliação](#garantia-e-avaliacao) (3)
  * `POST /api/pedidos/{id}/reclamacoes` — Reportar problema (antes de confirmar ou até 7 dias depois) (RF11)
  * `GET /api/reclamacoes` — As minhas reclamações
  * `POST /api/pedidos/{id}/avaliacao` — Avaliar com estrelas, etiquetas e comentário (RF12)
* [Conversas e notificações](#conversas-e-notificacoes) (9)
  * `GET /api/conversas` — Lista de conversas, uma por pedido e profissional (RF09, ecrã 18)
  * `GET /api/conversas/{id}` — Conversa com as últimas 50 mensagens (ecrã 19)
  * `POST /api/conversas/{id}/lida` — Marcar a conversa como lida (ecrã 19)
  * `POST /api/pedidos/{id}/conversas` — Cliente: abrir conversa com um profissional que enviou proposta
  * `GET /api/conversas/{id}/mensagens` — Mensagens da conversa, com paginação (marca como lidas)
  * `POST /api/conversas/{id}/mensagens` — Enviar mensagem com texto e/ou foto (RF09, ecrã 19)
  * `GET /api/notificacoes` — As minhas notificações
  * `POST /api/notificacoes/{id}/lida` — Marcar notificação como lida
  * `POST /api/notificacoes/lidas` — Marcar todas como lidas
* [Administração](#administracao) (6)
  * `GET /api/admin/verificacoes` — Pedidos de verificação de identidade
  * `GET /api/admin/verificacoes/{id}/{ficheiro}` — Ver o documento de identidade ou a fotografia do rosto (só admin)
  * `POST /api/admin/verificacoes/{id}/decidir` — Aprovar ou rejeitar verificação (atribui o selo Verificado)
  * `GET /api/admin/reclamacoes` — Reclamações para acompanhar (RF11)
  * `GET /api/admin/reclamacoes/{id}/foto` — Ver a foto junta a uma reclamação (só admin)
  * `PATCH /api/admin/reclamacoes/{id}` — Atualizar o estado de uma reclamação

## Autenticação e conta

#### Enviar código de entrada por SMS (RF01)

* **Title**

  Enviar código de entrada por SMS (RF01)

* **URL**

  `/api/auth/sms/pedir`

* **Method**

  `POST`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `telemovel` | string | sim | Número angolano: +244 e 9 dígitos começados por 9 |
  | `perfil` | `cliente` \\| `profissional` (omissão "cliente") | não |  |
  | `criar_conta` | boolean (omissão false) | não | Veio de "Criar conta" no ecrã 01 |

  ```json
  {
    "telemovel": "+244923000000",
    "perfil": "cliente",
    "criar_conta": false
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/auth/sms/pedir",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/auth/sms/pedir", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/auth/sms/pedir", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/auth/sms/pedir", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/auth/sms/pedir", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/auth/sms/pedir" \
    -H "Content-Type: application/json" \
    -d '{"telemovel":"+244923000000","perfil":"cliente","criar_conta":false}'
  ```

* **Notes**

  Envia um código de 6 dígitos por SMS (simulado: aparece no terminal da API). A resposta é igual para números novos e existentes. Só se pode pedir outro código passado 1 minuto. Fora de produção, o código vem também em codigo_dev. Rota pública.

---

#### Entrar ou criar conta com o código do SMS (RF01)

* **Title**

  Entrar ou criar conta com o código do SMS (RF01)

* **URL**

  `/api/auth/sms/verificar`

* **Method**

  `POST`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `telemovel` | string | sim | Número angolano: +244 e 9 dígitos começados por 9 |
  | `codigo` | string | sim |  |
  | `perfil` | `cliente` \\| `profissional` (omissão "cliente") | não |  |
  | `aceita_privacidade` | boolean | não | Consentimento RGPD (RNF10), obrigatório numa conta nova |
  | `nome` | string (mín. 2 car., máx. 100 car.) | não |  |
  | `dispositivo` | string (máx. 100 car.) | não |  |
  | `push_token` | string (máx. 255 car.) | não |  |

  ```json
  {
    "telemovel": "+244923000000",
    "codigo": "482173",
    "perfil": "cliente",
    "aceita_privacidade": true,
    "nome": "texto",
    "dispositivo": "texto",
    "push_token": "texto"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/auth/sms/verificar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/auth/sms/verificar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/auth/sms/verificar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/auth/sms/verificar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/auth/sms/verificar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/auth/sms/verificar" \
    -H "Content-Type: application/json" \
    -d '{"telemovel":"+244923000000","codigo":"482173","perfil":"cliente","aceita_privacidade":true,"nome":"texto","dispositivo":"texto","push_token":"texto"}'
  ```

* **Notes**

  Se o telemóvel ainda não tem conta, cria-a (é preciso aceita_privacidade: true). Com perfil = profissional, cria também o perfil profissional por completar. A sessão fica com o perfil escolhido (perfil_ativo). precisa_registo indica se a app deve abrir o registo profissional (ecrã 12). Rota pública.

---

#### Enviar código de entrada por email (RF01)

* **Title**

  Enviar código de entrada por email (RF01)

* **URL**

  `/api/auth/codigo/pedir`

* **Method**

  `POST`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `email` | string | sim |  |

  ```json
  {
    "email": "maria@exemplo.com"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/auth/codigo/pedir",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/auth/codigo/pedir", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/auth/codigo/pedir", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/auth/codigo/pedir", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/auth/codigo/pedir", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/auth/codigo/pedir" \
    -H "Content-Type: application/json" \
    -d '{"email":"maria@exemplo.com"}'
  ```

* **Notes**

  Envia um código de 6 dígitos para o email. Fora de produção, o código vem também em codigo_dev. Rota pública.

---

#### Entrar ou criar conta com o código do email (RF01)

* **Title**

  Entrar ou criar conta com o código do email (RF01)

* **URL**

  `/api/auth/codigo/verificar`

* **Method**

  `POST`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `email` | string | sim |  |
  | `codigo` | string | sim |  |
  | `nome` | string (mín. 2 car., máx. 100 car.) | não |  |
  | `telemovel` | string | não | Número angolano: +244 e 9 dígitos começados por 9 |
  | `tipo_perfil` | `cliente` \\| `profissional` | não |  |
  | `aceita_privacidade` | boolean | não | Consentimento RGPD (RNF10) |
  | `dispositivo` | string (máx. 100 car.) | não |  |
  | `push_token` | string (máx. 255 car.) | não |  |

  ```json
  {
    "email": "maria@exemplo.com",
    "codigo": "482173",
    "nome": "texto",
    "telemovel": "+244923000000",
    "tipo_perfil": "cliente",
    "aceita_privacidade": true,
    "dispositivo": "texto",
    "push_token": "texto"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/auth/codigo/verificar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/auth/codigo/verificar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/auth/codigo/verificar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/auth/codigo/verificar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/auth/codigo/verificar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/auth/codigo/verificar" \
    -H "Content-Type: application/json" \
    -d '{"email":"maria@exemplo.com","codigo":"482173","nome":"texto","telemovel":"+244923000000","tipo_perfil":"cliente","aceita_privacidade":true,"dispositivo":"texto","push_token":"texto"}'
  ```

* **Notes**

  Se o email ainda não tem conta, envie também nome, telemovel, tipo_perfil e aceita_privacidade para criar a conta. Sem esses dados devolve 400 REGISTO_INCOMPLETO (a app mostra o passo de registo). O código só é gasto quando a entrada é concluída. Rota pública.

---

#### Terminar a sessão neste dispositivo

* **Title**

  Terminar a sessão neste dispositivo

* **URL**

  `/api/auth/sair`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/auth/sair",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/auth/sair", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/auth/sair", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/auth/sair", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/auth/sair", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/auth/sair", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/auth/sair", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/auth/sair" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Dados da minha conta (EuJSON)

* **Title**

  Dados da minha conta (EuJSON)

* **URL**

  `/api/eu`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/eu",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/eu", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/eu", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/eu", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/eu", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/eu" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  A zona e o perfil_ativo seguem o perfil com que a sessão está a usar a app.

---

#### Atualizar nome, telemóvel, email ou token de push

* **Title**

  Atualizar nome, telemóvel, email ou token de push

* **URL**

  `/api/eu`

* **Method**

  `PATCH`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `nome` | string (mín. 2 car., máx. 100 car.) | não |  |
  | `telemovel` | string | não | Número angolano: +244 e 9 dígitos começados por 9 |
  | `email` | string | não |  |
  | `push_token` | string (máx. 255 car., pode ser null) | não |  |

  ```json
  {
    "nome": "texto",
    "telemovel": "+244923000000",
    "email": "maria@exemplo.com",
    "push_token": "texto"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/eu",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/eu", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/eu", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/eu", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/eu", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/eu", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/eu", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PATCH "http://localhost:3000/api/eu" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"nome":"texto","telemovel":"+244923000000","email":"maria@exemplo.com","push_token":"texto"}'
  ```

* **Notes**

  —

---

#### Desativar a minha conta (RGPD)

* **Title**

  Desativar a minha conta (RGPD)

* **URL**

  `/api/eu`

* **Method**

  `DELETE`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/eu",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/eu", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/eu", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/eu", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/eu", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X DELETE "http://localhost:3000/api/eu" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Desativa a conta e termina todas as sessões. O histórico de serviços é mantido para os comprovativos.

---

#### Mudar para cliente ou para profissional (ecrã 20)

* **Title**

  Mudar para cliente ou para profissional (ecrã 20)

* **URL**

  `/api/eu/perfil-ativo`

* **Method**

  `PUT`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `perfil` | `cliente` \\| `profissional` | sim |  |

  ```json
  {
    "perfil": "cliente"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/eu/perfil-ativo",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/eu/perfil-ativo", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/eu/perfil-ativo", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/eu/perfil-ativo", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/eu/perfil-ativo", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/eu/perfil-ativo", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/eu/perfil-ativo", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PUT "http://localhost:3000/api/eu/perfil-ativo" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"perfil":"cliente"}'
  ```

* **Notes**

  Muda o perfil desta sessão. Ao passar a profissional pela primeira vez, cria o perfil profissional por completar (a app segue para o registo, ecrã 12). A conta de administração não muda de perfil.

---

#### Mudar a foto de perfil

* **Title**

  Mudar a foto de perfil

* **URL**

  `/api/eu/foto`

* **Method**

  `PUT`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `multipart/form-data`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `foto` | ficheiro | não |  |

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/eu/foto",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/eu/foto", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/eu/foto", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/eu/foto", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/eu/foto", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/eu/foto", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/eu/foto", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PUT "http://localhost:3000/api/eu/foto" \
    -H "Authorization: Bearer <token>" \
    -F "foto=@ficheiro.jpg"
  ```

* **Notes**

  —

---

## Catálogo e ajuda

#### Categorias de serviço com ícone e rótulo (RF02)

* **Title**

  Categorias de serviço com ícone e rótulo (RF02)

* **URL**

  `/api/categorias`

* **Method**

  `GET`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/categorias",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/categorias", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/categorias", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/categorias"
  ```

* **Notes**

  As 13 categorias da app. chave é o identificador usado pela app; em_destaque marca as 8 da grelha do Início. Rota pública.

---

#### Etiquetas rápidas para avaliar (RF12)

* **Title**

  Etiquetas rápidas para avaliar (RF12)

* **URL**

  `/api/etiquetas`

* **Method**

  `GET`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/etiquetas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/etiquetas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/etiquetas", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/etiquetas"
  ```

* **Notes**

  A app envia a chave: pontual, preco_justo, simpatico, trabalho_limpo, rapido. Rota pública.

---

#### Perguntas frequentes (RF16)

* **Title**

  Perguntas frequentes (RF16)

* **URL**

  `/api/ajuda/perguntas`

* **Method**

  `GET`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `tema=[string]`  
  `q=[string]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/ajuda/perguntas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/ajuda/perguntas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/ajuda/perguntas", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/ajuda/perguntas"
  ```

* **Notes**

  Rota pública.

---

## Profissionais

#### Pesquisar profissionais (RF02)

* **Title**

  Pesquisar profissionais (RF02)

* **URL**

  `/api/profissionais`

* **Method**

  `GET`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  
  `offset=[integer (mín. 0, omissão 0, pode ser null)]`  
  `q=[string (máx. 60 car.)]`  
  `categoria_id=[integer (pode ser null)]`  
  `categoria_chave=[string (máx. 30 car.)]`  
  `lat=[number (mín. -90, máx. 90, pode ser null)]`  
  `lng=[number (mín. -180, máx. 180, pode ser null)]`  
  `raio_km=[number (mín. 1, máx. 100, omissão 15)]`  
  `verificado=[`true` \| `false`]`  
  `ordenar=[`distancia` \| `avaliacao` \| `servicos` (omissão "avaliacao")]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/profissionais"
  ```

* **Notes**

  Com lat/lng devolve a distância e filtra pelo raio. Ordenar por distância, avaliação ou serviços. Rota pública.

---

#### Profissionais perto de si (ecrã 02)

* **Title**

  Profissionais perto de si (ecrã 02)

* **URL**

  `/api/profissionais/perto`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  
  `categoria_chave=[string (máx. 30 car.)]`  
  `raio_km=[number (mín. 1, máx. 100)]`  
  `lat=[number (mín. -90, máx. 90, pode ser null)]`  
  `lng=[number (mín. -180, máx. 180, pode ser null)]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/perto",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/perto", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/perto", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/perto", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/perto", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/profissionais/perto" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  ProfissionalResumo ordenado pela distância à morada predefinida (ou a lat/lng indicados). Sem morada com GPS, usa Talatona como referência.

---

#### Pinos do mapa (ecrã 22)

* **Title**

  Pinos do mapa (ecrã 22)

* **URL**

  `/api/profissionais/mapa`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `raio_km=[number (mín. 1, máx. 50, omissão 5)]`  
  `categoria_chave=[string (máx. 30 car.)]`  
  `lat=[number (mín. -90, máx. 90, pode ser null)]`  
  `lng=[number (mín. -180, máx. 180, pode ser null)]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/mapa",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/mapa", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/mapa", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/mapa", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/mapa", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/profissionais/mapa" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Posição de cada profissional disponível num mapa quadrado centrado em si, com raio_km para cada lado. x e y vão de 0 a 1 (0,0 é o canto superior esquerdo).

---

#### Início do profissional (ecrã 14)

* **Title**

  Início do profissional (ecrã 14)

* **URL**

  `/api/profissionais/eu/painel`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/eu/painel",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/painel", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/painel", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/painel", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/painel", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/profissionais/eu/painel" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Resumo do profissional e os pedidos abertos das suas categorias dentro do raio (PedidoPertoJSON). pedidos_novos conta os que ainda não têm proposta dele e foram publicados há menos de uma hora.

---

#### Registo profissional e disponibilidade (ecrãs 12 e 14)

* **Title**

  Registo profissional e disponibilidade (ecrãs 12 e 14)

* **URL**

  `/api/profissionais/eu`

* **Method**

  `PUT`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `nome_completo` | string (mín. 2 car., máx. 100 car.) | não |  |
  | `categorias` | any[] | não |  |
  | `anos_experiencia` | integer (mín. 0, máx. 60, pode ser null) | não |  |
  | `zona` | string (mín. 2 car., máx. 80 car.) | não |  |
  | `raio_atuacao_km` | integer (mín. 1, máx. 30) | não |  |
  | `disponivel` | boolean | não |  |
  | `bio` | string (máx. 500 car., pode ser null) | não |  |
  | `latitude` | number (mín. -90, máx. 90, pode ser null) | não |  |
  | `longitude` | number (mín. -180, máx. 180, pode ser null) | não |  |
  | `mao_obra_desde` | integer (mín. 0, máx. 10000000, pode ser null) | não |  |
  | `especialidades` | string (mín. 2 car., máx. 60 car.)[] | não |  |

  ```json
  {
    "nome_completo": "texto",
    "categorias": [
      "canalizador",
      "pedreiro"
    ],
    "anos_experiencia": 0,
    "zona": "Viana, Luanda",
    "raio_atuacao_km": 1,
    "disponivel": true,
    "bio": "texto",
    "latitude": -90,
    "longitude": -180,
    "mao_obra_desde": 0,
    "especialidades": [
      "texto"
    ]
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/eu",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/profissionais/eu", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/profissionais/eu", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PUT "http://localhost:3000/api/profissionais/eu" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"nome_completo":"texto","categorias":["canalizador","pedreiro"],"anos_experiencia":0,"zona":"Viana, Luanda","raio_atuacao_km":1,"disponivel":true,"bio":"texto","latitude":-90,"longitude":-180,"mao_obra_desde":0,"especialidades":["texto"]}'
  ```

* **Notes**

  Cria o perfil profissional se ainda não existir e atualiza só os campos enviados. categorias aceita as chaves da app (ou ids). Também serve para o interruptor "Disponível para trabalhar" ({disponivel}). A sessão passa a profissional.

---

#### Definir o horário semanal (RF15)

* **Title**

  Definir o horário semanal (RF15)

* **URL**

  `/api/profissionais/eu/disponibilidade`

* **Method**

  `PUT`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `horarios` | object[] | sim |  |

  ```json
  {
    "horarios": [
      {
        "dia_semana": 1,
        "hora_inicio": "texto",
        "hora_fim": "texto"
      }
    ]
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/eu/disponibilidade",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/disponibilidade", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/disponibilidade", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/disponibilidade", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/disponibilidade", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/profissionais/eu/disponibilidade", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/profissionais/eu/disponibilidade", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PUT "http://localhost:3000/api/profissionais/eu/disponibilidade" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"horarios":[{"dia_semana":1,"hora_inicio":"texto","hora_fim":"texto"}]}'
  ```

* **Notes**

  —

---

#### Estado da minha verificação (ecrã 13)

* **Title**

  Estado da minha verificação (ecrã 13)

* **URL**

  `/api/profissionais/eu/verificacao`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/eu/verificacao",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/profissionais/eu/verificacao" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  estado: nao_pedida, rascunho, pendente, aprovada ou rejeitada.

---

#### Pedir o selo Verificado de uma só vez: documento + fotografia (RF07)

* **Title**

  Pedir o selo Verificado de uma só vez: documento + fotografia (RF07)

* **URL**

  `/api/profissionais/eu/verificacao`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `multipart/form-data`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `tipo_documento` | `bilhete_identidade` \\| `passaporte` \\| `cartao_residente` | sim |  |
  | `numero_documento` | string (mín. 5 car., máx. 30 car.) | sim |  |
  | `documento` | ficheiro | não |  |
  | `selfie` | ficheiro | não |  |

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/profissionais/eu/verificacao",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/profissionais/eu/verificacao", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/profissionais/eu/verificacao" \
    -H "Authorization: Bearer <token>" \
    -F "tipo_documento=bilhete_identidade" \
    -F "numero_documento=texto" \
    -F "documento=@ficheiro.jpg" \
    -F "selfie=@ficheiro.jpg"
  ```

* **Notes**

  Alternativa aos três passos do ecrã 13: envia os dois ficheiros e fica logo em análise.

---

#### Juntar a foto do documento de identidade (ecrã 13)

* **Title**

  Juntar a foto do documento de identidade (ecrã 13)

* **URL**

  `/api/profissionais/eu/verificacao/documento`

* **Method**

  `PUT`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `multipart/form-data`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `tipo_documento` | `bilhete_identidade` \\| `passaporte` \\| `cartao_residente` (omissão "bilhete_identidade") | não |  |
  | `numero_documento` | string (mín. 5 car., máx. 30 car.) | não |  |
  | `documento` | ficheiro | não |  |

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/eu/verificacao/documento",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/verificacao/documento", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/verificacao/documento", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/verificacao/documento", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/verificacao/documento", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/profissionais/eu/verificacao/documento", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/profissionais/eu/verificacao/documento", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PUT "http://localhost:3000/api/profissionais/eu/verificacao/documento" \
    -H "Authorization: Bearer <token>" \
    -F "tipo_documento=bilhete_identidade" \
    -F "numero_documento=texto" \
    -F "documento=@ficheiro.jpg"
  ```

* **Notes**

  Multipart com o campo "documento". A imagem fica fora de /uploads (só o admin a vê). Fora de produção, sem ficheiro, regista uma captura simulada.

---

#### Juntar a fotografia do rosto (ecrã 13)

* **Title**

  Juntar a fotografia do rosto (ecrã 13)

* **URL**

  `/api/profissionais/eu/verificacao/rosto`

* **Method**

  `PUT`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `multipart/form-data`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `rosto` | ficheiro | não |  |

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/eu/verificacao/rosto",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/verificacao/rosto", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/verificacao/rosto", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/verificacao/rosto", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/verificacao/rosto", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/profissionais/eu/verificacao/rosto", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/profissionais/eu/verificacao/rosto", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PUT "http://localhost:3000/api/profissionais/eu/verificacao/rosto" \
    -H "Authorization: Bearer <token>" \
    -F "rosto=@ficheiro.jpg"
  ```

* **Notes**

  Multipart com o campo "rosto". Fica fora de /uploads. Fora de produção, sem ficheiro, regista uma captura simulada.

---

#### Enviar para verificação (ecrã 13)

* **Title**

  Enviar para verificação (ecrã 13)

* **URL**

  `/api/profissionais/eu/verificacao/enviar`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/eu/verificacao/enviar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/verificacao/enviar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/verificacao/enviar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/verificacao/enviar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/verificacao/enviar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/profissionais/eu/verificacao/enviar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/profissionais/eu/verificacao/enviar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/profissionais/eu/verificacao/enviar" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Precisa do documento e do rosto. A análise demora até 48 horas.

---

#### Adicionar fotos à galeria "Trabalhos feitos" (RF06)

* **Title**

  Adicionar fotos à galeria "Trabalhos feitos" (RF06)

* **URL**

  `/api/profissionais/eu/trabalhos`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `multipart/form-data`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `legenda` | string (máx. 150 car.) | não |  |
  | `pedido_id` | integer (mín. 0) | não |  |
  | `fotos` | ficheiro[] | sim |  |

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/profissionais/eu/trabalhos",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/trabalhos", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/trabalhos", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/trabalhos", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/trabalhos", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/profissionais/eu/trabalhos", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/profissionais/eu/trabalhos", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/profissionais/eu/trabalhos" \
    -H "Authorization: Bearer <token>" \
    -F "legenda=texto" \
    -F "pedido_id=0" \
    -F "fotos=@ficheiro.jpg"
  ```

* **Notes**

  pedido_id é opcional; quando indicado, tem de ser um serviço seu já confirmado por QR.

---

#### Remover foto da galeria

* **Title**

  Remover foto da galeria

* **URL**

  `/api/profissionais/eu/trabalhos/{id}`

* **Method**

  `DELETE`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/eu/trabalhos/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/eu/trabalhos/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/profissionais/eu/trabalhos/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/profissionais/eu/trabalhos/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/eu/trabalhos/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X DELETE "http://localhost:3000/api/profissionais/eu/trabalhos/0" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Perfil do profissional com trabalhos feitos (RF06)

* **Title**

  Perfil do profissional com trabalhos feitos (RF06)

* **URL**

  `/api/profissionais/{id}`

* **Method**

  `GET`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  `lat=[number (mín. -90, máx. 90, pode ser null)]`  
  `lng=[number (mín. -180, máx. 180, pode ser null)]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/profissionais/0"
  ```

* **Notes**

  ProfissionalDetalhe: o ProfissionalResumo com especialidades, trabalhos e avaliações. Com lat/lng traz a distância. Rota pública.

---

#### Todas as avaliações de um profissional

* **Title**

  Todas as avaliações de um profissional

* **URL**

  `/api/profissionais/{id}/avaliacoes`

* **Method**

  `GET`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  
  `offset=[integer (mín. 0, omissão 0, pode ser null)]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/0/avaliacoes",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/0/avaliacoes", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/0/avaliacoes", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/profissionais/0/avaliacoes"
  ```

* **Notes**

  Rota pública.

---

#### Estatística das avaliações (ecrã 03, "Avaliações em números")

* **Title**

  Estatística das avaliações (ecrã 03, "Avaliações em números")

* **URL**

  `/api/profissionais/{id}/estatisticas`

* **Method**

  `GET`

* **Autenticação**

  Pública (não precisa de token).

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/profissionais/0/estatisticas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/profissionais/0/estatisticas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/profissionais/0/estatisticas", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/profissionais/0/estatisticas"
  ```

* **Notes**

  A partir da distribuição 1–5 estrelas: n, média, mediana, moda, desvio padrão e variância amostrais, intervalo de confiança a 95 % da média (t de Student se n < 30, normal z = 1,96 se n ≥ 30), distribuição e média bayesiana (prior de 10 avaliações à média da categoria principal). Sem avaliações, os valores vêm a null. Fórmulas em docs/MATEMATICA.md. Rota pública.

---

## Moradas e favoritos

#### As minhas moradas

* **Title**

  As minhas moradas

* **URL**

  `/api/moradas`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/moradas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/moradas" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Guardar morada (GPS + ponto de referência)

* **Title**

  Guardar morada (GPS + ponto de referência)

* **URL**

  `/api/moradas`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `rotulo` | string (mín. 1 car., máx. 40 car., omissão "Casa") | não |  |
  | `endereco` | string (mín. 3 car., máx. 200 car.) | sim |  |
  | `ponto_referencia` | string (máx. 200 car., pode ser null) | não |  |
  | `bairro` | string (máx. 80 car., pode ser null) | não |  |
  | `municipio` | string (mín. 2 car., máx. 80 car.) | sim |  |
  | `provincia` | string (máx. 60 car., omissão "Luanda") | não |  |
  | `latitude` | number (mín. -90, máx. 90, pode ser null) | não |  |
  | `longitude` | number (mín. -180, máx. 180, pode ser null) | não |  |
  | `predefinida` | boolean (omissão false) | não |  |

  ```json
  {
    "rotulo": "Casa",
    "endereco": "texto",
    "ponto_referencia": "Perto da cantina do Sr. Zé",
    "bairro": "texto",
    "municipio": "texto",
    "provincia": "Luanda",
    "latitude": -90,
    "longitude": -180,
    "predefinida": false
  }
  ```

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/moradas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/moradas", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/moradas" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"rotulo":"Casa","endereco":"texto","ponto_referencia":"Perto da cantina do Sr. Zé","bairro":"texto","municipio":"texto","provincia":"Luanda","latitude":-90,"longitude":-180,"predefinida":false}'
  ```

* **Notes**

  —

---

#### Editar morada

* **Title**

  Editar morada

* **URL**

  `/api/moradas/{id}`

* **Method**

  `PUT`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `rotulo` | string (mín. 1 car., máx. 40 car., omissão "Casa") | não |  |
  | `endereco` | string (mín. 3 car., máx. 200 car.) | sim |  |
  | `ponto_referencia` | string (máx. 200 car., pode ser null) | não |  |
  | `bairro` | string (máx. 80 car., pode ser null) | não |  |
  | `municipio` | string (mín. 2 car., máx. 80 car.) | sim |  |
  | `provincia` | string (máx. 60 car., omissão "Luanda") | não |  |
  | `latitude` | number (mín. -90, máx. 90, pode ser null) | não |  |
  | `longitude` | number (mín. -180, máx. 180, pode ser null) | não |  |
  | `predefinida` | boolean (omissão false) | não |  |

  ```json
  {
    "rotulo": "Casa",
    "endereco": "texto",
    "ponto_referencia": "Perto da cantina do Sr. Zé",
    "bairro": "texto",
    "municipio": "texto",
    "provincia": "Luanda",
    "latitude": -90,
    "longitude": -180,
    "predefinida": false
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/moradas/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PUT "http://localhost:3000/api/moradas/0" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"rotulo":"Casa","endereco":"texto","ponto_referencia":"Perto da cantina do Sr. Zé","bairro":"texto","municipio":"texto","provincia":"Luanda","latitude":-90,"longitude":-180,"predefinida":false}'
  ```

* **Notes**

  —

---

#### Apagar morada (não usada em pedidos)

* **Title**

  Apagar morada (não usada em pedidos)

* **URL**

  `/api/moradas/{id}`

* **Method**

  `DELETE`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/moradas/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/moradas/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X DELETE "http://localhost:3000/api/moradas/0" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Profissionais favoritos

* **Title**

  Profissionais favoritos

* **URL**

  `/api/favoritos`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/favoritos",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/favoritos", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/favoritos", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/favoritos", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/favoritos", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/favoritos" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Adicionar aos favoritos

* **Title**

  Adicionar aos favoritos

* **URL**

  `/api/favoritos/{profissionalId}`

* **Method**

  `PUT`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `profissionalId=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/favoritos/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PUT "http://localhost:3000/api/favoritos/0" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Remover dos favoritos

* **Title**

  Remover dos favoritos

* **URL**

  `/api/favoritos/{profissionalId}`

* **Method**

  `DELETE`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `profissionalId=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/favoritos/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/favoritos/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X DELETE "http://localhost:3000/api/favoritos/0" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

## Pedidos

#### Os meus pedidos: em curso, concluídos, cancelados (RF13, ecrã 07)

* **Title**

  Os meus pedidos: em curso, concluídos, cancelados (RF13, ecrã 07)

* **URL**

  `/api/pedidos`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  
  `offset=[integer (mín. 0, omissão 0, pode ser null)]`  
  `grupo=[`ativos` \| `rascunhos` \| `concluidos` \| `cancelados`]`  
  `categoria_id=[integer (pode ser null)]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Lista de PedidoJSON (com propostas vazias), mais recentes primeiro. Cliente: os pedidos que publicou. Profissional: os serviços em que a proposta dele foi aceite (com cliente_curto).

---

#### Criar pedido de serviço (RF03, ecrã 10)

* **Title**

  Criar pedido de serviço (RF03, ecrã 10)

* **URL**

  `/api/pedidos`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `categoria_id` | integer (mín. 0) | não |  |
  | `categoria_chave` | string (máx. 30 car.) | não |  |
  | `morada_id` | integer (mín. 0) | não |  |
  | `zona` | string (mín. 2 car., máx. 80 car.) | não | Usada quando não vem morada_id |
  | `ponto_referencia` | string (máx. 200 car.) | não |  |
  | `titulo` | string (mín. 3 car., máx. 100 car.) | sim |  |
  | `descricao` | string (mín. 5 car., máx. 2000 car.) | sim |  |
  | `quando` | string (pode ser null) | não | null = o mais cedo possível |
  | `urgencia` | `o_mais_cedo_possivel` \\| `agendado` | não |  |
  | `data_pretendida` | string (pode ser null) | não |  |
  | `publicar` | boolean (omissão true) | não |  |

  ```json
  {
    "categoria_id": 0,
    "categoria_chave": "canalizador",
    "morada_id": 0,
    "zona": "Talatona",
    "ponto_referencia": "perto da cantina do Sr. Zé",
    "titulo": "Fuga de água na cozinha",
    "descricao": "Cano a pingar debaixo do lava-loiça.",
    "quando": "texto",
    "urgencia": "o_mais_cedo_possivel",
    "data_pretendida": "texto",
    "publicar": true
  }
  ```

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/pedidos",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"categoria_id":0,"categoria_chave":"canalizador","morada_id":0,"zona":"Talatona","ponto_referencia":"perto da cantina do Sr. Zé","titulo":"Fuga de água na cozinha","descricao":"Cano a pingar debaixo do lava-loiça.","quando":"texto","urgencia":"o_mais_cedo_possivel","data_pretendida":"texto","publicar":true}'
  ```

* **Notes**

  Formato da app: {categoria_chave, titulo, descricao, zona, ponto_referencia, quando, publicar}. publicar=false guarda como rascunho (RM03, rede instável). Ao publicar, avisa os profissionais perto. Devolve {id, estado, pedido: PedidoJSON, profissionais_avisados, categoria_plural}.

---

#### Cliente: serviço à espera de confirmação (ecrãs 05 e 09)

* **Title**

  Cliente: serviço à espera de confirmação (ecrãs 05 e 09)

* **URL**

  `/api/pedidos/em-curso`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/em-curso",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/em-curso", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/em-curso", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/em-curso", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/em-curso", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/em-curso" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  O pedido aceite, a caminho ou em curso mais recente (PedidoJSON), ou null. Para ver todos: /pedidos/em-curso/lista.

---

#### Cliente: todos os serviços aceites, a caminho ou em curso

* **Title**

  Cliente: todos os serviços aceites, a caminho ou em curso

* **URL**

  `/api/pedidos/em-curso/lista`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/em-curso/lista",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/em-curso/lista", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/em-curso/lista", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/em-curso/lista", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/em-curso/lista", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/em-curso/lista" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Lista de PedidoJSON, o mais recente primeiro ([] se não houver).

---

#### Profissional: trabalho à espera do código do cliente (ecrã 16)

* **Title**

  Profissional: trabalho à espera do código do cliente (ecrã 16)

* **URL**

  `/api/pedidos/por-confirmar`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/por-confirmar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/por-confirmar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/por-confirmar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/por-confirmar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/por-confirmar", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/por-confirmar" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Devolve {pedido_id, servico, cliente, valor} do trabalho mais recente, ou null. Com vários serviços ativos, use /pedidos/por-confirmar/lista e confirme com POST /pedidos/confirmar (procura o pedido pelo código).

---

#### Profissional: todos os trabalhos à espera do código do cliente

* **Title**

  Profissional: todos os trabalhos à espera do código do cliente

* **URL**

  `/api/pedidos/por-confirmar/lista`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/por-confirmar/lista",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/por-confirmar/lista", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/por-confirmar/lista", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/por-confirmar/lista", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/por-confirmar/lista", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/por-confirmar/lista" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Lista de {pedido_id, servico, cliente, valor}, o mais recente primeiro ([] se não houver).

---

#### Profissional: pedidos abertos perto de si (RF15)

* **Title**

  Profissional: pedidos abertos perto de si (RF15)

* **URL**

  `/api/pedidos/proximos`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  
  `offset=[integer (mín. 0, omissão 0, pode ser null)]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/proximos",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/proximos", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/proximos", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/proximos", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/proximos", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/proximos" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Só mostra bairro e distância; a morada exata só é partilhada depois de aceitar (RNF10).

---

#### Detalhe do pedido: estado, propostas, acordo, chat, comprovativo (RF08)

* **Title**

  Detalhe do pedido: estado, propostas, acordo, chat, comprovativo (RF08)

* **URL**

  `/api/pedidos/{id}`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/0" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  PedidoJSON com propostas, mais o detalhe completo (morada, acordo, histórico…). O que se vê depende de quem pede: contactos e morada exata só depois de aceitar (RNF10). O profissional escolhido recebe contacto_cliente {nome, telemovel, morada, ponto_referencia, zona, …}. Para o profissional traz também distancia_km e novo.

---

#### Cliente: editar pedido antes de aceitar uma proposta (RF05, ecrã 04)

* **Title**

  Cliente: editar pedido antes de aceitar uma proposta (RF05, ecrã 04)

* **URL**

  `/api/pedidos/{id}`

* **Method**

  `PATCH`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `categoria_chave` | string (máx. 30 car.) | não |  |
  | `categoria_id` | integer (mín. 0) | não |  |
  | `titulo` | string (mín. 3 car., máx. 100 car.) | não |  |
  | `descricao` | string (mín. 5 car., máx. 2000 car.) | não |  |
  | `zona` | string (mín. 2 car., máx. 80 car.) | não | Usada quando não vem morada_id |
  | `ponto_referencia` | string (máx. 200 car., pode ser null) | não |  |
  | `quando` | string (pode ser null) | não | null = o mais cedo possível |
  | `morada_id` | integer (mín. 0) | não |  |
  | `urgencia` | `o_mais_cedo_possivel` \\| `agendado` | não |  |
  | `data_pretendida` | string (pode ser null) | não |  |

  ```json
  {
    "categoria_chave": "canalizador",
    "categoria_id": 0,
    "titulo": "Fuga de água na cozinha",
    "descricao": "Cano a pingar debaixo do lava-loiça.",
    "zona": "Talatona",
    "ponto_referencia": "perto da cantina do Sr. Zé",
    "quando": "texto",
    "morada_id": 0,
    "urgencia": "o_mais_cedo_possivel",
    "data_pretendida": "texto"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PATCH "http://localhost:3000/api/pedidos/0" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"categoria_chave":"canalizador","categoria_id":0,"titulo":"Fuga de água na cozinha","descricao":"Cano a pingar debaixo do lava-loiça.","zona":"Talatona","ponto_referencia":"perto da cantina do Sr. Zé","quando":"texto","morada_id":0,"urgencia":"o_mais_cedo_possivel","data_pretendida":"texto"}'
  ```

* **Notes**

  Aceita o formato da app, igual ao de POST /pedidos: categoria_chave, titulo, descricao, zona, ponto_referencia, quando (null = o mais cedo possível). Também aceita categoria_id, morada_id, urgencia e data_pretendida. Só muda os campos enviados. 409 PEDIDO_NAO_EDITAVEL se já houver proposta aceite. Devolve o PedidoJSON.

---

#### Cliente: desfazer a aceitação de uma proposta (ecrã 08)

* **Title**

  Cliente: desfazer a aceitação de uma proposta (ecrã 08)

* **URL**

  `/api/pedidos/{id}/desfazer-aceitacao`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/desfazer-aceitacao",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/desfazer-aceitacao", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/desfazer-aceitacao", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/desfazer-aceitacao", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/desfazer-aceitacao", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/desfazer-aceitacao", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/desfazer-aceitacao", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/desfazer-aceitacao" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Só enquanto o pedido está "aceite" e nos primeiros minutos (DESFAZER_ACEITACAO_MIN, 5 por omissão). As propostas voltam a estar disponíveis e o QR é anulado. Devolve o PedidoJSON.

---

#### Publicar um rascunho

* **Title**

  Publicar um rascunho

* **URL**

  `/api/pedidos/{id}/publicar`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/publicar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/publicar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/publicar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/publicar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/publicar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/publicar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/publicar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/publicar" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Juntar fotos ao pedido (opcional, máx. 5) (RM04)

* **Title**

  Juntar fotos ao pedido (opcional, máx. 5) (RM04)

* **URL**

  `/api/pedidos/{id}/fotos`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `multipart/form-data`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `fotos` | ficheiro[] | sim |  |

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/pedidos/0/fotos",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/fotos", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/fotos", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/fotos", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/fotos", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/fotos", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/fotos", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/fotos" \
    -H "Authorization: Bearer <token>" \
    -F "fotos=@ficheiro.jpg"
  ```

* **Notes**

  —

---

#### Cancelar pedido (RF05)

* **Title**

  Cancelar pedido (RF05)

* **URL**

  `/api/pedidos/{id}/cancelar`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `motivo` | string (máx. 255 car.) | não |  |

  ```json
  {
    "motivo": "texto"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/cancelar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/cancelar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/cancelar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/cancelar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/cancelar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/cancelar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/cancelar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/cancelar" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"motivo":"texto"}'
  ```

* **Notes**

  Possível até o serviço começar. Depois de "em curso", use Reportar problema.

---

#### Profissional: "A caminho" e "Em curso" (RF08)

* **Title**

  Profissional: "A caminho" e "Em curso" (RF08)

* **URL**

  `/api/pedidos/{id}/estado`

* **Method**

  `PATCH`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `estado` | `a_caminho` \\| `em_curso` | sim |  |

  ```json
  {
    "estado": "a_caminho"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/estado",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/estado", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/estado", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/estado", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/estado", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/estado", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/estado", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PATCH "http://localhost:3000/api/pedidos/0/estado" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"estado":"a_caminho"}'
  ```

* **Notes**

  "Concluído" só acontece pela confirmação com QR Code ou código. Devolve {id, estado}.

---

#### "Pedir de novo": cria um rascunho igual a um pedido anterior (RF13)

* **Title**

  "Pedir de novo": cria um rascunho igual a um pedido anterior (RF13)

* **URL**

  `/api/pedidos/{id}/pedir-de-novo`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/pedidos/0/pedir-de-novo",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/pedir-de-novo", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/pedir-de-novo", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/pedir-de-novo", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/pedir-de-novo", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/pedir-de-novo", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/pedir-de-novo", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/pedir-de-novo" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Devolve {id, estado: "rascunho", mensagem, pedido: PedidoJSON}. Publica-se com POST /pedidos/:id/publicar.

---

## Propostas

#### Probabilidade de chegar a tempo (Monte Carlo, ecrã 04)

* **Title**

  Probabilidade de chegar a tempo (Monte Carlo, ecrã 04)

* **URL**

  `/api/propostas/{id}/estimativa-chegada`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/propostas/0/estimativa-chegada",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/propostas/0/estimativa-chegada", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/propostas/0/estimativa-chegada", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/propostas/0/estimativa-chegada", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/propostas/0/estimativa-chegada", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/propostas/0/estimativa-chegada" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  10 000 simulações de tempo = preparação U(5,15) + distância / velocidade lognormal (mediana 18 km/h, σ = 0,5) + atraso U(5,25) com probabilidade 0,3. Devolve {proposta_id, distancia_km, tempo_prometido_min, simulacoes, media_min, p50_min, p90_min, prob_cumprir}. Semente fixa por proposta (resultado estável). Só o cliente do pedido ou o profissional da proposta. 400 SEM_DISTANCIA sem GPS; 400 SEM_TEMPO_PROMETIDO em propostas "na hora pedida".

---

#### Cliente: comparar propostas (RF04)

* **Title**

  Cliente: comparar propostas (RF04)

* **URL**

  `/api/pedidos/{id}/propostas`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  `ordenar=[`preco` \| `avaliacao` \| `chegada` (omissão "preco")]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/propostas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/0/propostas" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Lista de PropostaJSON: preço em Kz por componentes, chegada prevista, estrelas e selo Verificado.

---

#### Profissional: enviar proposta com preço fechado (RF15, ecrã 15)

* **Title**

  Profissional: enviar proposta com preço fechado (RF15, ecrã 15)

* **URL**

  `/api/pedidos/{id}/propostas`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `valor_mao_obra` | number (mín. 0, máx. 100000000) | sim |  |
  | `valor_material` | number (mín. 0, máx. 100000000, omissão 0) | não |  |
  | `valor_deslocacao` | number (mín. 0, máx. 100000000, omissão 0) | não |  |
  | `material_detalhe` | string (máx. 150 car.) | não |  |
  | `inclui_descricao` | string (máx. 300 car.) | não | Se vazio, é gerado a partir das componentes |
  | `tempo_chegada_min` | integer (mín. 5, máx. 1440) | não |  |
  | `na_hora_pedida` | boolean (omissão false) | não | Chega à hora que o cliente pediu (em vez de tempo_chegada_min) |
  | `mensagem` | string (máx. 500 car.) | não |  |

  ```json
  {
    "valor_mao_obra": 8000,
    "valor_material": 3500,
    "valor_deslocacao": 1000,
    "material_detalhe": "sifão e vedante",
    "inclui_descricao": "texto",
    "tempo_chegada_min": 40,
    "na_hora_pedida": false,
    "mensagem": "texto"
  }
  ```

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/pedidos/0/propostas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/propostas", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/propostas" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"valor_mao_obra":8000,"valor_material":3500,"valor_deslocacao":1000,"material_detalhe":"sifão e vedante","inclui_descricao":"texto","tempo_chegada_min":40,"na_hora_pedida":false,"mensagem":"texto"}'
  ```

* **Notes**

  Preço por componentes; o total é calculado pela base de dados e tem de ser pelo menos 500 Kz. Chegada: tempo_chegada_min ou na_hora_pedida (só em pedidos com hora marcada). Uma proposta por profissional e pedido. Devolve a PropostaJSON.

---

#### Profissional: corrigir a proposta antes de ser aceite

* **Title**

  Profissional: corrigir a proposta antes de ser aceite

* **URL**

  `/api/propostas/{id}`

* **Method**

  `PATCH`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `valor_mao_obra` | number (mín. 0, máx. 100000000) | não |  |
  | `valor_material` | number (mín. 0, máx. 100000000, omissão 0) | não |  |
  | `valor_deslocacao` | number (mín. 0, máx. 100000000, omissão 0) | não |  |
  | `material_detalhe` | string (máx. 150 car.) | não |  |
  | `inclui_descricao` | string (máx. 300 car.) | não | Se vazio, é gerado a partir das componentes |
  | `tempo_chegada_min` | integer (mín. 5, máx. 1440) | não |  |
  | `na_hora_pedida` | boolean (omissão false) | não | Chega à hora que o cliente pediu (em vez de tempo_chegada_min) |
  | `mensagem` | string (máx. 500 car.) | não |  |

  ```json
  {
    "valor_mao_obra": 8000,
    "valor_material": 3500,
    "valor_deslocacao": 1000,
    "material_detalhe": "sifão e vedante",
    "inclui_descricao": "texto",
    "tempo_chegada_min": 40,
    "na_hora_pedida": false,
    "mensagem": "texto"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/propostas/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/propostas/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/propostas/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/propostas/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/propostas/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/propostas/0", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/propostas/0", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PATCH "http://localhost:3000/api/propostas/0" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"valor_mao_obra":8000,"valor_material":3500,"valor_deslocacao":1000,"material_detalhe":"sifão e vedante","inclui_descricao":"texto","tempo_chegada_min":40,"na_hora_pedida":false,"mensagem":"texto"}'
  ```

* **Notes**

  —

---

#### Profissional: retirar proposta

* **Title**

  Profissional: retirar proposta

* **URL**

  `/api/propostas/{id}/retirar`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/propostas/0/retirar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/propostas/0/retirar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/propostas/0/retirar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/propostas/0/retirar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/propostas/0/retirar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/propostas/0/retirar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/propostas/0/retirar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/propostas/0/retirar" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Cliente: recusar proposta (RF05)

* **Title**

  Cliente: recusar proposta (RF05)

* **URL**

  `/api/propostas/{id}/recusar`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/propostas/0/recusar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/propostas/0/recusar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/propostas/0/recusar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/propostas/0/recusar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/propostas/0/recusar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/propostas/0/recusar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/propostas/0/recusar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/propostas/0/recusar" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Cliente: aceitar proposta e fechar o acordo (RF05)

* **Title**

  Cliente: aceitar proposta e fechar o acordo (RF05)

* **URL**

  `/api/propostas/{id}/aceitar`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/propostas/0/aceitar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/propostas/0/aceitar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/propostas/0/aceitar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/propostas/0/aceitar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/propostas/0/aceitar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/propostas/0/aceitar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/propostas/0/aceitar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/propostas/0/aceitar" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Numa só transação: aceita esta proposta, recusa as outras, passa o pedido a "aceite", gera o QR Code + código numérico com o valor acordado e abre o chat. Devolve o resumo do acordo.

---

#### Profissional: pedir alteração do preço combinado

* **Title**

  Profissional: pedir alteração do preço combinado

* **URL**

  `/api/pedidos/{id}/alteracoes-preco`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `valor_novo` | number (mín. 0, máx. 100000000) | sim |  |
  | `motivo` | string (mín. 5 car., máx. 300 car.) | sim |  |

  ```json
  {
    "valor_novo": 0,
    "motivo": "texto"
  }
  ```

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/pedidos/0/alteracoes-preco",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/alteracoes-preco", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/alteracoes-preco", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/alteracoes-preco", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/alteracoes-preco", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/alteracoes-preco", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/alteracoes-preco", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/alteracoes-preco" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"valor_novo":0,"motivo":"texto"}'
  ```

* **Notes**

  O valor só muda se o cliente aprovar. Enquanto houver um pedido pendente, não é possível confirmar o serviço.

---

#### Cliente: aprovar ou recusar a alteração de preço

* **Title**

  Cliente: aprovar ou recusar a alteração de preço

* **URL**

  `/api/alteracoes-preco/{id}/responder`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `aprovar` | boolean | sim |  |

  ```json
  {
    "aprovar": true
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/alteracoes-preco/0/responder",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/alteracoes-preco/0/responder", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/alteracoes-preco/0/responder", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/alteracoes-preco/0/responder", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/alteracoes-preco/0/responder", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/alteracoes-preco/0/responder", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/alteracoes-preco/0/responder", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/alteracoes-preco/0/responder" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"aprovar":true}'
  ```

* **Notes**

  —

---

## Confirmação por QR e comprovativo

#### Cliente: QR Code e código numérico do serviço em curso (ecrã 05)

* **Title**

  Cliente: QR Code e código numérico do serviço em curso (ecrã 05)

* **URL**

  `/api/pedidos/{id}/qr`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/qr",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/qr", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/qr", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/qr", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/qr", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/0/qr" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  token é o texto a desenhar no QR: opaco, sem o id do pedido nem o código. Vale QR_VALIDADE_MIN minutos (10 por omissão) e renova-se ao abrir de novo. Depois de 5 códigos errados, abrir o ecrã gera um código novo. Mostrar só com o trabalho feito.

---

#### Profissional: confirmar o serviço só com o código (ou o QR), sem indicar o pedido (RF10, ecrã 16)

* **Title**

  Profissional: confirmar o serviço só com o código (ou o QR), sem indicar o pedido (RF10, ecrã 16)

* **URL**

  `/api/pedidos/confirmar`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `codigo` | string | não | Os 6 dígitos ditos pelo cliente (aceita "482 173") |
  | `token_qr` | string (mín. 10 car., máx. 64 car.) | não | Conteúdo lido do QR (kx_qr_…) |
  | `metodo_pagamento` | `dinheiro` \\| `multicaixa_express` \\| `transferencia` (omissão "dinheiro") | não | RF14 |

  ```json
  {
    "codigo": "482173",
    "token_qr": "texto",
    "metodo_pagamento": "dinheiro"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/confirmar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/confirmar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/confirmar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/confirmar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/confirmar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/confirmar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/confirmar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/confirmar" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"codigo":"482173","token_qr":"texto","metodo_pagamento":"dinheiro"}'
  ```

* **Notes**

  Envie codigo (6 dígitos, aceita "482 173") ou token_qr (lido do QR). A API procura, entre os serviços ativos com a proposta deste profissional aceite e a confirmação pendente, aquele cujo código ou QR corresponde, e confirma esse. Código errado conta uma tentativa em todos os serviços pendentes dele; com 5 erros fica bloqueado (429) até o cliente abrir de novo o QR. Se, em desenvolvimento (CODIGO_QR_FIXO_DEV), vários serviços tiverem o mesmo código, confirma o que o cliente abriu (ou renovou) no ecrã do QR mais recentemente. Sem serviços por confirmar: 404 SEM_SERVICO_POR_CONFIRMAR. Devolve o ComprovativoJSON, como POST /pedidos/:id/confirmar.

---

#### Profissional: confirmar o serviço lendo o QR ou com o código numérico (RF10, ecrã 16)

* **Title**

  Profissional: confirmar o serviço lendo o QR ou com o código numérico (RF10, ecrã 16)

* **URL**

  `/api/pedidos/{id}/confirmar`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `token` | string (mín. 10 car., máx. 64 car.) | não | Conteúdo lido do QR |
  | `codigo` | string | não | Os 6 dígitos ditos pelo cliente (aceita "482 173") |
  | `metodo_pagamento` | `dinheiro` \\| `multicaixa_express` \\| `transferencia` (omissão "dinheiro") | não | RF14 |

  ```json
  {
    "token": "texto",
    "codigo": "482173",
    "metodo_pagamento": "dinheiro"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/confirmar",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/confirmar", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/confirmar", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/confirmar", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/confirmar", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/confirmar", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/confirmar", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/confirmar" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"token":"texto","codigo":"482173","metodo_pagamento":"dinheiro"}'
  ```

* **Notes**

  Envie token (lido do QR) ou codigo (os 6 dígitos ditos pelo cliente). Cada código errado conta; à quinta tentativa fica bloqueado (429) até o cliente abrir de novo o QR. Fecha o pedido pelo valor acordado (O4) e devolve o ComprovativoJSON. Com vários serviços ativos, prefira POST /pedidos/confirmar, que encontra o pedido pelo código.

---

#### Comprovativo digital: valor, data e profissional (RF10, RF17)

* **Title**

  Comprovativo digital: valor, data e profissional (RF10, RF17)

* **URL**

  `/api/pedidos/{id}/comprovativo`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/comprovativo",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/comprovativo", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/comprovativo", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/comprovativo", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/comprovativo", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/pedidos/0/comprovativo" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  ComprovativoJSON, para o cliente, o profissional escolhido ou o admin.

---

## Garantia e avaliação

#### Reportar problema (antes de confirmar ou até 7 dias depois) (RF11)

* **Title**

  Reportar problema (antes de confirmar ou até 7 dias depois) (RF11)

* **URL**

  `/api/pedidos/{id}/reclamacoes`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `multipart/form-data`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `tipo` | `trabalho_mal_feito` \\| `preco_diferente` \\| `nao_compareceu` \\| `atraso` \\| `comportamento` \\| `outro` | sim |  |
  | `descricao` | string (mín. 10 car., máx. 2000 car.) | sim |  |
  | `foto` | ficheiro | não |  |

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/pedidos/0/reclamacoes",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/reclamacoes", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/reclamacoes", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/reclamacoes", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/reclamacoes", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/reclamacoes", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/reclamacoes", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/reclamacoes" \
    -H "Authorization: Bearer <token>" \
    -F "tipo=trabalho_mal_feito" \
    -F "descricao=texto" \
    -F "foto=@ficheiro.jpg"
  ```

* **Notes**

  O prazo de 7 dias é garantido por um trigger na base de dados (422 se passou).

---

#### As minhas reclamações

* **Title**

  As minhas reclamações

* **URL**

  `/api/reclamacoes`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/reclamacoes",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/reclamacoes", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/reclamacoes", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/reclamacoes", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/reclamacoes", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/reclamacoes" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Avaliar com estrelas, etiquetas e comentário (RF12)

* **Title**

  Avaliar com estrelas, etiquetas e comentário (RF12)

* **URL**

  `/api/pedidos/{id}/avaliacao`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `estrelas` | integer (mín. 1, máx. 5) | sim |  |
  | `comentario` | string (máx. 500 car.) | não |  |
  | `etiquetas` | any[] (omissão []) | não |  |

  ```json
  {
    "estrelas": 1,
    "comentario": "texto",
    "etiquetas": [
      "pontual",
      "preco_justo"
    ]
  }
  ```

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/pedidos/0/avaliacao",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/avaliacao", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/avaliacao", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/avaliacao", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/avaliacao", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/avaliacao", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/avaliacao", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/avaliacao" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"estrelas":1,"comentario":"texto","etiquetas":["pontual","preco_justo"]}'
  ```

* **Notes**

  Só para serviços confirmados por QR (trigger trg_avaliacao_valida). Uma avaliação por serviço. etiquetas usa as chaves da app: pontual, preco_justo, simpatico, trabalho_limpo, rapido (ids também servem).

---

## Conversas e notificações

#### Lista de conversas, uma por pedido e profissional (RF09, ecrã 18)

* **Title**

  Lista de conversas, uma por pedido e profissional (RF09, ecrã 18)

* **URL**

  `/api/conversas`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/conversas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/conversas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/conversas", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/conversas", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/conversas", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/conversas" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  ConversaJSON com só a última mensagem, mais recentes primeiro. Segue o perfil ativo: como cliente, as conversas dos seus pedidos; como profissional, as conversas em que é o profissional.

---

#### Conversa com as últimas 50 mensagens (ecrã 19)

* **Title**

  Conversa com as últimas 50 mensagens (ecrã 19)

* **URL**

  `/api/conversas/{id}`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/conversas/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/conversas/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/conversas/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/conversas/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/conversas/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/conversas/0" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  ConversaJSON com as mensagens por ordem ascendente. Não marca como lidas: use POST /conversas/{id}/lida.

---

#### Marcar a conversa como lida (ecrã 19)

* **Title**

  Marcar a conversa como lida (ecrã 19)

* **URL**

  `/api/conversas/{id}/lida`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/conversas/0/lida",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/conversas/0/lida", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/conversas/0/lida", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/conversas/0/lida", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/conversas/0/lida", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/conversas/0/lida", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/conversas/0/lida", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/conversas/0/lida" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Marca como lidas as mensagens do outro participante. Devolve {nao_lidas: 0}.

---

#### Cliente: abrir conversa com um profissional que enviou proposta

* **Title**

  Cliente: abrir conversa com um profissional que enviou proposta

* **URL**

  `/api/pedidos/{id}/conversas`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `profissional_id` | integer (mín. 0) | sim |  |

  ```json
  {
    "profissional_id": 0
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/pedidos/0/conversas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/pedidos/0/conversas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/pedidos/0/conversas", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/pedidos/0/conversas", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/pedidos/0/conversas", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/pedidos/0/conversas", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/pedidos/0/conversas", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/pedidos/0/conversas" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"profissional_id":0}'
  ```

* **Notes**

  Útil para tirar dúvidas antes de aceitar. Devolve a conversa existente se já houver.

---

#### Mensagens da conversa, com paginação (marca como lidas)

* **Title**

  Mensagens da conversa, com paginação (marca como lidas)

* **URL**

  `/api/conversas/{id}/mensagens`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  `antes_de=[integer (pode ser null)]`  
  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/conversas/0/mensagens",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/conversas/0/mensagens" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Paginação para trás: passe antes_de = id da mensagem mais antiga que já tem.

---

#### Enviar mensagem com texto e/ou foto (RF09, ecrã 19)

* **Title**

  Enviar mensagem com texto e/ou foto (RF09, ecrã 19)

* **URL**

  `/api/conversas/{id}/mensagens`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `multipart/form-data`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `texto` | string (máx. 1000 car.) | não |  |
  | `foto` | ficheiro | não |  |

* **Success Response**

  * **Code:** 201  
  * **Content:**

    ```json
    {
      "title": "Criado com sucesso",
      "status": 201,
      "detail": "Recurso criado com sucesso.",
      "instance": "/api/conversas/0/mensagens",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/conversas/0/mensagens", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/conversas/0/mensagens" \
    -H "Authorization: Bearer <token>" \
    -F "texto=texto" \
    -F "foto=@ficheiro.jpg"
  ```

* **Notes**

  JSON {texto} (até 1000 caracteres) ou multipart com texto e foto. Devolve a MensagemJSON.

---

#### As minhas notificações

* **Title**

  As minhas notificações

* **URL**

  `/api/notificacoes`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  
  `offset=[integer (mín. 0, omissão 0, pode ser null)]`  
  `so_nao_lidas=[`true` \| `false` (omissão "false")]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/notificacoes",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/notificacoes", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/notificacoes", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/notificacoes", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/notificacoes", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/notificacoes" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Marcar notificação como lida

* **Title**

  Marcar notificação como lida

* **URL**

  `/api/notificacoes/{id}/lida`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/notificacoes/0/lida",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/notificacoes/0/lida", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/notificacoes/0/lida", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/notificacoes/0/lida", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/notificacoes/0/lida", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/notificacoes/0/lida", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/notificacoes/0/lida", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/notificacoes/0/lida" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Marcar todas como lidas

* **Title**

  Marcar todas como lidas

* **URL**

  `/api/notificacoes/lidas`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/notificacoes/lidas",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/notificacoes/lidas", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/notificacoes/lidas", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/notificacoes/lidas", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/notificacoes/lidas", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/notificacoes/lidas", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/notificacoes/lidas", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/notificacoes/lidas" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

## Administração

#### Pedidos de verificação de identidade

* **Title**

  Pedidos de verificação de identidade

* **URL**

  `/api/admin/verificacoes`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  
  `offset=[integer (mín. 0, omissão 0, pode ser null)]`  
  `estado=[`pendente` \| `aprovada` \| `rejeitada` (omissão "pendente")]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/admin/verificacoes",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/admin/verificacoes", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/admin/verificacoes", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/admin/verificacoes", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/admin/verificacoes", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/admin/verificacoes" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Ver o documento de identidade ou a fotografia do rosto (só admin)

* **Title**

  Ver o documento de identidade ou a fotografia do rosto (só admin)

* **URL**

  `/api/admin/verificacoes/{id}/{ficheiro}`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  
  `ficheiro=[`documento` \| `selfie`]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/admin/verificacoes/0/documento",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/admin/verificacoes/0/documento", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/admin/verificacoes/0/documento", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/admin/verificacoes/0/documento", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/admin/verificacoes/0/documento", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/admin/verificacoes/0/documento" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  ficheiro: documento ou selfie. Devolve a imagem JPEG. Estes ficheiros não estão em /uploads.

---

#### Aprovar ou rejeitar verificação (atribui o selo Verificado)

* **Title**

  Aprovar ou rejeitar verificação (atribui o selo Verificado)

* **URL**

  `/api/admin/verificacoes/{id}/decidir`

* **Method**

  `POST`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `aprovar` | boolean | sim |  |
  | `motivo_rejeicao` | string (máx. 255 car.) | não |  |

  ```json
  {
    "aprovar": true,
    "motivo_rejeicao": "texto"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/admin/verificacoes/0/decidir",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/admin/verificacoes/0/decidir", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/admin/verificacoes/0/decidir", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/admin/verificacoes/0/decidir", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/admin/verificacoes/0/decidir", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/admin/verificacoes/0/decidir", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/admin/verificacoes/0/decidir", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X POST "http://localhost:3000/api/admin/verificacoes/0/decidir" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"aprovar":true,"motivo_rejeicao":"texto"}'
  ```

* **Notes**

  —

---

#### Reclamações para acompanhar (RF11)

* **Title**

  Reclamações para acompanhar (RF11)

* **URL**

  `/api/admin/reclamacoes`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  Nenhum.

  **Optional:**

  `limit=[integer (mín. 1, máx. 100, omissão 20)]`  
  `offset=[integer (mín. 0, omissão 0, pode ser null)]`  
  `estado=[`aberta` \| `em_analise` \| `resolvida` \| `rejeitada`]`  

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/admin/reclamacoes",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/admin/reclamacoes", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/admin/reclamacoes", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/admin/reclamacoes", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/admin/reclamacoes", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/admin/reclamacoes" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  —

---

#### Ver a foto junta a uma reclamação (só admin)

* **Title**

  Ver a foto junta a uma reclamação (só admin)

* **URL**

  `/api/admin/reclamacoes/{id}/foto`

* **Method**

  `GET`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Nenhum.

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/admin/reclamacoes/0/foto",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/admin/reclamacoes/0/foto", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/admin/reclamacoes/0/foto", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/admin/reclamacoes/0/foto", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/admin/reclamacoes/0/foto", "data": { "codigo": "NAO_ENCONTRADO" } }`

* **Sample Call**

  ```bash
  curl -X GET "http://localhost:3000/api/admin/reclamacoes/0/foto" \
    -H "Authorization: Bearer <token>"
  ```

* **Notes**

  Devolve a imagem JPEG. As fotos das reclamações não estão em /uploads.

---

#### Atualizar o estado de uma reclamação

* **Title**

  Atualizar o estado de uma reclamação

* **URL**

  `/api/admin/reclamacoes/{id}`

* **Method**

  `PATCH`

* **Autenticação**

  Obrigatória: cabeçalho `Authorization: Bearer <token>`.

* **URL Params**

  **Required:**

  `id=[integer (mín. 0)]` (no caminho)  

  **Optional:**

  Nenhum.

* **Data Params**

  Formato: `application/json`

  | Campo | Tipo | Obrigatório | Descrição |
  |---|---|---|---|
  | `estado` | `em_analise` \\| `resolvida` \\| `rejeitada` | sim |  |
  | `resolucao` | string (máx. 500 car.) | não |  |

  ```json
  {
    "estado": "em_analise",
    "resolucao": "texto"
  }
  ```

* **Success Response**

  * **Code:** 200  
  * **Content:**

    ```json
    {
      "title": "Sucesso",
      "status": 200,
      "detail": "Pedido processado.",
      "instance": "/api/admin/reclamacoes/0",
      "data": "<conteúdo específico do endpoint>"
    }
    ```

* **Error Response**

  * **Code:** 400 — Dados inválidos  
    **Content:** `{ "title": "Dados inválidos", "status": 400, "detail": "…", "instance": "/api/admin/reclamacoes/0", "data": { "codigo": "VALIDACAO" } }`

  * **Code:** 401 — Falha na autenticação  
    **Content:** `{ "title": "Falha na autenticação", "status": 401, "detail": "…", "instance": "/api/admin/reclamacoes/0", "data": { "codigo": "NAO_AUTENTICADO" } }`

  * **Code:** 403 — Acesso negado  
    **Content:** `{ "title": "Acesso negado", "status": 403, "detail": "…", "instance": "/api/admin/reclamacoes/0", "data": { "codigo": "SEM_PERMISSAO" } }`

  * **Code:** 404 — Não encontrado  
    **Content:** `{ "title": "Não encontrado", "status": 404, "detail": "…", "instance": "/api/admin/reclamacoes/0", "data": { "codigo": "NAO_ENCONTRADO" } }`

  * **Code:** 409 — Conflito  
    **Content:** `{ "title": "Conflito", "status": 409, "detail": "…", "instance": "/api/admin/reclamacoes/0", "data": { "codigo": "CONFLITO" } }`

  * **Code:** 422 — Regra de negócio violada  
    **Content:** `{ "title": "Regra de negócio violada", "status": 422, "detail": "…", "instance": "/api/admin/reclamacoes/0", "data": { "codigo": "REGRA_NEGOCIO" } }`

* **Sample Call**

  ```bash
  curl -X PATCH "http://localhost:3000/api/admin/reclamacoes/0" \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"estado":"em_analise","resolucao":"texto"}'
  ```

* **Notes**

  —

---
