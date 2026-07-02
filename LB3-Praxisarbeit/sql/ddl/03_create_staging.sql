-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 03_create_staging.sql
-- Staging-Tabellen (alle Felder VARCHAR, keine FKs) für CSV-Import
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

DROP TABLE IF EXISTS stg_personen;
DROP TABLE IF EXISTS stg_benutzer;
DROP TABLE IF EXISTS stg_buchung;
DROP TABLE IF EXISTS stg_positionen;
DROP TABLE IF EXISTS stg_land;
DROP TABLE IF EXISTS stg_leistung;

CREATE TABLE stg_personen (
    Personen_ID VARCHAR(20),
    Titel       VARCHAR(255),
    Vorname     VARCHAR(255),
    Name        VARCHAR(255),
    Strasse     VARCHAR(255),
    PLZ         VARCHAR(20),
    Ort         VARCHAR(255),
    Anrede      VARCHAR(50),
    Telefon     VARCHAR(60),
    erfasst     VARCHAR(40),
    Sprache     VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stg_benutzer (
    Benutzer_ID    VARCHAR(20),
    Benutzername   VARCHAR(50),
    Password       VARCHAR(255),
    Vorname        VARCHAR(60),
    Name           VARCHAR(60),
    Benutzergruppe VARCHAR(10),
    erfasst        VARCHAR(40),
    deaktiviert    VARCHAR(40),
    aktiv          VARCHAR(10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stg_buchung (
    Buchungs_ID VARCHAR(20),
    Personen_FS VARCHAR(20),
    Ankunft     VARCHAR(40),
    Abreise     VARCHAR(40),
    Land_FS     VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stg_positionen (
    Positions_ID  VARCHAR(20),
    Buchungs_FS   VARCHAR(20),
    Konto         VARCHAR(20),
    Anzahl        VARCHAR(20),
    Preis         VARCHAR(20),
    Rabatt        VARCHAR(20),
    Benutzer_FS   VARCHAR(20),
    erfasst       VARCHAR(40),
    Leistung_Text VARCHAR(255),
    Leistung_FS   VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stg_land (
    Land_ID VARCHAR(20),
    Land    VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stg_leistung (
    LeistungID   VARCHAR(20),
    Beschreibung VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
