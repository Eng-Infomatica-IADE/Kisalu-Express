-- =====================================================================
--  Kisalu Express · Dados de exemplo
--  Correr depois de create.sql. Todos os nomes, telemóveis, emails e
--  documentos são fictícios. Os dados seguem o mock da app Flutter
--  (lib/data/mock), para a app mostrar o mesmo com ou sem servidor.
--
--  Pessoas principais:
--    Maria Kiala     +244923000000  cliente (Talatona, 2 moradas, 3 favoritos)
--    Joaquim Manuel  +244923000002  canalizador verificado, 4.8 em 126 avaliações
--    Administrador   +244923000099  admin
-- =====================================================================

USE kisalu_express;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET time_zone = '+00:00';

-- ---------------------------------------------------------------------
-- Categorias (as 13 da app; as 8 primeiras estão em destaque no Início)
-- ---------------------------------------------------------------------

INSERT INTO categoria (id, chave, nome, plural, icone, ordem, em_destaque) VALUES
 (1,  'eletricista',  'Eletricista',     'eletricistas',                'bolt',              1,  TRUE),
 (2,  'canalizador',  'Canalizador',     'canalizadores',               'water_drop',        2,  TRUE),
 (3,  'mecanico',     'Mecânico',        'mecânicos',                   'car_repair',        3,  TRUE),
 (4,  'pedreiro',     'Pedreiro',        'pedreiros',                   'foundation',        4,  TRUE),
 (5,  'ar_cond',      'Ar condicionado', 'técnicos de ar condicionado', 'ac_unit',           5,  TRUE),
 (6,  'cabeleireira', 'Cabeleireira',    'cabeleireiras',               'content_cut',       6,  TRUE),
 (7,  'pintor',       'Pintor',          'pintores',                    'format_paint',      7,  TRUE),
 (8,  'limpeza',      'Limpeza',         'profissionais de limpeza',    'cleaning_services', 8,  TRUE),
 (9,  'carpinteiro',  'Carpinteiro',     'carpinteiros',                'carpenter',         9,  FALSE),
 (10, 'jardinagem',   'Jardinagem',      'jardineiros',                 'yard',              10, FALSE),
 (11, 'informatica',  'Informática',     'técnicos de informática',     'computer',          11, FALSE),
 (12, 'serralharia',  'Serralharia',     'serralheiros',                'hardware',          12, FALSE),
 (13, 'transporte',   'Transporte',      'transportadores',             'local_shipping',    13, FALSE);

INSERT INTO etiqueta (id, chave, nome) VALUES
 (1, 'pontual',        'Pontual'),
 (2, 'preco_justo',    'Preço justo'),
 (3, 'simpatico',      'Simpático'),
 (4, 'trabalho_limpo', 'Trabalho limpo'),
 (5, 'rapido',         'Rápido');

-- ---------------------------------------------------------------------
-- Utilizadores
-- ---------------------------------------------------------------------

