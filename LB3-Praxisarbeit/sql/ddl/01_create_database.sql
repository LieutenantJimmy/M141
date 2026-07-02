-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 01_create_database.sql
-- Erstellt die personalisierte Datenbank
-- Autor: Giovanni Merola   ·   Datum: 30.06.2026
-- ============================================================

DROP DATABASE IF EXISTS backpacker_lb3_giovanni;
CREATE DATABASE backpacker_lb3_giovanni
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE      utf8mb4_unicode_ci;

USE backpacker_lb3_giovanni;

-- Sanity-Check
SELECT DATABASE() AS aktive_db,
       @@character_set_database AS charset,
       @@collation_database     AS collation;
