-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 50_data_consistency.sql
-- Konsistenz- und Qualitätsabfragen (DQL) für Testprotokolle
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

-- T-D-01: Zeilenzahlen pro Tabelle
SELECT 'tbl_personen'   AS tbl, COUNT(*) AS zeilen FROM tbl_personen
UNION ALL SELECT 'tbl_benutzer'   , COUNT(*) FROM tbl_benutzer
UNION ALL SELECT 'tbl_land'       , COUNT(*) FROM tbl_land
UNION ALL SELECT 'tbl_leistung'   , COUNT(*) FROM tbl_leistung
UNION ALL SELECT 'tbl_buchung'    , COUNT(*) FROM tbl_buchung
UNION ALL SELECT 'tbl_positionen' , COUNT(*) FROM tbl_positionen;

-- T-D-02: Verwaiste FK – Buchungen ohne Person
SELECT COUNT(*) AS verwaiste_buchung_person
FROM tbl_buchung b LEFT JOIN tbl_personen p ON p.Personen_ID = b.Personen_FS
WHERE b.Personen_FS IS NOT NULL AND p.Personen_ID IS NULL;

-- T-D-03: Buchungen mit Land_FS=0 (Sentinel) – muss 0 sein
SELECT COUNT(*) AS sentinel_land_in_buchung
FROM tbl_buchung WHERE Land_FS = 0;

-- T-D-04: Positionen ohne gültige Buchung
SELECT COUNT(*) AS verwaiste_pos_buchung
FROM tbl_positionen p LEFT JOIN tbl_buchung b ON b.Buchungs_ID = p.Buchungs_FS
WHERE p.Buchungs_FS IS NOT NULL AND b.Buchungs_ID IS NULL;

-- T-D-05: Positionen ohne gültige Leistung-FK (Leistung_Text bleibt erlaubt)
SELECT COUNT(*) AS pos_ohne_leistung_fk
FROM tbl_positionen p LEFT JOIN tbl_leistung le ON le.LeistungID = p.Leistung_FS
WHERE p.Leistung_FS IS NOT NULL AND le.LeistungID IS NULL;

-- T-D-06: Benutzer mit Sentinel-Deaktivierung – muss 0 sein
SELECT COUNT(*) AS sentinel_deaktiviert FROM tbl_benutzer WHERE deaktiviert = '1000-01-01';

-- T-D-07: Buchungen mit Abreise vor Ankunft – muss 0 sein
SELECT COUNT(*) AS rueckwaertsbuchung
FROM tbl_buchung WHERE Ankunft IS NOT NULL AND Abreise IS NOT NULL AND Abreise < Ankunft;

-- T-D-08a: Erzwungener CHECK (chk_pos_rabatt): Rabatt ausserhalb 0-100 – muss 0 sein
SELECT COUNT(*) AS rabatt_check_verletzt
FROM tbl_positionen
WHERE Rabatt < 0 OR Rabatt > 100;

-- T-D-08b: Negative Anzahl/Preis sind BEWUSST erlaubt (Stornos/Korrekturen,
--          siehe Kommentar in 02_create_tables.sql). Hier nur informativ
--          ausgewiesen, damit die Datenqualitaet nachvollziehbar bleibt.
SELECT
    SUM(Anzahl < 0)              AS stornos_anzahl_negativ,
    SUM(Preis  < 0)              AS stornos_preis_negativ,
    SUM(Anzahl < 0 OR Preis < 0) AS stornos_zeilen_total
FROM tbl_positionen;

-- T-D-09: doppelte Benutzernamen – muss 0 sein
SELECT Benutzername, COUNT(*) cnt FROM tbl_benutzer
GROUP BY Benutzername HAVING cnt > 1;

-- T-D-10: Indizes vorhanden?
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA='backpacker_lb3_giovanni'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- T-D-11: FK-Constraints vorhanden?
SELECT CONSTRAINT_NAME, TABLE_NAME, REFERENCED_TABLE_NAME
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA='backpacker_lb3_giovanni';

-- T-D-12: Zeichensatz aller Tabellen
SELECT TABLE_NAME, TABLE_COLLATION
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='backpacker_lb3_giovanni';