INSERT INTO utilizador (id, email, telemovel, nome, tipo_perfil, consentimento_rgpd_em, criado_em) VALUES
 (1,  'maria@exemplo.com',           '+244923000000', 'Maria Kiala',          'cliente',      NOW(), '2026-03-02 10:00:00'),
 (2,  'joaquim@exemplo.com',         '+244923000002', 'Joaquim Manuel',       'profissional', NOW(), '2025-11-15 09:00:00'),
 (3,  'rui@exemplo.com',             '+244923000003', 'Rui Santos',           'profissional', NOW(), '2026-01-20 09:00:00'),
 (4,  'admin@exemplo.com',           '+244923000099', 'Administrador Kisalu', 'admin',        NOW(), '2025-10-01 09:00:00'),
 (5,  'paulo@exemplo.com',           '+244923000005', 'Paulo Neto',           'profissional', NOW(), '2025-12-03 09:00:00'),
 (6,  'ana.cardoso@exemplo.com',     '+244923000006', 'Ana Cardoso',          'profissional', NOW(), '2026-02-11 09:00:00'),
 (7,  'carlos@exemplo.com',          '+244923000007', 'Carlos Dias',          'profissional', NOW(), '2026-01-08 09:00:00'),
 (8,  'nuno@exemplo.com',            '+244923000008', 'Nuno Ferreira',        'profissional', NOW(), '2026-02-25 09:00:00'),
 (9,  'helder@exemplo.com',          '+244923000009', 'Hélder Tavares',       'profissional', NOW(), '2026-04-14 09:00:00'),
 (10, 'maria.sebastiao@exemplo.com', '+244923000010', 'Maria Sebastião',      'cliente',      NOW(), '2026-05-06 09:00:00'),
 (11, 'pedro.kiluange@exemplo.com',  '+244923000011', 'Pedro Kiluange',       'cliente',      NOW(), '2026-05-19 09:00:00'),
 (12, 'ana.paulo@exemplo.com',       '+244923000012', 'Ana Paulo',            'cliente',      NOW(), '2026-06-02 09:00:00'),
 (13, 'rui.bento@exemplo.com',       '+244923000013', 'Rui Bento',            'cliente',      NOW(), '2026-06-30 09:00:00'),
 (14, 'teresa@exemplo.com',          '+244923000014', 'Teresa Mbala',         'cliente',      NOW(), '2026-07-21 09:00:00');

-- Profissionais. As coordenadas põem os quatro primeiros à volta da casa da Maria em
-- Talatona (mapa do ecrã 22). O Joaquim fica a 1,2 km da morada predefinida da Maria,
-- como no Figma, e por isso aparece primeiro em "Perto de si" (ecrã 02).
INSERT INTO profissional
 (utilizador_id, bio, anos_experiencia, zona, raio_atuacao_km, latitude, longitude, mao_obra_desde, especialidades, verificado, verificado_em) VALUES
 (2, 'Canalizador há 6 anos. Fugas, esquentadores e loiças sanitárias.', 6, 'Talatona, Luanda', 10, -8.912400, 13.177100, 8000,
     JSON_ARRAY('Fugas de água','Esquentadores','Desentupimentos','Loiças sanitárias'), TRUE, '2025-11-20 10:00:00'),
 (3, 'Canalização e pequenas obras.', 3, 'Kilamba, Luanda', 10, -8.913700, 13.200300, 9000,
     JSON_ARRAY('Canalização','Pequenas obras'), TRUE, '2026-01-25 10:00:00'),
 (5, 'Canalizador e técnico de esquentadores.', 9, 'Talatona, Luanda', 10, -8.923600, 13.158600, 10000,
     JSON_ARRAY('Esquentadores','Fugas de água'), FALSE, NULL),
 (6, 'Tranças, penteados e cortes ao domicílio.', 4, 'Talatona, Luanda', 10, -8.898800, 13.209600, 5000,
     JSON_ARRAY('Tranças','Penteados','Cortes'), TRUE, '2026-02-15 10:00:00'),
 (7, 'Instalações elétricas, tomadas e quadros.', 7, 'Talatona, Luanda', 10, -8.930000, 13.198000, 5000,
     JSON_ARRAY('Tomadas','Quadros elétricos','Iluminação'), TRUE, '2026-01-12 10:00:00'),
 (8, 'Instalação e limpeza de ar condicionado.', 5, 'Belas, Luanda', 15, -8.960000, 13.165000, 7000,
     JSON_ARRAY('Limpeza de AC','Instalação de AC'), TRUE, '2026-03-01 10:00:00'),
 (9, 'Mecânica geral e travões.', 8, 'Viana, Luanda', 20, -8.905000, 13.260000, 8000,
     JSON_ARRAY('Travões','Revisões'), FALSE, NULL);

INSERT INTO profissional_categoria (profissional_id, categoria_id) VALUES
 (2,2), (2,4), (3,2), (3,4), (5,2), (6,6), (7,1), (8,5), (9,3);

