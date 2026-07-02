-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 70_tests_cloud.sql
-- Cloud-Smoke-Tests: Datenkonsistenz nach Migration
-- Auszuführen als avnadmin (Master) gegen die Cloud-DB.
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

-- ===== KONSISTENZ =====
SELECT 'C-D-01 Zeilen pro Tabelle' AS test;
SELECT 'tbl_personen'   t, COUNT(*) c FROM tbl_personen   UNION ALL
SELECT 'tbl_benutzer'    , COUNT(*)   FROM tbl_benutzer   UNION ALL
SELECT 'tbl_land'        , COUNT(*)   FROM tbl_land       UNION ALL
SELECT 'tbl_leistung'    , COUNT(*)   FROM tbl_leistung   UNION ALL
SELECT 'tbl_buchung'     , COUNT(*)   FROM tbl_buchung    UNION ALL
SELECT 'tbl_positionen'  , COUNT(*)   FROM tbl_positionen;

SELECT 'C-D-02 Foreign Keys aktiv?' AS test;
SELECT COUNT(*) AS fk_anzahl
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA='backpacker_lb3_giovanni';  -- erwartet 5

SELECT 'C-D-03 Charset' AS test;
SELECT DEFAULT_CHARACTER_SET_NAME FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME='backpacker_lb3_giovanni';        -- erwartet utf8mb4

SELECT 'C-D-04 TLS aktiv?' AS test;
SHOW VARIABLES LIKE 'have_ssl';                  -- erwartet YES
SHOW VARIABLES LIKE 'require_secure_transport';  -- erwartet ON

SELECT 'C-D-05 Rollen vorhanden?' AS test;
SELECT User, Host FROM mysql.user WHERE User LIKE 'role_%';

SELECT 'C-D-06 User-Rollenzuweisung' AS test;
SHOW GRANTS FOR 'giovanni_benutzer'@'%';
SHOW GRANTS FOR 'giovanni_manager'@'%';

SELECT 'C-D-07 Migrierte Testdaten enthalten?' AS test;
SELECT COUNT(*) FROM tbl_personen WHERE Name = 'Giovanni-Test';   -- erwartet >= 1

-- ===== Beispiel-Reports (DQL) =====
SELECT 'R-01 Top10 Länder nach Buchungen' AS report;
SELECT l.Land, COUNT(*) AS buchungen
FROM tbl_buchung b
JOIN tbl_land l ON l.Land_ID = b.Land_FS
GROUP BY l.Land
ORDER BY buchungen DESC LIMIT 10;

SELECT 'R-02 Umsatz pro Benutzer (Empfang)' AS report;
SELECT u.Benutzername,
       ROUND(SUM(p.Anzahl * p.Preis * (1 - p.Rabatt/100)),2) AS umsatz
FROM tbl_positionen p
JOIN tbl_benutzer  u ON u.Benutzer_ID = p.Benutzer_FS
GROUP BY u.Benutzername
ORDER BY umsatz DESC;

SELECT 'R-03 Buchungen mit > 5 Positionen' AS report;
SELECT b.Buchungs_ID, COUNT(*) AS positionen
FROM tbl_buchung b
JOIN tbl_positionen p ON p.Buchungs_FS = b.Buchungs_ID
GROUP BY b.Buchungs_ID
HAVING COUNT(*) > 5
ORDER BY positionen DESC LIMIT 20;
