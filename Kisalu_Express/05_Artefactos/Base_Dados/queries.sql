-- =====================================================================
--  Kisalu Express · Consultas de exemplo
--  Uma ou mais consultas por funcionalidade (ecrãs da app). São as mesmas
--  regras que a API aplica em src/modules, escritas em SQL simples.
--
--  Correr depois de create.sql e populate.sql. As consultas que alteram
--  dados seguem uma história: a Teresa pede para reparar o muro, o Joaquim
--  envia proposta, ela aceita, ele confirma com o código e ela avalia.
--  Os parâmetros ficam em variáveis (@...) para se poderem trocar.
-- =====================================================================

USE kisalu_express;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET time_zone = '+00:00';

-- Maria (cliente, Talatona), Joaquim (canalizador e pedreiro) e Teresa (cliente, Viana)
SET @maria   = 1;
SET @joaquim = 2;
SET @teresa  = 14;

-- ---------------------------------------------------------------------
-- 1. Entrar com o telemóvel (ecrãs 01 e 11)
-- ---------------------------------------------------------------------

SET @telemovel = '+244923000000';
SET @codigo    = '482173';

-- 1.1 Pode pedir outro código? Último pedido há menos de 60 s e quantos nos últimos 10 min
SELECT TIMESTAMPDIFF(SECOND, MAX(criado_em), NOW())                AS segundos_desde_ultimo,
       SUM(criado_em > NOW() - INTERVAL 10 MINUTE)                 AS pedidos_ultimos_10_min
  FROM codigo_login
 WHERE telemovel = @telemovel;

-- 1.2 Guardar o código (só o hash) válido durante 5 minutos
INSERT INTO codigo_login (telemovel, codigo_hash, expira_em)
VALUES (@telemovel, SHA2(CONCAT(@telemovel, ':', @codigo), 256), NOW() + INTERVAL 5 MINUTE);

-- 1.3 Validar: o último código ainda válido deste telemóvel e se o hash confere
SELECT id, tentativas,
       codigo_hash = SHA2(CONCAT(@telemovel, ':', @codigo), 256) AS codigo_certo
  FROM codigo_login
 WHERE telemovel = @telemovel AND usado = FALSE AND expira_em > NOW()
 ORDER BY id DESC
 LIMIT 1;

UPDATE codigo_login SET usado = TRUE
 WHERE telemovel = @telemovel AND usado = FALSE
 ORDER BY id DESC LIMIT 1;

-- 1.4 Já há conta com este número? (se não houver, a API cria-a)
SELECT id, nome, tipo_perfil, ativo FROM utilizador WHERE telemovel = @telemovel;

-- 1.5 Sessão com o perfil escolhido no ecrã 01
INSERT INTO sessao (utilizador_id, token_hash, perfil_ativo, expira_em)
VALUES (@maria, SHA2(UUID(), 256), 'cliente', NOW() + INTERVAL 30 DAY);

-- 1.6 Dados do ecrã 02 e do perfil (20): zona da morada predefinida, novidades, moradas e favoritos
SELECT u.id, u.nome, u.telemovel,
       CONCAT(COALESCE(m.bairro, m.municipio), ', ', m.provincia)                               AS zona,
       EXISTS (SELECT 1 FROM notificacao n WHERE n.utilizador_id = u.id AND n.lida = FALSE)    AS tem_novidades,
       (SELECT COUNT(*) FROM morada x   WHERE x.utilizador_id = u.id)                           AS moradas_guardadas,
       (SELECT COUNT(*) FROM favorito f WHERE f.cliente_id = u.id)                              AS favoritos
  FROM utilizador u
  LEFT JOIN morada m ON m.utilizador_id = u.id AND m.predefinida = TRUE
 WHERE u.id = @maria;

-- ---------------------------------------------------------------------
-- 2. Categorias (ecrã 02 e "Ver todos")
-- ---------------------------------------------------------------------

-- As 13 categorias, com quantos profissionais disponíveis tem cada uma
SELECT c.id, c.chave, c.nome, c.plural, c.em_destaque, c.icone,
       COUNT(p.utilizador_id) AS profissionais_disponiveis
  FROM categoria c
  LEFT JOIN profissional_categoria pc ON pc.categoria_id = c.id
  LEFT JOIN profissional p ON p.utilizador_id = pc.profissional_id AND p.disponivel = TRUE
 WHERE c.ativa = TRUE
 GROUP BY c.id
 ORDER BY c.ordem;

