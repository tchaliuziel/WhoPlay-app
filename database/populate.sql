-- =============================================================
-- WhoPlay — dados de exemplo (os mesmos do mockup)
-- Correr DEPOIS do schema.sql:
--   mysql -u root < database/seed.sql
-- Palavra-passe de todos os utilizadores: 12345678
-- =============================================================

USE whoplay;

-- Modalidades -------------------------------------------------
INSERT INTO modalidades (id, nome, descricao) VALUES
  (1, 'Padel',       '2 ou 4 jogadores'),
  (2, 'Ténis',       '2 ou 4 jogadores'),
  (3, 'Futebol',     '5, 7 ou 11 por equipa'),
  (4, 'BJJ',         'Parceiro de treino'),
  (5, 'Basquetebol', '3x3 ou 5x5'),
  (6, 'Voleibol',    'Praia ou pavilhão'),
  (7, 'Running',     'Companhia de corrida'),
  (8, 'Ginásio',     'Parceiro de treino');

-- Utilizadores ------------------------------------------------
-- O hash abaixo é o bcrypt de "12345678" (gerado pela API).
SET @pass = '$2b$10$pmW7t7Clw0vlmN2AmEkgd.CI3VDEi4DeFultw7XPSs8aZHl5Szzw2';

INSERT INTO utilizadores (id, nome, email, password_hash, localidade, latitude, longitude, raio_km, objetivo, avaliacao) VALUES
  (1, 'Sebastião', 'sebastiao@email.com', @pass, 'Moscavide', 38.779000, -9.103000, 5, 'Jogos amigáveis',    4.8),
  (2, 'Tchali',    'tchali@email.com',    @pass, 'Olivais',   38.795200, -9.103000, 5, 'Jogos amigáveis',    4.7),
  (3, 'Helio',     'helio@email.com',     @pass, 'Alvalade',  38.779000, -9.138700, 5, 'Jogos amigáveis',    4.5),
  (4, 'Cristiano', 'cristiano@email.com', @pass, 'Marvila',   38.741200, -9.103000, 5, 'Jogos competitivos', 4.2);

-- Desportos e nível de cada um --------------------------------
INSERT INTO utilizador_modalidades (utilizador_id, modalidade_id, nivel) VALUES
  (1, 1, 'Intermédio'), (1, 2, 'Iniciante'),
  (2, 1, 'Intermédio'),
  (3, 1, 'Intermédio'), (3, 2, 'Intermédio'),
  (4, 1, 'Avançado'),   (4, 3, 'Intermédio');

-- Disponibilidade (1 = segunda … 7 = domingo) ------------------
INSERT INTO disponibilidades (utilizador_id, dia_semana, hora_inicio, hora_fim) VALUES
  -- Sebastião
  (1, 1, '18:00', '21:00'), (1, 3, '18:00', '22:00'), (1, 6, '10:00', '15:00'),
  -- Tchali
  (2, 1, '18:00', '21:00'), (2, 2, '19:00', '21:00'), (2, 3, '18:00', '21:00'), (2, 4, '19:00', '21:00'),
  (2, 5, '19:00', '21:00'), (2, 6, '10:00', '13:30'), (2, 7, '19:00', '21:00'),
  -- Helio
  (3, 1, '18:00', '20:00'), (3, 2, '18:00', '20:00'), (3, 3, '18:00', '20:00'), (3, 4, '18:00', '20:00'),
  (3, 5, '18:00', '20:00'), (3, 6, '10:00', '12:00'), (3, 7, '18:00', '20:00'),
  -- Cristiano
  (4, 1, '20:00', '22:00'), (4, 2, '20:00', '22:00'), (4, 3, '20:00', '22:00'), (4, 4, '20:00', '22:00'),
  (4, 5, '20:00', '22:00'), (4, 6, '14:00', '16:00'), (4, 7, '20:00', '22:00');

-- Jogo de Padel no próximo sábado às 10:00 ---------------------
-- (5 - WEEKDAY(hoje) + 7) % 7 = dias que faltam até sábado
INSERT INTO jogos (id, organizador_id, modalidade_id, data_hora, local_nome, latitude, longitude,
                   nivel, formato, capacidade, jogadores_externos, preco) VALUES
  (1, 1, 1,
   TIMESTAMP(CURDATE() + INTERVAL ((5 - WEEKDAY(CURDATE()) + 7) % 7) DAY, '10:00:00'),
   'Padel Club X', 38.757400, -9.103000, 'Intermédio', 'Amigável', 4, 0, 8.00);

INSERT INTO jogo_participantes (jogo_id, utilizador_id, codigo_checkin) VALUES
  (1, 1, UUID()), (1, 3, UUID()), (1, 4, UUID());

-- Convites ----------------------------------------------------
INSERT INTO convites (remetente_id, destinatario_id, modalidade_id, data_hora, estado, respondido_em) VALUES
  -- Sebastião convidou o Tchali para hoje às 19:00 (à espera)
  (1, 2, 1, TIMESTAMP(CURDATE(), '19:00:00'), 'pendente', NULL),
  -- Cristiano convidou o Sebastião para quarta às 18:00 (por responder)
  (4, 1, 1, TIMESTAMP(CURDATE() + INTERVAL ((2 - WEEKDAY(CURDATE()) + 7) % 7) DAY, '18:00:00'), 'pendente', NULL),
  -- Sebastião convidou o Helio e ele aceitou
  (1, 3, 1, TIMESTAMP(CURDATE(), '18:00:00'), 'aceite', NOW() - INTERVAL 5 MINUTE);

-- Avisos do Sebastião -----------------------------------------
INSERT INTO notificacoes (utilizador_id, titulo, detalhe, lida, criado_em) VALUES
  (1, 'O Helio aceitou o teu convite', '', FALSE, NOW() - INTERVAL 5 MINUTE),
  (1, 'Falta 1 jogador para o teu jogo', 'Padel · sábado às 10:00', FALSE, NOW() - INTERVAL 1 HOUR),
  (1, 'Encontrámos 3 jogadores compatíveis perto de ti', '', TRUE, NOW() - INTERVAL 1 DAY);
