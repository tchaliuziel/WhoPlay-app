-- =============================================================
-- WhoPlay — estrutura da base de dados (MySQL 8 / MariaDB 10.4+)
-- Correr no phpMyAdmin (separador SQL) ou:
--   mysql -u root < database/schema.sql
-- Este script não apaga a base de dados existente. Executar numa BD nova/vazia.
-- =============================================================

DROP DATABASE IF EXISTS whoplay;
CREATE DATABASE IF NOT EXISTS whoplay CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE whoplay;

-- -------------------------------------------------------------
-- 1. Utilizadores (RF01–RF04, RF08)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS utilizadores (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(80)   NOT NULL,
  email          VARCHAR(120)  NOT NULL,
  password_hash  VARCHAR(255)  NOT NULL,
  localidade     VARCHAR(80)   NULL,
  latitude       DECIMAL(9,6)  NULL,
  longitude      DECIMAL(9,6)  NULL,
  raio_km        TINYINT UNSIGNED NOT NULL DEFAULT 5,
  objetivo       ENUM('Jogos amigáveis','Jogos competitivos','Treino') NOT NULL DEFAULT 'Jogos amigáveis',
  avaliacao      DECIMAL(2,1)  NULL,
  criado_em      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_utilizadores_email (email)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 2. Modalidades (lista de desportos da app)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS modalidades (
  id         TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome       VARCHAR(40)  NOT NULL,
  descricao  VARCHAR(60)  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_modalidades_nome (nome)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 3. Que modalidades cada utilizador joga e com que nível (RF05, RF06)
--    Tabela de ligação N:N entre utilizadores e modalidades.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS utilizador_modalidades (
  utilizador_id  INT UNSIGNED     NOT NULL,
  modalidade_id  TINYINT UNSIGNED NOT NULL,
  nivel          ENUM('Iniciante','Intermédio','Avançado') NOT NULL DEFAULT 'Iniciante',
  PRIMARY KEY (utilizador_id, modalidade_id),
  CONSTRAINT fk_um_utilizador FOREIGN KEY (utilizador_id) REFERENCES utilizadores (id) ON DELETE CASCADE,
  CONSTRAINT fk_um_modalidade FOREIGN KEY (modalidade_id) REFERENCES modalidades (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 4. Disponibilidade semanal (RF07). dia_semana: 1 = segunda … 7 = domingo
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS disponibilidades (
  id             INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  utilizador_id  INT UNSIGNED     NOT NULL,
  dia_semana     TINYINT UNSIGNED NOT NULL,
  hora_inicio    TIME             NOT NULL,
  hora_fim       TIME             NOT NULL,
  PRIMARY KEY (id),
  KEY idx_disp_utilizador (utilizador_id, dia_semana),
  CONSTRAINT fk_disp_utilizador FOREIGN KEY (utilizador_id) REFERENCES utilizadores (id) ON DELETE CASCADE,
  CONSTRAINT ck_disp_dia CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT ck_disp_horas CHECK (hora_fim > hora_inicio)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 5. Jogos criados pelos utilizadores
--    jogadores_externos = pessoas que já vão mas não usam a app.
--    Vagas livres = capacidade - jogadores_externos - participantes.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS jogos (
  id                  INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  organizador_id      INT UNSIGNED     NOT NULL,
  modalidade_id       TINYINT UNSIGNED NOT NULL,
  data_hora           DATETIME         NOT NULL,
  local_nome          VARCHAR(100)     NOT NULL,
  latitude            DECIMAL(9,6)     NULL,
  longitude           DECIMAL(9,6)     NULL,
  nivel               ENUM('Iniciante','Intermédio','Avançado') NOT NULL,
  formato             ENUM('Amigável','Competitivo') NOT NULL DEFAULT 'Amigável',
  capacidade          TINYINT UNSIGNED NOT NULL,
  jogadores_externos  TINYINT UNSIGNED NOT NULL DEFAULT 0,
  preco               DECIMAL(6,2)     NOT NULL DEFAULT 0,
  estado              ENUM('aberto','cancelado','terminado') NOT NULL DEFAULT 'aberto',
  criado_em           DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_jogos_data (data_hora),
  CONSTRAINT fk_jogos_organizador FOREIGN KEY (organizador_id) REFERENCES utilizadores (id) ON DELETE CASCADE,
  CONSTRAINT fk_jogos_modalidade FOREIGN KEY (modalidade_id) REFERENCES modalidades (id),
  CONSTRAINT ck_jogos_capacidade CHECK (capacidade BETWEEN 2 AND 30)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 6. Quem vai a cada jogo + check-in por QR Code
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS jogo_participantes (
  jogo_id         INT UNSIGNED NOT NULL,
  utilizador_id   INT UNSIGNED NOT NULL,
  entrou_em       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  codigo_checkin  CHAR(36)     NOT NULL,
  checkin_em      DATETIME     NULL,
  PRIMARY KEY (jogo_id, utilizador_id),
  UNIQUE KEY uq_part_codigo (codigo_checkin),
  CONSTRAINT fk_part_jogo FOREIGN KEY (jogo_id) REFERENCES jogos (id) ON DELETE CASCADE,
  CONSTRAINT fk_part_utilizador FOREIGN KEY (utilizador_id) REFERENCES utilizadores (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 7. Convites entre jogadores
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS convites (
  id               INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  remetente_id     INT UNSIGNED     NOT NULL,
  destinatario_id  INT UNSIGNED     NOT NULL,
  modalidade_id    TINYINT UNSIGNED NOT NULL,
  data_hora        DATETIME         NOT NULL,
  estado           ENUM('pendente','aceite','recusado') NOT NULL DEFAULT 'pendente',
  criado_em        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  respondido_em    DATETIME         NULL,
  PRIMARY KEY (id),
  KEY idx_conv_destinatario (destinatario_id, estado),
  CONSTRAINT fk_conv_remetente FOREIGN KEY (remetente_id) REFERENCES utilizadores (id) ON DELETE CASCADE,
  CONSTRAINT fk_conv_destinatario FOREIGN KEY (destinatario_id) REFERENCES utilizadores (id) ON DELETE CASCADE,
  CONSTRAINT fk_conv_modalidade FOREIGN KEY (modalidade_id) REFERENCES modalidades (id),
  CONSTRAINT ck_conv_pessoas CHECK (remetente_id <> destinatario_id)
) ENGINE=InnoDB;

-- -------------------------------------------------------------
-- 8. Avisos (notificações dentro da app)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notificacoes (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  utilizador_id  INT UNSIGNED NOT NULL,
  titulo         VARCHAR(150) NOT NULL,
  detalhe        VARCHAR(150) NOT NULL DEFAULT '',
  lida           BOOLEAN      NOT NULL DEFAULT FALSE,
  criado_em      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_notif_utilizador (utilizador_id, lida),
  CONSTRAINT fk_notif_utilizador FOREIGN KEY (utilizador_id) REFERENCES utilizadores (id) ON DELETE CASCADE
) ENGINE=InnoDB;