-- ---------------------------------------------------------------------
-- 3. Profissionais perto de si (ecrã 02)
-- ---------------------------------------------------------------------

-- Distância (Haversine, em km) desde a morada predefinida da Maria.
-- A categoria principal é a de menor ordem.
SELECT lat, lng INTO @lat, @lng FROM (
  SELECT latitude AS lat, longitude AS lng FROM morada WHERE utilizador_id = @maria AND predefinida = TRUE
) AS casa;

SELECT p.utilizador_id AS id, u.nome, p.zona,
       (SELECT c.nome FROM profissional_categoria pc JOIN categoria c ON c.id = pc.categoria_id
         WHERE pc.profissional_id = p.utilizador_id ORDER BY c.ordem LIMIT 1)                    AS categoria,
       ROUND(6371 * 2 * ASIN(SQRT(POWER(SIN(RADIANS(p.latitude - @lat) / 2), 2)
             + COS(RADIANS(@lat)) * COS(RADIANS(p.latitude)) * POWER(SIN(RADIANS(p.longitude - @lng) / 2), 2))), 1) AS distancia_km,
       p.media_avaliacao AS rating, p.total_avaliacoes, p.total_servicos, p.verificado, p.mao_obra_desde
  FROM profissional p
  JOIN utilizador u ON u.id = p.utilizador_id AND u.ativo = TRUE
 WHERE p.disponivel = TRUE AND p.latitude IS NOT NULL
 ORDER BY distancia_km
 LIMIT 20;

-- ---------------------------------------------------------------------
-- 4. Perfil do profissional (ecrã 03)
-- ---------------------------------------------------------------------

SELECT u.nome, p.zona, p.anos_experiencia, p.especialidades, p.verificado,
       p.media_avaliacao, p.total_avaliacoes, p.total_servicos, p.mao_obra_desde,
       (SELECT COUNT(*) FROM trabalho_foto t WHERE t.profissional_id = p.utilizador_id AND t.visivel = TRUE) AS total_trabalhos_feitos
  FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id
 WHERE p.utilizador_id = @joaquim;

-- Avaliações com o autor abreviado ("Maria S.") e as etiquetas por chave
SELECT CONCAT(SUBSTRING_INDEX(uc.nome, ' ', 1), ' ', LEFT(SUBSTRING_INDEX(uc.nome, ' ', -1), 1), '.') AS autor,
       a.estrelas, a.comentario,
       GROUP_CONCAT(e.chave ORDER BY e.id) AS etiquetas
  FROM avaliacao a
  JOIN utilizador uc ON uc.id = a.cliente_id
  LEFT JOIN avaliacao_etiqueta ae ON ae.avaliacao_id = a.id
  LEFT JOIN etiqueta e ON e.id = ae.etiqueta_id
 WHERE a.profissional_id = @joaquim
 GROUP BY a.id
 ORDER BY a.criado_em DESC;

-- ---------------------------------------------------------------------
-- 5. Painel do profissional (ecrã 14)
-- ---------------------------------------------------------------------

SELECT SUBSTRING_INDEX(u.nome, ' ', 1) AS nome, p.zona, p.raio_atuacao_km AS raio_km,
       p.media_avaliacao AS rating, p.total_servicos AS servicos, p.disponivel
  FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id
 WHERE p.utilizador_id = @joaquim;

-- "Disponível para trabalhar"
UPDATE profissional SET disponivel = TRUE WHERE utilizador_id = @joaquim;

-- ---------------------------------------------------------------------
-- 6. Pedidos perto do profissional (ecrãs 14 e 15)
-- ---------------------------------------------------------------------

-- Pedidos abertos das categorias do Joaquim, dentro do raio, sem morada exata (RNF10).
-- "novo" = ainda sem proposta dele e publicado há menos de uma hora.
SELECT latitude, longitude, raio_atuacao_km INTO @plat, @plng, @raio
  FROM profissional WHERE utilizador_id = @joaquim;

