-- =============================================================
-- WhoPlay — consultas de prática (as mesmas que a API usa)
-- Corram uma de cada vez no phpMyAdmin (separador SQL).
-- =============================================================

USE whoplay;

-- 1. Todas as modalidades, por ordem alfabética
SELECT id, nome, descricao
FROM modalidades
ORDER BY nome;

-- 2. Perfil do Sebastião com os desportos e níveis (JOIN)
SELECT u.nome, u.localidade, m.nome AS modalidade, um.nivel
FROM utilizadores u
JOIN utilizador_modalidades um ON um.utilizador_id = u.id
JOIN modalidades m             ON m.id = um.modalidade_id
WHERE u.email = 'sebastiao@email.com';

-- 3. Disponibilidade do Sebastião, com o nome do dia
SELECT ELT(dia_semana, 'Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo') AS dia,
       TIME_FORMAT(hora_inicio, '%Hh') AS das,
       TIME_FORMAT(hora_fim, '%Hh')    AS ate
FROM disponibilidades
WHERE utilizador_id = 1
ORDER BY dia_semana;

-- 4. Jogadores de Padel a menos de 5 km do Sebastião (fórmula de Haversine)
--    6371 = raio da Terra em km
SELECT u.id, u.nome, um.nivel,
       ROUND(6371 * 2 * ASIN(SQRT(
         POWER(SIN(RADIANS(u.latitude - eu.latitude) / 2), 2) +
         COS(RADIANS(eu.latitude)) * COS(RADIANS(u.latitude)) *
         POWER(SIN(RADIANS(u.longitude - eu.longitude) / 2), 2)
       )), 1) AS distancia_km
FROM utilizadores u
JOIN utilizador_modalidades um ON um.utilizador_id = u.id AND um.modalidade_id = 1
JOIN utilizadores eu           ON eu.id = 1
WHERE u.id <> eu.id
HAVING distancia_km <= 5
ORDER BY distancia_km;

-- 5. Jogos abertos com o número de vagas livres (subconsulta)
SELECT j.id, m.nome AS modalidade, j.local_nome,
       DATE_FORMAT(j.data_hora, '%d/%m %H:%i') AS quando,
       j.capacidade - j.jogadores_externos
         - (SELECT COUNT(*) FROM jogo_participantes p WHERE p.jogo_id = j.id) AS vagas
FROM jogos j
JOIN modalidades m ON m.id = j.modalidade_id
WHERE j.estado = 'aberto' AND j.data_hora > NOW()
ORDER BY j.data_hora;

-- 6. Convites recebidos pelo Sebastião que ainda estão por responder
SELECT c.id, r.nome AS de, m.nome AS modalidade, c.data_hora
FROM convites c
JOIN utilizadores r ON r.id = c.remetente_id
JOIN modalidades m  ON m.id = c.modalidade_id
WHERE c.destinatario_id = 1 AND c.estado = 'pendente';

-- 7. Quantos avisos por ler tem o Sebastião (COUNT)
SELECT COUNT(*) AS por_ler
FROM notificacoes
WHERE utilizador_id = 1 AND lida = FALSE;

-- 8. Estatística: jogadores e avaliação média por modalidade (GROUP BY)
SELECT m.nome AS modalidade,
       COUNT(*)                   AS jogadores,
       ROUND(AVG(u.avaliacao), 2) AS avaliacao_media,
       SUM(um.nivel = 'Avançado') AS avancados
FROM utilizador_modalidades um
JOIN modalidades m  ON m.id = um.modalidade_id
JOIN utilizadores u ON u.id = um.utilizador_id
GROUP BY m.nome
ORDER BY jogadores DESC;

-- 9. Aceitar o convite do Cristiano (UPDATE)
UPDATE convites
SET estado = 'aceite', respondido_em = NOW()
WHERE id = 2 AND destinatario_id = 1;

-- 10. O Tchali entra no jogo 1 (INSERT) — o UUID() gera o código do QR
INSERT INTO jogo_participantes (jogo_id, utilizador_id, codigo_checkin)
VALUES (1, 2, UUID());

-- 11. Desfazer os passos 9 e 10 (DELETE e UPDATE)
DELETE FROM jogo_participantes WHERE jogo_id = 1 AND utilizador_id = 2;
UPDATE convites SET estado = 'pendente', respondido_em = NULL WHERE id = 2;