INSERT INTO verificacao_identidade
 (profissional_id, tipo_documento, numero_documento, documento_url, selfie_url, estado, revisto_por, submetido_em, revisto_em) VALUES
 (2, 'bilhete_identidade', '004567890LA041', 'verificacoes/exemplo-bi-2.jpg', 'verificacoes/exemplo-rosto-2.jpg', 'aprovada', 4, '2025-11-18 10:00:00', '2025-11-20 10:00:00'),
 (3, 'bilhete_identidade', '007654321LA042', 'verificacoes/exemplo-bi-3.jpg', 'verificacoes/exemplo-rosto-3.jpg', 'aprovada', 4, '2026-01-22 10:00:00', '2026-01-25 10:00:00'),
 (6, 'bilhete_identidade', '001122334LA043', 'verificacoes/exemplo-bi-6.jpg', 'verificacoes/exemplo-rosto-6.jpg', 'aprovada', 4, '2026-02-12 10:00:00', '2026-02-15 10:00:00'),
 (7, 'passaporte',         'N0012345',       'verificacoes/exemplo-bi-7.jpg', 'verificacoes/exemplo-rosto-7.jpg', 'aprovada', 4, '2026-01-09 10:00:00', '2026-01-12 10:00:00'),
 (8, 'bilhete_identidade', '005566778LA044', 'verificacoes/exemplo-bi-8.jpg', 'verificacoes/exemplo-rosto-8.jpg', 'aprovada', 4, '2026-02-26 10:00:00', '2026-03-01 10:00:00');

INSERT INTO disponibilidade (profissional_id, dia_semana, hora_inicio, hora_fim) VALUES
 (2,1,'08:00','18:00'), (2,2,'08:00','18:00'), (2,3,'08:00','18:00'), (2,4,'08:00','18:00'),
 (2,5,'08:00','18:00'), (2,6,'09:00','13:00');

-- ---------------------------------------------------------------------
-- Moradas e favoritos
-- ---------------------------------------------------------------------

INSERT INTO morada (id, utilizador_id, rotulo, endereco, ponto_referencia, bairro, municipio, provincia, latitude, longitude, predefinida) VALUES
 (1, 1,  'Casa',     'Rua 21, Casa 14',                  'Perto da cantina do Sr. Zé',  'Talatona',     'Talatona', 'Luanda', -8.920000, 13.185000, TRUE),
 (2, 1,  'Trabalho', 'Via S8, Edifício Atlântico, 3.º',  'Em frente ao supermercado',   'Talatona',     'Talatona', 'Luanda', -8.913000, 13.192000, FALSE),
 (3, 10, 'Casa',     'Rua da Missão, Casa 7',            'Atrás da escola primária',    'Talatona',     'Talatona', 'Luanda', -8.925000, 13.180000, TRUE),
 (4, 11, 'Casa',     'Edifício B12, apartamento 4',      'Junto ao jardim central',     'Kilamba',      'Belas',    'Luanda', -8.995000, 13.270000, TRUE),
 (5, 12, 'Casa',     'Rua 5, Casa 31',                   'Perto da paragem do Camama',  'Camama',       'Belas',    'Luanda', -8.960000, 13.230000, TRUE),
 (6, 13, 'Casa',     'Condomínio Jardim, vivenda 9',     'Portão azul',                 'Talatona',     'Talatona', 'Luanda', -8.918000, 13.176000, TRUE),
 (7, 14, 'Casa',     'Rua do Mercado, Casa 22',          'Ao lado da igreja',           NULL,           'Viana',    'Luanda', -8.896800, 13.181200, TRUE);

INSERT INTO favorito (cliente_id, profissional_id) VALUES (1,2), (1,6), (1,7);

-- ---------------------------------------------------------------------
-- Pedido 1: "Fuga de água na cozinha" (ecrã 04), com 3 propostas
-- ---------------------------------------------------------------------

INSERT INTO pedido (id, cliente_id, categoria_id, morada_id, titulo, descricao, urgencia, data_pretendida, estado, criado_em, publicado_em)
VALUES (1, 1, 2, 1, 'Fuga de água na cozinha', 'Cano a pingar debaixo do lava-loiça. Precisa de reparação hoje.',
        'agendado', NOW() + INTERVAL 1 HOUR, 'publicado', NOW() - INTERVAL 6 MINUTE, NOW() - INTERVAL 5 MINUTE);
