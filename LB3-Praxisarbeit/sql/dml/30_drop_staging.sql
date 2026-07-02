-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 30_drop_staging.sql
-- Nach erfolgreichem Cleanup werden die Stagings entfernt.
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;
DROP TABLE IF EXISTS stg_personen;
DROP TABLE IF EXISTS stg_benutzer;
DROP TABLE IF EXISTS stg_buchung;
DROP TABLE IF EXISTS stg_positionen;
DROP TABLE IF EXISTS stg_land;
DROP TABLE IF EXISTS stg_leistung;
SHOW TABLES;