SELECT pe.id, pe.titulo, c.chave AS categoria_chave, COALESCE(m.bairro, m.municipio) AS zona,
       ROUND(6371 * 2 * ASIN(SQRT(POWER(SIN(RADIANS(m.latitude - @plat) / 2), 2)
             + COS(RADIANS(@plat)) * COS(RADIANS(m.latitude)) * POWER(SIN(RADIANS(m.longitude - @plng) / 2), 2))), 1) AS distancia_km,
       pe.data_pretendida, pe.publicado_em,
       (NOT EXISTS (SELECT 1 FROM proposta x WHERE x.pedido_id = pe.id AND x.profissional_id = @joaquim)
        AND pe.publicado_em > NOW() - INTERVAL 1 HOUR) AS novo
  FROM pedido pe
  JOIN categoria c ON c.id = pe.categoria_id
  JOIN morada m ON m.id = pe.morada_id
  JOIN profissional_categoria pc ON pc.categoria_id = pe.categoria_id AND pc.profissional_id = @joaquim
 WHERE pe.estado IN ('publicado', 'com_propostas') AND pe.cliente_id <> @joaquim
HAVING distancia_km IS NULL OR distancia_km <= @raio
 ORDER BY pe.publicado_em DESC;

-- ---------------------------------------------------------------------
-- 7. Enviar proposta (ecrã 15)
-- ---------------------------------------------------------------------

-- Proposta do Joaquim para o muro da Teresa: 9 000 + 6 000 + 1 000 = 16 000 Kz,
-- chega à hora que a cliente pediu. O total é calculado pela coluna gerada.
INSERT INTO proposta (pedido_id, profissional_id, valor_mao_obra, valor_material, valor_deslocacao,
                      inclui_descricao, material_detalhe, na_hora_pedida)
VALUES (10, @joaquim, 9000, 6000, 1000, 'Mão de obra · material · deslocação', 'blocos e cimento', TRUE);
SET @proposta = LAST_INSERT_ID();

UPDATE pedido SET estado = 'com_propostas' WHERE id = 10 AND estado = 'publicado';

-- Cartões de proposta que a cliente compara (ecrã 04)
SELECT * FROM vw_cartao_proposta WHERE pedido_id = 10 ORDER BY valor_total;

-- Propostas do pedido 1 com a hora prevista de chegada
SELECT pr.id, u.nome, pr.valor_total, pr.material_detalhe,
       CASE WHEN pr.na_hora_pedida THEN pe.data_pretendida
            WHEN pr.estado = 'aceite' THEN pr.respondida_em + INTERVAL pr.tempo_chegada_min MINUTE
            ELSE NOW() + INTERVAL pr.tempo_chegada_min MINUTE END AS chegada_prevista
  FROM proposta pr
  JOIN pedido pe ON pe.id = pr.pedido_id
  JOIN utilizador u ON u.id = pr.profissional_id
 WHERE pr.pedido_id = 1 AND pr.estado IN ('enviada', 'aceite')
 ORDER BY pr.valor_total;

-- ---------------------------------------------------------------------
-- 8. Aceitar proposta (ecrã 08), numa transação
-- ---------------------------------------------------------------------

START TRANSACTION;
UPDATE proposta SET estado = 'aceite', respondida_em = NOW() WHERE id = @proposta AND estado = 'enviada';
UPDATE proposta SET estado = 'recusada', respondida_em = NOW() WHERE pedido_id = 10 AND id <> @proposta AND estado = 'enviada';
UPDATE pedido SET estado = 'aceite', proposta_aceite_id = @proposta WHERE id = 10;
INSERT INTO confirmacao_servico (pedido_id, token_qr, codigo_numerico, valor_acordado, expira_em)
SELECT 10, CONCAT('kx_qr_', REPLACE(UUID(), '-', '')), '482173', valor_total, NOW() + INTERVAL 10 MINUTE
  FROM proposta WHERE id = @proposta;
INSERT IGNORE INTO conversa (pedido_id, profissional_id) VALUES (10, @joaquim);
COMMIT;

