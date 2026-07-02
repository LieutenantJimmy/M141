-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 02_create_tables.sql
-- Normalisiertes Schema in 2.NF, InnoDB, FK + Indizes + CHECKs
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS tbl_positionen;
DROP TABLE IF EXISTS tbl_buchung;
DROP TABLE IF EXISTS tbl_benutzer;
DROP TABLE IF EXISTS tbl_personen;
DROP TABLE IF EXISTS tbl_land;
DROP TABLE IF EXISTS tbl_leistung;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------
-- tbl_land (Länderverzeichnis)
-- ----------------------------------------------------------------
CREATE TABLE tbl_land (
    Land_ID  INT          NOT NULL AUTO_INCREMENT,
    Land     VARCHAR(80)  NOT NULL,
    PRIMARY KEY (Land_ID),
    UNIQUE KEY uq_land_name (Land)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Verzeichnis der Herkunftsländer';

-- ----------------------------------------------------------------
-- tbl_leistung (Leistungskatalog)
-- ----------------------------------------------------------------
CREATE TABLE tbl_leistung (
    LeistungID    INT          NOT NULL AUTO_INCREMENT,
    Beschreibung  VARCHAR(70)  NOT NULL,
    PRIMARY KEY (LeistungID),
    UNIQUE KEY uq_leistung_beschr (Beschreibung)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Leistungskatalog (Übernachtung, Verpflegung etc.)';

-- ----------------------------------------------------------------
-- tbl_personen (Gäste)
-- ----------------------------------------------------------------
CREATE TABLE tbl_personen (
    Personen_ID  INT          NOT NULL AUTO_INCREMENT,
    Titel        VARCHAR(120) NULL,
    Vorname      VARCHAR(100) NULL,
    Name         VARCHAR(120) NOT NULL,
    Strasse      VARCHAR(150) NULL,
    PLZ          VARCHAR(30)  NULL,
    Ort          VARCHAR(120) NULL,
    Anrede       VARCHAR(120) NULL,
    Telefon      VARCHAR(60)  NULL,
    erfasst      DATETIME     NULL,
    Sprache      CHAR(2)      NULL,
    PRIMARY KEY (Personen_ID),
    KEY idx_personen_name (Name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Enthält alle Gäste';

-- ----------------------------------------------------------------
-- tbl_benutzer (Mitarbeitende mit Login)
-- ----------------------------------------------------------------
CREATE TABLE tbl_benutzer (
    Benutzer_ID    INT          NOT NULL AUTO_INCREMENT,
    Benutzername   VARCHAR(20)  NOT NULL,
    Password       VARCHAR(255) NULL,            -- Hash (bcrypt/SHA-2)
    Vorname        VARCHAR(40)  NULL,
    Name           VARCHAR(40)  NULL,
    Benutzergruppe TINYINT      NOT NULL DEFAULT 1,
    erfasst        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deaktiviert    DATE         NULL,
    aktiv          TINYINT      NOT NULL DEFAULT 1,
    PRIMARY KEY (Benutzer_ID),
    UNIQUE KEY uq_benutzer_name (Benutzername),
    CONSTRAINT chk_benutzer_aktiv  CHECK (aktiv IN (0,1)),
    CONSTRAINT chk_benutzer_gruppe CHECK (Benutzergruppe IN (1,2))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Mitarbeitende (1=Benutzer, 2=Management)';

-- ----------------------------------------------------------------
-- tbl_buchung (Kopf einer Übernachtung)
-- ----------------------------------------------------------------
CREATE TABLE tbl_buchung (
    Buchungs_ID  INT       NOT NULL AUTO_INCREMENT,
    Personen_FS  INT       NULL,
    Ankunft      DATETIME  NULL,
    Abreise      DATETIME  NULL,
    Land_FS      INT       NULL,
    PRIMARY KEY (Buchungs_ID),
    KEY idx_buchung_personen (Personen_FS),
    KEY idx_buchung_land     (Land_FS),
    KEY idx_buchung_ankunft  (Ankunft),
    CONSTRAINT fk_buchung_personen
        FOREIGN KEY (Personen_FS) REFERENCES tbl_personen(Personen_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_buchung_land
        FOREIGN KEY (Land_FS) REFERENCES tbl_land(Land_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_buchung_zeitraum
        CHECK (Abreise IS NULL OR Ankunft IS NULL OR Abreise >= Ankunft)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Buchungskopf (1 Buchung pro Aufenthalt)';

-- ----------------------------------------------------------------
-- tbl_positionen (Einzelpositionen pro Buchung)
-- ----------------------------------------------------------------
CREATE TABLE tbl_positionen (
    Positions_ID   INT           NOT NULL AUTO_INCREMENT,
    Buchungs_FS    INT           NULL,
    Konto          INT           NOT NULL DEFAULT 0,
    Anzahl         INT           NOT NULL DEFAULT 0,
    Preis          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Rabatt         DECIMAL(5,2)  NOT NULL DEFAULT 0.00,
    Benutzer_FS    INT           NULL,
    erfasst        DATETIME      NOT NULL DEFAULT '2000-01-01 00:00:00',
    Leistung_Text  VARCHAR(255)  NULL,
    Leistung_FS    INT           NULL,
    PRIMARY KEY (Positions_ID),
    KEY idx_pos_buchung  (Buchungs_FS),
    KEY idx_pos_benutzer (Benutzer_FS),
    KEY idx_pos_leistung (Leistung_FS),
    FULLTEXT KEY ft_pos_text (Leistung_Text),
    CONSTRAINT fk_pos_buchung
        FOREIGN KEY (Buchungs_FS) REFERENCES tbl_buchung(Buchungs_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pos_benutzer
        FOREIGN KEY (Benutzer_FS) REFERENCES tbl_benutzer(Benutzer_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pos_leistung
        FOREIGN KEY (Leistung_FS) REFERENCES tbl_leistung(LeistungID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- chk_pos_anzahl und chk_pos_preis bewusst entfernt: das reale
    -- Quellsystem führt Stornos/Korrekturen als negative Werte
    -- (Anzahl < 0, Preis < 0). Eine zu strikte Prüfung würde die
    -- legitime Geschäftslogik blockieren.
    CONSTRAINT chk_pos_rabatt CHECK (Rabatt  BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Buchungspositionen';

-- Strukturkontrolle
SHOW TABLES;