INSERT INTO historico_estado_pedido (pedido_id, estado_anterior, estado_novo, alterado_por, criado_em)
VALUES (1, NULL, 'publicado', 1, NOW() - INTERVAL 5 MINUTE);
INSERT INTO pedido_foto (pedido_id, url) VALUES (1, '/uploads/pedidos/exemplo-fuga.jpg');

INSERT INTO proposta (id, pedido_id, profissional_id, valor_mao_obra, valor_material, valor_deslocacao,
                      inclui_descricao, material_detalhe, tempo_chegada_min, criado_em) VALUES
 (1, 1, 2, 8000,  3500, 1000, 'Mão de obra · material · deslocação', 'sifão e vedante', 40, NOW() - INTERVAL 4 MINUTE),
 (2, 1, 3, 13500, 0,    1500, 'Mão de obra · deslocação',            NULL,              60, NOW() - INTERVAL 3 MINUTE),
 (3, 1, 5, 14000, 3000, 1500, 'Mão de obra · material · deslocação', 'tubo e abraçadeiras', 25, NOW() - INTERVAL 2 MINUTE);

UPDATE pedido SET estado = 'com_propostas' WHERE id = 1;

-- ---------------------------------------------------------------------
-- Histórico da Maria (ecrã 07): serviços concluídos e um cancelado
-- ---------------------------------------------------------------------

INSERT INTO pedido (id, cliente_id, categoria_id, morada_id, titulo, descricao, estado, criado_em, publicado_em, concluido_em, cancelado_em, motivo_cancelamento) VALUES
 (2, 1, 1, 1, 'Tomada sem luz',      'A tomada da sala deixou de dar corrente.',    'concluido', '2026-09-24 08:00:00', '2026-09-24 08:00:00', '2026-09-24 10:00:00', NULL, NULL),
 (3, 1, 5, 1, 'Limpeza de AC',       'O ar condicionado do quarto cheira a mofo.',  'concluido', '2026-09-12 08:00:00', '2026-09-12 08:00:00', '2026-09-12 10:30:00', NULL, NULL),
 (4, 1, 3, 2, 'Pastilhas de travão', 'O carro chia ao travar.',                     'cancelado', '2026-09-03 08:00:00', '2026-09-03 08:00:00', NULL, '2026-09-03 11:00:00', 'Resolvi de outra forma.'),
 (5, 1, 6, 1, 'Tranças',             'Tranças para um casamento no sábado.',        'concluido', '2026-08-28 08:00:00', '2026-08-28 08:00:00', '2026-08-28 12:00:00', NULL, NULL);

-- Trabalhos do Joaquim para outros clientes (histórico do lado profissional)
INSERT INTO pedido (id, cliente_id, categoria_id, morada_id, titulo, descricao, estado, criado_em, publicado_em, concluido_em, cancelado_em, motivo_cancelamento) VALUES
 (6, 10, 2, 3, 'Fuga na casa de banho', 'Pinga água por baixo do autoclismo.',      'concluido', '2026-10-02 08:00:00', '2026-10-02 08:00:00', '2026-10-02 10:00:00', NULL, NULL),
 (7, 11, 2, 4, 'Desentupir pia',        'A pia da cozinha não escoa.',              'concluido', '2026-09-24 07:00:00', '2026-09-24 07:00:00', '2026-09-24 09:00:00', NULL, NULL),
 (8, 12, 2, 5, 'Trocar esquentador',    'O esquentador antigo deixou de acender.',  'concluido', '2026-09-12 07:00:00', '2026-09-12 07:00:00', '2026-09-12 12:00:00', NULL, NULL),
 (9, 13, 2, 6, 'Torneira a pingar',     'A torneira do tanque não fecha bem.',      'cancelado', '2026-09-03 07:00:00', '2026-09-03 07:00:00', NULL, '2026-09-03 09:00:00', 'Já não é preciso.');