-- Serviço em curso da cliente (ecrã 05)
SELECT pe.id, pe.titulo, pe.estado, cs.valor_acordado, u.nome AS profissional
  FROM pedido pe
  JOIN proposta pr ON pr.id = pe.proposta_aceite_id
  JOIN utilizador u ON u.id = pr.profissional_id
  JOIN confirmacao_servico cs ON cs.pedido_id = pe.id
 WHERE pe.cliente_id = @teresa AND pe.estado IN ('aceite', 'a_caminho', 'em_curso')
 ORDER BY pe.atualizado_em DESC
 LIMIT 1;

-- ---------------------------------------------------------------------
-- 9. QR Code e confirmação com código (ecrãs 05, 16 e 17)
-- ---------------------------------------------------------------------

-- 9.1 O que o ecrã 05 mostra: token opaco, código e validade
SELECT pedido_id, token_qr AS token, codigo_numerico AS codigo, expira_em AS valido_ate, valor_acordado
  FROM confirmacao_servico
 WHERE pedido_id = 10 AND estado = 'pendente';

-- 9.2 Trabalho à espera do código do cliente (ecrã 16)
SELECT pe.id AS pedido_id, pe.titulo AS servico,
       CONCAT(SUBSTRING_INDEX(uc.nome, ' ', 1), ' ', LEFT(SUBSTRING_INDEX(uc.nome, ' ', -1), 1), '.') AS cliente,
       cs.valor_acordado AS valor
  FROM pedido pe
  JOIN proposta pr ON pr.id = pe.proposta_aceite_id
  JOIN utilizador uc ON uc.id = pe.cliente_id
  JOIN confirmacao_servico cs ON cs.pedido_id = pe.id AND cs.estado = 'pendente'
 WHERE pr.profissional_id = @joaquim AND pe.estado IN ('aceite', 'a_caminho', 'em_curso');

-- 9.3 Código errado: conta a tentativa (à quinta, a API bloqueia)
UPDATE confirmacao_servico SET tentativas = tentativas + 1
 WHERE pedido_id = 10 AND estado = 'pendente' AND codigo_numerico <> '000000';

-- 9.4 Código certo: o trigger trg_confirmacao_concluir fecha o pedido e soma o serviço
UPDATE confirmacao_servico
   SET estado = 'confirmado', metodo_confirmacao = 'codigo', metodo_pagamento = 'dinheiro',
       numero_comprovativo = CONCAT('KX-', YEAR(NOW()), '-', LPAD(id, 6, '0')), confirmado_em = NOW()
 WHERE pedido_id = 10 AND estado = 'pendente' AND codigo_numerico = '482173' AND tentativas < 5;

SELECT estado, concluido_em FROM pedido WHERE id = 10;

-- ---------------------------------------------------------------------
-- 10. Comprovativo (ecrãs 06 e 17)
-- ---------------------------------------------------------------------

SELECT numero_comprovativo, titulo, cliente, profissional, valor_kz, metodo_pagamento, metodo_confirmacao, confirmado_em
  FROM vw_comprovativo
 WHERE pedido_id = 10;

-- ---------------------------------------------------------------------
-- 11. Avaliar o serviço (ecrã 06)
-- ---------------------------------------------------------------------

-- Os triggers validam (só serviços confirmados) e atualizam a média de forma incremental
INSERT INTO avaliacao (pedido_id, cliente_id, profissional_id, estrelas, comentario)
VALUES (10, @teresa, @joaquim, 5, 'Muro novo em dois dias. Muito profissional.');
SET @avaliacao = LAST_INSERT_ID();

INSERT INTO avaliacao_etiqueta (avaliacao_id, etiqueta_id)
SELECT @avaliacao, id FROM etiqueta WHERE chave IN ('pontual', 'trabalho_limpo');

SELECT media_avaliacao, total_avaliacoes, total_servicos FROM profissional WHERE utilizador_id = @joaquim;

-- Etiquetas mais dadas a um profissional
SELECT e.chave, e.nome, COUNT(*) AS total
  FROM avaliacao a
  JOIN avaliacao_etiqueta ae ON ae.avaliacao_id = a.id
  JOIN etiqueta e ON e.id = ae.etiqueta_id
 WHERE a.profissional_id = @joaquim
 GROUP BY e.id
 ORDER BY total DESC;

