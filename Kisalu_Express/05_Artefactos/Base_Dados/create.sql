-- =====================================================================
--  Kisalu Express · Criação da base de dados (MySQL 8.0+)
--  Tabelas, índices, triggers e vistas. Os dados de exemplo estão em
--  populate.sql e as consultas de exemplo em queries.sql.
--  Grupo G05 · Turma D02 · Projeto Multidisciplinar (PBL) · 2026/27
--  Modelo derivado dos requisitos RF01–RF18, RNF10 e RM01–RM07
--  do Relatório da Fase 1.
--
--  Ordem: create.sql → populate.sql → (opcional) queries.sql
--  As datas são guardadas em UTC (a API liga com time_zone = '+00:00').
-- =====================================================================

DROP DATABASE IF EXISTS kisalu_express;
CREATE DATABASE kisalu_express
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE kisalu_express;

-- ---------------------------------------------------------------------
-- 1. CONTAS E AUTENTICAÇÃO (RF01)
-- ---------------------------------------------------------------------

-- Uma conta nasce do telemóvel (código por SMS) ou do email (código por email).
-- Quem entra por SMS ainda não tem nome nem email: por isso são opcionais.
CREATE TABLE utilizador (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email            VARCHAR(150) NULL,                 -- entrada alternativa por email
  telemovel        VARCHAR(20)  NOT NULL,             -- identifica a conta, ex.: +244923456789
  nome             VARCHAR(100) NULL,                 -- preenchido no registo
  foto_url         VARCHAR(255) NULL,
  tipo_perfil      ENUM('cliente','profissional','admin') NOT NULL DEFAULT 'cliente',
  consentimento_rgpd_em DATETIME NULL,                -- RNF10
  ativo            BOOLEAN      NOT NULL DEFAULT TRUE,
  criado_em        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ultimo_acesso_em DATETIME     NULL,
  CONSTRAINT uq_utilizador_telemovel UNIQUE (telemovel),
  CONSTRAINT uq_utilizador_email     UNIQUE (email)
) ENGINE=InnoDB;

-- Códigos de 6 dígitos enviados por SMS ou por email
CREATE TABLE codigo_login (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email        VARCHAR(150) NULL,
  telemovel    VARCHAR(20)  NULL,
  codigo_hash  CHAR(64)     NOT NULL,                 -- SHA-256 do código, nunca o código em claro
  expira_em    DATETIME     NOT NULL,
  tentativas   TINYINT UNSIGNED NOT NULL DEFAULT 0,
  usado        BOOLEAN      NOT NULL DEFAULT FALSE,
  criado_em    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_codigo_destino CHECK (email IS NOT NULL OR telemovel IS NOT NULL),
  INDEX idx_codigo_email (email, criado_em),
  INDEX idx_codigo_telemovel (telemovel, criado_em)
) ENGINE=InnoDB;