INSERT INTO proposta (id, pedido_id, profissional_id, valor_mao_obra, valor_material, valor_deslocacao, inclui_descricao, tempo_chegada_min, estado, criado_em, respondida_em) VALUES
 (4,  2, 7, 4500,  500,   1000, 'Mão de obra · material · deslocação', 30, 'aceite', '2026-09-24 08:10:00', '2026-09-24 08:20:00'),
 (5,  3, 8, 8000,  0,     1500, 'Mão de obra · deslocação',            45, 'aceite', '2026-09-12 08:10:00', '2026-09-12 08:20:00'),
 (6,  4, 9, 9000,  5000,  1000, 'Mão de obra · material · deslocação', 60, 'aceite', '2026-09-03 08:10:00', '2026-09-03 08:20:00'),
 (7,  5, 6, 18000, 1000,  1000, 'Mão de obra · material · deslocação', 30, 'aceite', '2026-08-28 08:10:00', '2026-08-28 08:20:00'),
 (8,  6, 2, 7000,  1000,  1000, 'Mão de obra · material · deslocação', 40, 'aceite', '2026-10-02 08:10:00', '2026-10-02 08:20:00'),
 (9,  7, 2, 7000,  500,   1000, 'Mão de obra · material · deslocação', 40, 'aceite', '2026-09-24 07:10:00', '2026-09-24 07:20:00'),
 (10, 8, 2, 9000,  8000,  1000, 'Mão de obra · material · deslocação', 60, 'aceite', '2026-09-12 07:10:00', '2026-09-12 07:20:00'),
 (11, 9, 2, 4000,  0,     1000, 'Mão de obra · deslocação',            40, 'aceite', '2026-09-03 07:10:00', '2026-09-03 07:20:00');

UPDATE pedido SET proposta_aceite_id = id + 2 WHERE id BETWEEN 2 AND 9;

INSERT INTO confirmacao_servico
 (id, pedido_id, token_qr, codigo_numerico, valor_acordado, estado, metodo_confirmacao, metodo_pagamento, numero_comprovativo, gerado_em, confirmado_em) VALUES
 (1, 2, 'kx_qr_exemploTomadaSemLuz000000000001', '301854', 6000,  'confirmado', 'qr',     'dinheiro',           'KX-2026-000001', '2026-09-24 08:20:00', '2026-09-24 10:00:00'),
 (2, 3, 'kx_qr_exemploLimpezaDeAc0000000000002', '297316', 9500,  'confirmado', 'codigo', 'dinheiro',           'KX-2026-000002', '2026-09-12 08:20:00', '2026-09-12 10:30:00'),
 (3, 4, 'kx_qr_exemploPastilhasTravao00000003', '640218', 15000, 'expirado',   NULL,     NULL,                 NULL,             '2026-09-03 08:20:00', NULL),
 (4, 5, 'kx_qr_exemploTrancas00000000000000004', '188240', 20000, 'confirmado', 'qr',     'multicaixa_express', 'KX-2026-000004', '2026-08-28 08:20:00', '2026-08-28 12:00:00'),
 (5, 6, 'kx_qr_exemploFugaCasaDeBanho0000000005', '552907', 9000,  'confirmado', 'qr',     'dinheiro',           'KX-2026-000005', '2026-10-02 08:20:00', '2026-10-02 10:00:00'),
 (6, 7, 'kx_qr_exemploDesentupirPia00000000006', '813466', 8500,  'confirmado', 'codigo', 'dinheiro',           'KX-2026-000006', '2026-09-24 07:20:00', '2026-09-24 09:00:00'),
 (7, 8, 'kx_qr_exemploTrocarEsquentador0000007', '420975', 18000, 'confirmado', 'qr',     'transferencia',      'KX-2026-000007', '2026-09-12 07:20:00', '2026-09-12 12:00:00'),
 (8, 9, 'kx_qr_exemploTorneiraPingar0000000008', '379150', 5000,  'expirado',   NULL,     NULL,                 NULL,             '2026-09-03 07:20:00', NULL);