-- ---------------------------------------------------------------------
-- 12. Histórico de pedidos (ecrã 07)
-- ---------------------------------------------------------------------

-- Mais recentes primeiro, com o profissional e o valor combinado
SELECT pe.id, pe.titulo, c.chave AS categoria_chave, pe.estado, pe.criado_em,
       u.nome AS profissional, COALESCE(cs.valor_acordado, pr.valor_total) AS valor
  FROM pedido pe
  JOIN categoria c ON c.id = pe.categoria_id
  LEFT JOIN proposta pr ON pr.id = pe.proposta_aceite_id
  LEFT JOIN utilizador u ON u.id = pr.profissional_id
  LEFT JOIN confirmacao_servico cs ON cs.pedido_id = pe.id
 WHERE pe.cliente_id = @maria
 ORDER BY pe.criado_em DESC;

-- Linha do tempo de um pedido (RF08)
SELECT estado_anterior, estado_novo, criado_em FROM historico_estado_pedido WHERE pedido_id = 10 ORDER BY id;

-- ---------------------------------------------------------------------
-- 13. Conversas (ecrã 18)
-- ---------------------------------------------------------------------

-- Conversas da Maria: com quem, última mensagem, valor e mensagens por ler
SELECT c.id, pe.titulo AS pedido_titulo, u.nome AS interlocutor,
       COALESCE(pr.valor_total, 0) AS valor,
       (SELECT m.texto FROM mensagem m WHERE m.conversa_id = c.id ORDER BY m.id DESC LIMIT 1) AS ultima_mensagem,
       (SELECT COUNT(*) FROM mensagem m WHERE m.conversa_id = c.id AND m.remetente_id <> @maria AND m.lida_em IS NULL) AS nao_lidas
  FROM conversa c
  JOIN pedido pe ON pe.id = c.pedido_id
  JOIN utilizador u ON u.id = c.profissional_id
  LEFT JOIN proposta pr ON pr.pedido_id = c.pedido_id AND pr.profissional_id = c.profissional_id
 WHERE pe.cliente_id = @maria
 ORDER BY (SELECT MAX(m.enviada_em) FROM mensagem m WHERE m.conversa_id = c.id) DESC;

-- ---------------------------------------------------------------------
-- 14. Mensagens e "lida" (ecrã 19)
-- ---------------------------------------------------------------------

-- Últimas 50 mensagens da conversa 1, vistas pela Maria ("minha" e "lida")
SELECT * FROM (
  SELECT m.id, m.texto, m.remetente_id = @maria AS minha, m.enviada_em,
         (m.remetente_id = @maria AND m.lida_em IS NOT NULL) AS lida
    FROM mensagem m
   WHERE m.conversa_id = 1
   ORDER BY m.id DESC
   LIMIT 50
) AS ultimas ORDER BY id;

-- Enviar e marcar a conversa como lida ao abrir
INSERT INTO mensagem (conversa_id, remetente_id, texto) VALUES (1, @maria, 'Obrigada, fico à espera.');
UPDATE mensagem SET lida_em = NOW() WHERE conversa_id = 1 AND remetente_id <> @maria AND lida_em IS NULL;

-- ---------------------------------------------------------------------
-- 15. Mapa (ecrã 22)
-- ---------------------------------------------------------------------

-- Posição de cada profissional no mapa estático, centrado na casa da Maria e com
-- @raio_mapa km para cada lado. x e y vão de 0 a 1 (0,0 é o canto superior esquerdo)
SET @raio_mapa = 5;
SELECT * FROM (
  SELECT p.utilizador_id AS id, u.nome,
         ROUND(0.5 + (p.longitude - @lng) * 111.32 * COS(RADIANS(@lat)) / (2 * @raio_mapa), 3) AS x,
         ROUND(0.5 - (p.latitude  - @lat) * 110.57 / (2 * @raio_mapa), 3)                      AS y
    FROM profissional p JOIN utilizador u ON u.id = p.utilizador_id
   WHERE p.disponivel = TRUE AND p.latitude IS NOT NULL
) AS pinos
 WHERE x BETWEEN 0 AND 1 AND y BETWEEN 0 AND 1;