-- Sessões mantidas no dispositivo (RF01 "sessão mantida").
-- perfil_ativo: a mesma pessoa pode usar a app como cliente ou como profissional.
CREATE TABLE sessao (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  utilizador_id  INT UNSIGNED NOT NULL,
  token_hash     CHAR(64)     NOT NULL,
  perfil_ativo   ENUM('cliente','profissional','admin') NULL,
  dispositivo    VARCHAR(100) NULL,
  push_token     VARCHAR(255) NULL,                   -- RM06 notificações push
  criado_em      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expira_em      DATETIME     NOT NULL,
  revogada       BOOLEAN      NOT NULL DEFAULT FALSE,
  CONSTRAINT uq_sessao_token UNIQUE (token_hash),
  CONSTRAINT fk_sessao_utilizador FOREIGN KEY (utilizador_id)
    REFERENCES utilizador(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. PROFISSIONAIS, CATEGORIAS E VERIFICAÇÃO (RF02, RF06, RF07, RF15)
-- ---------------------------------------------------------------------

CREATE TABLE categoria (
  id           SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  chave        VARCHAR(30)  NOT NULL,                 -- a app identifica a categoria por esta chave: canalizador, ar_cond…
  nome         VARCHAR(60)  NOT NULL,                 -- Eletricista, Canalizador…
  plural       VARCHAR(60)  NOT NULL,                 -- "Já avisámos 8 canalizadores"
  icone        VARCHAR(60)  NOT NULL,                 -- RNF04 ícone + rótulo
  ordem        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  em_destaque  BOOLEAN      NOT NULL DEFAULT FALSE,   -- grelha 4 × 2 do Início
  ativa        BOOLEAN      NOT NULL DEFAULT TRUE,
  CONSTRAINT uq_categoria_chave UNIQUE (chave),
  CONSTRAINT uq_categoria_nome  UNIQUE (nome)
) ENGINE=InnoDB;

-- Especialização 1:1 de utilizador (só existe para quem trabalha como profissional)
CREATE TABLE profissional (
  utilizador_id     INT UNSIGNED PRIMARY KEY,
  bio               VARCHAR(500) NULL,
  anos_experiencia  TINYINT UNSIGNED NULL,
  zona              VARCHAR(80)  NULL,                -- texto mostrado: "Talatona, Luanda"
  raio_atuacao_km   SMALLINT UNSIGNED NOT NULL DEFAULT 10,
  latitude          DECIMAL(9,6) NULL,                -- zona base (não a morada exata)
  longitude         DECIMAL(9,6) NULL,
  mao_obra_desde    DECIMAL(12,2) NULL,               -- "mão de obra desde 8 000 Kz"
  especialidades    JSON         NULL,                -- ["Fugas de água", "Esquentadores"]
  disponivel        BOOLEAN      NOT NULL DEFAULT TRUE,
  verificado        BOOLEAN      NOT NULL DEFAULT FALSE,  -- selo "Verificado" (RF07)
  verificado_em     DATETIME     NULL,
  media_avaliacao   DECIMAL(2,1) NOT NULL DEFAULT 0.0,   -- atualizada por trigger
  total_avaliacoes  INT UNSIGNED NOT NULL DEFAULT 0,
  -- Distribuição das avaliações por estrelas (estatística do ecrã 03, docs/MATEMATICA.md).
  -- Inclui o histórico anterior às linhas de `avaliacao`; o trigger soma 1 à coluna certa.
  avaliacoes_1      INT UNSIGNED NOT NULL DEFAULT 0,
  avaliacoes_2      INT UNSIGNED NOT NULL DEFAULT 0,
  avaliacoes_3      INT UNSIGNED NOT NULL DEFAULT 0,
  avaliacoes_4      INT UNSIGNED NOT NULL DEFAULT 0,
  avaliacoes_5      INT UNSIGNED NOT NULL DEFAULT 0,
  total_servicos    INT UNSIGNED NOT NULL DEFAULT 0,     -- serviços confirmados por QR
  CONSTRAINT fk_profissional_utilizador FOREIGN KEY (utilizador_id)
    REFERENCES utilizador(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- N:M: um profissional pode trabalhar em várias categorias
CREATE TABLE profissional_categoria (
  profissional_id INT UNSIGNED      NOT NULL,
  categoria_id    SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (profissional_id, categoria_id),
  CONSTRAINT fk_pc_profissional FOREIGN KEY (profissional_id)
    REFERENCES profissional(utilizador_id) ON DELETE CASCADE,
  CONSTRAINT fk_pc_categoria FOREIGN KEY (categoria_id)
    REFERENCES categoria(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Verificação de identidade: documento + fotografia do rosto (RF07, N3).
-- Em 'rascunho' o profissional ainda está a juntar os ficheiros (ecrã 13).
CREATE TABLE verificacao_identidade (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  profissional_id   INT UNSIGNED NOT NULL,
  tipo_documento    ENUM('bilhete_identidade','passaporte','cartao_residente') NULL,
  numero_documento  VARCHAR(30)  NULL,
  documento_url     VARCHAR(255) NULL,
  selfie_url        VARCHAR(255) NULL,
  estado            ENUM('rascunho','pendente','aprovada','rejeitada') NOT NULL DEFAULT 'pendente',
  motivo_rejeicao   VARCHAR(255) NULL,
  revisto_por       INT UNSIGNED NULL,                -- admin que reviu
  criado_em         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  submetido_em      DATETIME     NULL,                -- quando foi enviada para análise
  revisto_em        DATETIME     NULL,
  CONSTRAINT ck_verif_completa CHECK (estado = 'rascunho' OR (documento_url IS NOT NULL AND selfie_url IS NOT NULL)),
  CONSTRAINT fk_verif_profissional FOREIGN KEY (profissional_id)
    REFERENCES profissional(utilizador_id) ON DELETE CASCADE,
  CONSTRAINT fk_verif_admin FOREIGN KEY (revisto_por)
    REFERENCES utilizador(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Disponibilidade semanal do profissional (RF15)
CREATE TABLE disponibilidade (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  profissional_id INT UNSIGNED NOT NULL,
  dia_semana      TINYINT UNSIGNED NOT NULL,          -- 1 = segunda … 7 = domingo
  hora_inicio     TIME NOT NULL,
  hora_fim        TIME NOT NULL,
  CONSTRAINT ck_disp_dia   CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT ck_disp_horas CHECK (hora_fim > hora_inicio),
  CONSTRAINT fk_disp_profissional FOREIGN KEY (profissional_id)
    REFERENCES profissional(utilizador_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. MORADAS (RM05) E FAVORITOS (RF13)
-- ---------------------------------------------------------------------

CREATE TABLE morada (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  utilizador_id     INT UNSIGNED NOT NULL,
  rotulo            VARCHAR(40)  NOT NULL DEFAULT 'Casa',  -- Casa, Trabalho…
  endereco          VARCHAR(200) NOT NULL,
  ponto_referencia  VARCHAR(200) NULL,                     -- "perto da cantina…"
  bairro            VARCHAR(80)  NULL,
  municipio         VARCHAR(80)  NOT NULL,
  provincia         VARCHAR(60)  NOT NULL DEFAULT 'Luanda',
  latitude          DECIMAL(9,6) NULL,
  longitude         DECIMAL(9,6) NULL,
  predefinida       BOOLEAN      NOT NULL DEFAULT FALSE,
  criado_em         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_morada_utilizador FOREIGN KEY (utilizador_id)
    REFERENCES utilizador(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE favorito (
  cliente_id      INT UNSIGNED NOT NULL,
  profissional_id INT UNSIGNED NOT NULL,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (cliente_id, profissional_id),
  CONSTRAINT fk_fav_cliente FOREIGN KEY (cliente_id)
    REFERENCES utilizador(id) ON DELETE CASCADE,
  CONSTRAINT fk_fav_profissional FOREIGN KEY (profissional_id)
    REFERENCES profissional(utilizador_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. PEDIDOS E PROPOSTAS (RF03, RF04, RF05, RF08, RF15)
-- ---------------------------------------------------------------------

CREATE TABLE pedido (
  id                   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id           INT UNSIGNED      NOT NULL,
  categoria_id         SMALLINT UNSIGNED NOT NULL,
  morada_id            INT UNSIGNED      NOT NULL,
  titulo               VARCHAR(100) NOT NULL,          -- "Fuga de água na cozinha"
  descricao            TEXT         NOT NULL,
  urgencia             ENUM('o_mais_cedo_possivel','agendado') NOT NULL DEFAULT 'o_mais_cedo_possivel',
  data_pretendida      DATETIME     NULL,
  estado               ENUM('rascunho','publicado','com_propostas','aceite',
                            'a_caminho','em_curso','concluido','cancelado')
                       NOT NULL DEFAULT 'rascunho',    -- RF08
  proposta_aceite_id   INT UNSIGNED NULL,              -- FK adicionada mais abaixo
  motivo_cancelamento  VARCHAR(255) NULL,
  criado_em            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  publicado_em         DATETIME NULL,
  concluido_em         DATETIME NULL,                  -- conta a garantia de 7 dias (RF11)
  cancelado_em         DATETIME NULL,
  atualizado_em        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT ck_pedido_agendado CHECK (urgencia = 'o_mais_cedo_possivel' OR data_pretendida IS NOT NULL),
  CONSTRAINT fk_pedido_cliente FOREIGN KEY (cliente_id)
    REFERENCES utilizador(id) ON DELETE RESTRICT,
  CONSTRAINT fk_pedido_categoria FOREIGN KEY (categoria_id)
    REFERENCES categoria(id) ON DELETE RESTRICT,
  CONSTRAINT fk_pedido_morada FOREIGN KEY (morada_id)
    REFERENCES morada(id) ON DELETE RESTRICT,
  INDEX idx_pedido_estado (estado, categoria_id),
  INDEX idx_pedido_cliente (cliente_id, estado)
) ENGINE=InnoDB;

-- Fotos opcionais do pedido (RF03, RM04)
CREATE TABLE pedido_foto (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id  INT UNSIGNED NOT NULL,
  url        VARCHAR(255) NOT NULL,
  criado_em  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pfoto_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Linha do tempo do pedido: Publicado → Propostas → A caminho → Em curso → Concluído (RF08)
CREATE TABLE historico_estado_pedido (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id      INT UNSIGNED NOT NULL,
  estado_anterior VARCHAR(20) NULL,
  estado_novo     VARCHAR(20) NOT NULL,
  alterado_por   INT UNSIGNED NULL,
  criado_em      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_hist_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_hist_utilizador FOREIGN KEY (alterado_por)
    REFERENCES utilizador(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Proposta com preço fechado em Kz e o que inclui (RF04, RF15).
-- Chegada: daqui a tempo_chegada_min minutos, ou na hora pedida pelo cliente.
CREATE TABLE proposta (
  id                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id          INT UNSIGNED NOT NULL,
  profissional_id    INT UNSIGNED NOT NULL,
  valor_mao_obra     DECIMAL(12,2) NOT NULL DEFAULT 0,
  valor_material     DECIMAL(12,2) NOT NULL DEFAULT 0,
  valor_deslocacao   DECIMAL(12,2) NOT NULL DEFAULT 0,
  valor_total        DECIMAL(12,2) AS (valor_mao_obra + valor_material + valor_deslocacao) STORED,
  inclui_descricao   VARCHAR(300) NULL,                -- "Mão de obra · material · deslocação"
  material_detalhe   VARCHAR(150) NULL,                -- "sifão e vedante"
  tempo_chegada_min  SMALLINT UNSIGNED NULL,           -- "chega em 40 min"
  na_hora_pedida     BOOLEAN NOT NULL DEFAULT FALSE,   -- chega à hora que o cliente pediu
  mensagem           VARCHAR(500) NULL,
  estado             ENUM('enviada','aceite','recusada','retirada','expirada')
                     NOT NULL DEFAULT 'enviada',
  criado_em          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  respondida_em      DATETIME NULL,
  CONSTRAINT uq_proposta_pedido_prof UNIQUE (pedido_id, profissional_id),  -- 1 proposta por profissional
  CONSTRAINT ck_proposta_valores CHECK (valor_mao_obra >= 0 AND valor_material >= 0 AND valor_deslocacao >= 0),
  CONSTRAINT ck_proposta_chegada CHECK (na_hora_pedida = TRUE OR tempo_chegada_min IS NOT NULL),
  CONSTRAINT fk_proposta_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_proposta_profissional FOREIGN KEY (profissional_id)
    REFERENCES profissional(utilizador_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Relação circular pedido ↔ proposta aceite (1:0..1)
ALTER TABLE pedido
  ADD CONSTRAINT uq_pedido_proposta_aceite UNIQUE (proposta_aceite_id),
  ADD CONSTRAINT fk_pedido_proposta_aceite FOREIGN KEY (proposta_aceite_id)
    REFERENCES proposta(id) ON DELETE SET NULL;

-- Alteração de preço só com aprovação do cliente (RF08, N1, O4)
CREATE TABLE alteracao_preco (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  proposta_id      INT UNSIGNED  NOT NULL,
  valor_anterior   DECIMAL(12,2) NOT NULL,
  valor_novo       DECIMAL(12,2) NOT NULL,
  motivo           VARCHAR(300)  NOT NULL,
  estado           ENUM('pendente','aprovada','recusada') NOT NULL DEFAULT 'pendente',
  pedida_em        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  respondida_em    DATETIME NULL,
  CONSTRAINT ck_alt_valor CHECK (valor_novo >= 0),
  CONSTRAINT fk_alt_proposta FOREIGN KEY (proposta_id)
    REFERENCES proposta(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. CONFIRMAÇÃO POR QR, COMPROVATIVO E PAGAMENTO (RF10, RF14)
-- ---------------------------------------------------------------------

-- token_qr é um texto opaco (ex.: kx_qr_8Wm4…): não revela o pedido nem o código.
-- O QR renova-se quando expira; o código numérico aceita no máximo 5 tentativas erradas.
CREATE TABLE confirmacao_servico (
  id                   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id            INT UNSIGNED  NOT NULL,
  token_qr             VARCHAR(64)   NOT NULL,
  codigo_numerico      CHAR(6)       NOT NULL,         -- alternativo ao QR: "482 173"
  valor_acordado       DECIMAL(12,2) NOT NULL,         -- valor aceite (ou alteração aprovada)
  estado               ENUM('pendente','confirmado','expirado') NOT NULL DEFAULT 'pendente',
  tentativas           TINYINT UNSIGNED NOT NULL DEFAULT 0,
  expira_em            DATETIME      NULL,             -- validade do QR mostrado ao cliente
  qr_aberto_em         DATETIME(3)   NULL,             -- última vez que o cliente abriu (ou renovou) o QR
  metodo_confirmacao   ENUM('qr','codigo') NULL,
  metodo_pagamento     ENUM('dinheiro','multicaixa_express','transferencia') NULL,  -- RF14
  numero_comprovativo  VARCHAR(20)   NULL,             -- ex.: KX-2026-000123
  gerado_em            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  confirmado_em        DATETIME NULL,
  CONSTRAINT uq_conf_pedido      UNIQUE (pedido_id),
  CONSTRAINT uq_conf_token       UNIQUE (token_qr),
  CONSTRAINT uq_conf_comprovativo UNIQUE (numero_comprovativo),
  CONSTRAINT ck_conf_codigo CHECK (codigo_numerico REGEXP '^[0-9]{6}$'),
  CONSTRAINT fk_conf_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. RECLAMAÇÕES / GARANTIA DE 7 DIAS (RF11)
-- ---------------------------------------------------------------------

CREATE TABLE reclamacao (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id     INT UNSIGNED NOT NULL,
  autor_id      INT UNSIGNED NOT NULL,
  tipo          ENUM('trabalho_mal_feito','preco_diferente','nao_compareceu',
                     'atraso','comportamento','outro') NOT NULL,
  descricao     TEXT NOT NULL,
  foto_url      VARCHAR(255) NULL,
  estado        ENUM('aberta','em_analise','resolvida','rejeitada') NOT NULL DEFAULT 'aberta',
  resolucao     VARCHAR(500) NULL,
  criado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolvida_em  DATETIME NULL,
  CONSTRAINT fk_recl_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_recl_autor FOREIGN KEY (autor_id)
    REFERENCES utilizador(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. AVALIAÇÕES E PORTEFÓLIO (RF06, RF12)
-- ---------------------------------------------------------------------

CREATE TABLE avaliacao (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id        INT UNSIGNED NOT NULL,
  cliente_id       INT UNSIGNED NOT NULL,
  profissional_id  INT UNSIGNED NOT NULL,
  estrelas         TINYINT UNSIGNED NOT NULL,
  comentario       VARCHAR(500) NULL,
  criado_em        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_avaliacao_pedido UNIQUE (pedido_id),      -- 1 avaliação por serviço
  CONSTRAINT ck_avaliacao_estrelas CHECK (estrelas BETWEEN 1 AND 5),
  CONSTRAINT fk_aval_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_aval_cliente FOREIGN KEY (cliente_id)
    REFERENCES utilizador(id) ON DELETE RESTRICT,
  CONSTRAINT fk_aval_profissional FOREIGN KEY (profissional_id)
    REFERENCES profissional(utilizador_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Etiquetas rápidas do ecrã 06: pontual, preco_justo, simpatico, trabalho_limpo, rapido
CREATE TABLE etiqueta (
  id     SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  chave  VARCHAR(30) NOT NULL,                        -- a app envia a chave
  nome   VARCHAR(40) NOT NULL,
  CONSTRAINT uq_etiqueta_chave UNIQUE (chave),
  CONSTRAINT uq_etiqueta_nome  UNIQUE (nome)
) ENGINE=InnoDB;

CREATE TABLE avaliacao_etiqueta (
  avaliacao_id INT UNSIGNED      NOT NULL,
  etiqueta_id  SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (avaliacao_id, etiqueta_id),
  CONSTRAINT fk_ae_avaliacao FOREIGN KEY (avaliacao_id)
    REFERENCES avaliacao(id) ON DELETE CASCADE,
  CONSTRAINT fk_ae_etiqueta FOREIGN KEY (etiqueta_id)
    REFERENCES etiqueta(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Galeria "Trabalhos feitos" (RF06, N2); pedido_id liga a um serviço confirmado
CREATE TABLE trabalho_foto (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  profissional_id  INT UNSIGNED NOT NULL,
  pedido_id        INT UNSIGNED NULL,
  url              VARCHAR(255) NOT NULL,
  legenda          VARCHAR(150) NULL,
  visivel          BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tf_profissional FOREIGN KEY (profissional_id)
    REFERENCES profissional(utilizador_id) ON DELETE CASCADE,
  CONSTRAINT fk_tf_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. CONVERSAS (RF09) E NOTIFICAÇÕES (RM06)
-- ---------------------------------------------------------------------

CREATE TABLE conversa (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  pedido_id        INT UNSIGNED NOT NULL,
  profissional_id  INT UNSIGNED NOT NULL,
  criado_em        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_conversa UNIQUE (pedido_id, profissional_id),
  CONSTRAINT fk_conv_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE CASCADE,
  CONSTRAINT fk_conv_profissional FOREIGN KEY (profissional_id)
    REFERENCES profissional(utilizador_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE mensagem (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversa_id   INT UNSIGNED NOT NULL,
  remetente_id  INT UNSIGNED NOT NULL,
  texto         TEXT NULL,
  foto_url      VARCHAR(255) NULL,
  enviada_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lida_em       DATETIME NULL,
  CONSTRAINT ck_msg_conteudo CHECK (texto IS NOT NULL OR foto_url IS NOT NULL),
  CONSTRAINT fk_msg_conversa FOREIGN KEY (conversa_id)
    REFERENCES conversa(id) ON DELETE CASCADE,
  CONSTRAINT fk_msg_remetente FOREIGN KEY (remetente_id)
    REFERENCES utilizador(id) ON DELETE CASCADE,
  INDEX idx_msg_conversa (conversa_id, enviada_em)
) ENGINE=InnoDB;

CREATE TABLE notificacao (
  id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  utilizador_id  INT UNSIGNED NOT NULL,
  pedido_id      INT UNSIGNED NULL,
  tipo           ENUM('novo_pedido','nova_proposta','proposta_aceite','estado_pedido','alteracao_preco',
                      'nova_mensagem','lembrete_avaliacao','reclamacao','sistema') NOT NULL,
  titulo         VARCHAR(80)  NOT NULL,
  corpo          VARCHAR(200) NOT NULL,
  acao           VARCHAR(40)  NULL,                    -- ex.: "ver_propostas" (ação direta)
  lida           BOOLEAN NOT NULL DEFAULT FALSE,
  criado_em      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notif_utilizador FOREIGN KEY (utilizador_id)
    REFERENCES utilizador(id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_pedido FOREIGN KEY (pedido_id)
    REFERENCES pedido(id) ON DELETE CASCADE,
  INDEX idx_notif_utilizador (utilizador_id, lida, criado_em)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. AJUDA (RF16)
-- ---------------------------------------------------------------------

CREATE TABLE pergunta_frequente (
  id        SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tema      VARCHAR(40)  NOT NULL,                     -- "QR Code", "Pagamentos"…
  pergunta  VARCHAR(200) NOT NULL,
  resposta  TEXT         NOT NULL,
  ordem     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  ativa     BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- =====================================================================
-- REGRAS DE NEGÓCIO (TRIGGERS)
-- =====================================================================
DELIMITER $$

-- RF08: cada mudança de estado fica no histórico
CREATE TRIGGER trg_pedido_historico
AFTER UPDATE ON pedido
FOR EACH ROW
BEGIN
  IF NEW.estado <> OLD.estado THEN
    INSERT INTO historico_estado_pedido (pedido_id, estado_anterior, estado_novo)
    VALUES (NEW.id, OLD.estado, NEW.estado);
  END IF;
END$$

-- RF12: só se avalia um serviço confirmado (pedido concluído) pelo próprio cliente
CREATE TRIGGER trg_avaliacao_valida
BEFORE INSERT ON avaliacao
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_cliente INT UNSIGNED;
  SELECT estado, cliente_id INTO v_estado, v_cliente FROM pedido WHERE id = NEW.pedido_id;
  IF v_estado <> 'concluido' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Só é possível avaliar serviços confirmados.';
  END IF;
  IF v_cliente <> NEW.cliente_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Só o cliente do pedido pode avaliar.';
  END IF;
END$$

-- Reputação que se acumula: soma 1 à contagem das estrelas dadas e recalcula o total
-- e a média a partir da distribuição (que já traz o histórico dos dados de exemplo).
-- No UPDATE de uma só tabela o MySQL aplica as atribuições da esquerda para a direita,
-- por isso o total e a média já usam a contagem atualizada.
CREATE TRIGGER trg_avaliacao_media
AFTER INSERT ON avaliacao
FOR EACH ROW
BEGIN
  UPDATE profissional p
     SET p.avaliacoes_1     = p.avaliacoes_1 + (NEW.estrelas = 1),
         p.avaliacoes_2     = p.avaliacoes_2 + (NEW.estrelas = 2),
         p.avaliacoes_3     = p.avaliacoes_3 + (NEW.estrelas = 3),
         p.avaliacoes_4     = p.avaliacoes_4 + (NEW.estrelas = 4),
         p.avaliacoes_5     = p.avaliacoes_5 + (NEW.estrelas = 5),
         p.total_avaliacoes = p.avaliacoes_1 + p.avaliacoes_2 + p.avaliacoes_3 + p.avaliacoes_4 + p.avaliacoes_5,
         p.media_avaliacao  = ROUND((p.avaliacoes_1 + 2 * p.avaliacoes_2 + 3 * p.avaliacoes_3
                                     + 4 * p.avaliacoes_4 + 5 * p.avaliacoes_5) / p.total_avaliacoes, 1)
   WHERE p.utilizador_id = NEW.profissional_id;
END$$

-- RF11: reclamação antes de confirmar ou até 7 dias depois da conclusão
CREATE TRIGGER trg_reclamacao_garantia
BEFORE INSERT ON reclamacao
FOR EACH ROW
BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_concluido DATETIME;
  SELECT estado, concluido_em INTO v_estado, v_concluido FROM pedido WHERE id = NEW.pedido_id;
  IF v_estado IN ('rascunho','publicado','com_propostas') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ainda não há serviço aceite neste pedido.';
  END IF;
  IF v_estado = 'concluido' AND v_concluido < NOW() - INTERVAL 7 DAY THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A garantia de 7 dias já terminou.';
  END IF;
END$$

-- RF10 + O4: confirmar o serviço fecha o pedido pelo valor acordado e conta para o profissional
CREATE TRIGGER trg_confirmacao_concluir
AFTER UPDATE ON confirmacao_servico
FOR EACH ROW
BEGIN
  IF NEW.estado = 'confirmado' AND OLD.estado <> 'confirmado' THEN
    UPDATE pedido SET estado = 'concluido', concluido_em = NEW.confirmado_em
     WHERE id = NEW.pedido_id;
    UPDATE profissional p
      JOIN proposta pr ON pr.profissional_id = p.utilizador_id
      JOIN pedido pe   ON pe.proposta_aceite_id = pr.id
       SET p.total_servicos = p.total_servicos + 1
     WHERE pe.id = NEW.pedido_id;
  END IF;
END$$

DELIMITER ;

-- =====================================================================
-- VISTAS
-- =====================================================================

-- Cartão de proposta (RF04 / O3): preço, o que inclui, chegada, estrelas e selo
CREATE VIEW vw_cartao_proposta AS
SELECT pr.id               AS proposta_id,
       pr.pedido_id,
       pr.profissional_id,
       u.nome              AS profissional,
       pr.valor_total,
       pr.inclui_descricao,
       pr.material_detalhe,
       pr.tempo_chegada_min,
       pr.na_hora_pedida,
       p.media_avaliacao,
       p.total_avaliacoes,
       p.total_servicos,
       p.verificado,
       pr.estado
  FROM proposta pr
  JOIN profissional p ON p.utilizador_id = pr.profissional_id
  JOIN utilizador u   ON u.id = p.utilizador_id;

-- Média global de cada categoria (prior da média bayesiana, docs/MATEMATICA.md):
-- soma de todas as estrelas dos profissionais da categoria a dividir pelo número de avaliações.
-- Um profissional com duas categorias conta nas duas.
CREATE VIEW vw_media_categoria AS
SELECT pc.categoria_id,
       SUM(p.avaliacoes_1 + p.avaliacoes_2 + p.avaliacoes_3 + p.avaliacoes_4 + p.avaliacoes_5) AS n,
       SUM(p.avaliacoes_1 + 2 * p.avaliacoes_2 + 3 * p.avaliacoes_3 + 4 * p.avaliacoes_4 + 5 * p.avaliacoes_5) AS soma,
       SUM(p.avaliacoes_1 + 2 * p.avaliacoes_2 + 3 * p.avaliacoes_3 + 4 * p.avaliacoes_4 + 5 * p.avaliacoes_5)
         / NULLIF(SUM(p.avaliacoes_1 + p.avaliacoes_2 + p.avaliacoes_3 + p.avaliacoes_4 + p.avaliacoes_5), 0) AS media
  FROM profissional_categoria pc
  JOIN profissional p ON p.utilizador_id = pc.profissional_id
 GROUP BY pc.categoria_id;

-- Comprovativo digital (RF10): valor, data e profissional
CREATE VIEW vw_comprovativo AS
SELECT c.numero_comprovativo,
       pe.id            AS pedido_id,
       pe.titulo,
       pe.cliente_id,
       cl.nome          AS cliente,
       pr.profissional_id,
       up.nome          AS profissional,
       c.valor_acordado AS valor_kz,
       c.metodo_pagamento,
       c.metodo_confirmacao,
       c.confirmado_em
  FROM confirmacao_servico c
  JOIN pedido pe      ON pe.id = c.pedido_id
  JOIN utilizador cl  ON cl.id = pe.cliente_id
  JOIN proposta pr    ON pr.id = pe.proposta_aceite_id
  JOIN utilizador up  ON up.id = pr.profissional_id
 WHERE c.estado = 'confirmado';