-- Avaliações que aparecem no perfil do Joaquim (ecrã 03) e nos outros perfis
INSERT INTO avaliacao (id, pedido_id, cliente_id, profissional_id, estrelas, comentario, criado_em) VALUES
 (1, 6, 10, 2, 5, 'Chegou a horas e resolveu a fuga em 40 min. Recomendo!', '2026-10-02 11:00:00'),
 (2, 7, 11, 2, 5, 'Trabalho limpo e preço igual ao combinado.',              '2026-09-24 10:00:00'),
 (3, 2, 1,  7, 5, 'Resolveu a tomada num instante.',                          '2026-09-24 11:30:00'),
 (4, 3, 1,  8, 4, 'Bom serviço, chegou um pouco atrasado.',                   '2026-09-12 12:00:00'),
 (5, 5, 1,  6, 5, 'Tranças lindas, recomendo a todas.',                       '2026-08-28 13:00:00');

INSERT INTO avaliacao_etiqueta (avaliacao_id, etiqueta_id) VALUES
 (1,1), (1,5), (2,4), (2,2), (3,5), (4,3), (5,1), (5,3);

INSERT INTO trabalho_foto (profissional_id, pedido_id, url, legenda) VALUES
 (2, 6,    '/uploads/trabalhos/exemplo-antes-depois.jpg', 'Antes/depois'),
 (2, 8,    '/uploads/trabalhos/exemplo-esquentador.jpg',  'Esquentador'),
 (2, NULL, '/uploads/trabalhos/exemplo-loica.jpg',        'Loiça sanitária');

-- ---------------------------------------------------------------------
-- Pedido 10: "Reparar muro do quintal" (painel do profissional, ecrã 14)
-- ---------------------------------------------------------------------

INSERT INTO pedido (id, cliente_id, categoria_id, morada_id, titulo, descricao, urgencia, data_pretendida, estado, criado_em, publicado_em)
VALUES (10, 14, 4, 7, 'Reparar muro do quintal', 'Parte do muro caiu com a chuva. Preciso de o refazer.',
        'agendado', TIMESTAMP(UTC_DATE() + INTERVAL 1 DAY, '08:00:00'), 'publicado',
        NOW() - INTERVAL 22 MINUTE, NOW() - INTERVAL 22 MINUTE);
INSERT INTO historico_estado_pedido (pedido_id, estado_anterior, estado_novo, alterado_por, criado_em)
VALUES (10, NULL, 'publicado', 14, NOW() - INTERVAL 22 MINUTE);

-- ---------------------------------------------------------------------
-- Conversas (ecrãs 18 e 19)
-- ---------------------------------------------------------------------

INSERT INTO conversa (id, pedido_id, profissional_id, criado_em) VALUES
 (1, 1, 2, NOW() - INTERVAL 10 MINUTE),
 (2, 2, 7, '2026-09-24 08:20:00'),
 (3, 3, 8, '2026-09-12 08:20:00');

INSERT INTO mensagem (conversa_id, remetente_id, texto, enviada_em, lida_em) VALUES
 (1, 1, 'Boa tarde. Já tem o sifão para a reparação?',       NOW() - INTERVAL 9 MINUTE, NOW() - INTERVAL 8 MINUTE),
 (1, 2, 'Boa tarde, Maria. Sim, levo o sifão e o vedante.',  NOW() - INTERVAL 7 MINUTE, NULL),
 (1, 2, 'Chego às 15h40, como combinado.',                   NOW() - INTERVAL 1 MINUTE, NULL),
 (2, 1, 'Ficou tudo a funcionar. Obrigada!',                 '2026-09-24 10:05:00', '2026-09-24 10:10:00'),
 (2, 7, 'Obrigado pela preferência!',                        '2026-09-24 10:20:00', '2026-09-24 10:30:00'),
 (3, 8, 'Já pode ligar o ar condicionado.',                  '2026-09-12 10:40:00', '2026-09-12 10:50:00'),
 (3, 8, 'O filtro já está limpo.',                           '2026-09-12 10:45:00', '2026-09-12 10:50:00');

-- ---------------------------------------------------------------------
-- Notificações e ajuda
-- ---------------------------------------------------------------------

INSERT INTO notificacao (utilizador_id, pedido_id, tipo, titulo, corpo, acao, criado_em) VALUES
 (1, 1,  'nova_proposta', 'Recebeu 3 propostas',     'Compare preço, chegada e avaliações.', 'ver_propostas', NOW() - INTERVAL 2 MINUTE),
 (2, 10, 'novo_pedido',   'Novo pedido perto de si', 'Reparar muro do quintal · Viana',      'ver_pedido',    NOW() - INTERVAL 22 MINUTE);

INSERT INTO pergunta_frequente (tema, pergunta, resposta, ordem) VALUES
 ('QR Code',    'Quando devo mostrar o QR Code?', 'Só quando o trabalho estiver concluído e verificado. Se a leitura falhar, diga o código numérico.', 1),
 ('Garantia',   'Posso reclamar depois de confirmar?', 'Sim, até 7 dias depois, em Pedidos › Concluídos › Reportar problema.', 2),
 ('Pagamentos', 'O preço pode mudar depois de aceitar?', 'Só se aprovar na app um pedido de alteração feito pelo profissional.', 3);

-- ---------------------------------------------------------------------
-- Reputação acumulada antes destes dados (como no mock da app).
-- Os triggers somam a partir daqui: contagem por estrelas, total e média.
-- ---------------------------------------------------------------------

-- avaliacoes_1..5 é a distribuição por estrelas (inclui as linhas de `avaliacao` acima);
-- a soma dá total_avaliacoes e a média arredondada dá media_avaliacao.
--   Joaquim: 1+1·2+3·3+13·4+108·5 = 604 em 126 → 4,79 → 4,8
UPDATE profissional SET media_avaliacao = 4.8, total_avaliacoes = 126, total_servicos = 126,
       avaliacoes_1 = 1, avaliacoes_2 = 1, avaliacoes_3 = 3, avaliacoes_4 = 13, avaliacoes_5 = 108 WHERE utilizador_id = 2;
UPDATE profissional SET media_avaliacao = 4.6, total_avaliacoes = 54,  total_servicos = 60,
       avaliacoes_1 = 1, avaliacoes_2 = 1, avaliacoes_3 = 2, avaliacoes_4 = 12, avaliacoes_5 = 38  WHERE utilizador_id = 3;
UPDATE profissional SET media_avaliacao = 4.9, total_avaliacoes = 97,  total_servicos = 110,
       avaliacoes_1 = 0, avaliacoes_2 = 0, avaliacoes_3 = 2, avaliacoes_4 = 7,  avaliacoes_5 = 88  WHERE utilizador_id = 5;
UPDATE profissional SET media_avaliacao = 4.9, total_avaliacoes = 88,  total_servicos = 41,
       avaliacoes_1 = 0, avaliacoes_2 = 0, avaliacoes_3 = 1, avaliacoes_4 = 7,  avaliacoes_5 = 80  WHERE utilizador_id = 6;
UPDATE profissional SET media_avaliacao = 4.7, total_avaliacoes = 73,  total_servicos = 80,
       avaliacoes_1 = 0, avaliacoes_2 = 1, avaliacoes_3 = 3, avaliacoes_4 = 13, avaliacoes_5 = 56  WHERE utilizador_id = 7;
UPDATE profissional SET media_avaliacao = 4.5, total_avaliacoes = 39,  total_servicos = 44,
       avaliacoes_1 = 0, avaliacoes_2 = 1, avaliacoes_3 = 3, avaliacoes_4 = 9,  avaliacoes_5 = 26  WHERE utilizador_id = 8;
UPDATE profissional SET media_avaliacao = 4.4, total_avaliacoes = 28,  total_servicos = 31,
       avaliacoes_1 = 0, avaliacoes_2 = 1, avaliacoes_3 = 3, avaliacoes_4 = 8,  avaliacoes_5 = 16  WHERE utilizador_id = 9;
