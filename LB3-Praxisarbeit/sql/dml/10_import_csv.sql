-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 10_import_csv.sql
-- Import der originalen CSV-Dateien in Staging-Tabellen
-- Voraussetzung: secure_file_priv erlaubt das Verzeichnis ODER
--                Aufruf via `mysql --local-infile=1 -u avnadmin -p ...`
--                und `LOCAL` Keyword unten.
-- CSV-Pfad ggf. anpassen (Windows: C:/xampp/htdocs/lb3/csv/  /
-- Linux:   /var/lib/mysql-files/lb3/)
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

-- @csv_dir muss vor Ausführung gesetzt sein, z. B. mit:
--   SET @csv_dir := 'C:/lb3_csv/';                -- (XAMPP/Windows)
--   SET @csv_dir := '/var/lib/mysql-files/lb3/';  -- (Linux MariaDB)

-- ---------- tbl_land ----------
TRUNCATE TABLE stg_land;
LOAD DATA LOCAL INFILE 'C:/Users/Giovanni/Documents/GitHub/M141/LB3-Praxisarbeit/csv/tbl_land.csv'
INTO TABLE stg_land
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Land_ID, Land);

-- ---------- tbl_leistung ----------
TRUNCATE TABLE stg_leistung;
LOAD DATA LOCAL INFILE 'C:/Users/Giovanni/Documents/GitHub/M141/LB3-Praxisarbeit/csv/tbl_leistung.csv'
INTO TABLE stg_leistung
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(LeistungID, Beschreibung);

-- ---------- tbl_personen ----------
TRUNCATE TABLE stg_personen;
LOAD DATA LOCAL INFILE 'C:/Users/Giovanni/Documents/GitHub/M141/LB3-Praxisarbeit/csv/tbl_personen.csv'
INTO TABLE stg_personen
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Personen_ID, Titel, Vorname, Name, Strasse, PLZ, Ort, Anrede, Telefon, erfasst, Sprache);

-- ---------- tbl_benutzer ----------
TRUNCATE TABLE stg_benutzer;
LOAD DATA LOCAL INFILE 'C:/Users/Giovanni/Documents/GitHub/M141/LB3-Praxisarbeit/csv/tbl_benutzer.csv'
INTO TABLE stg_benutzer
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Benutzer_ID, Benutzername, Password, Vorname, Name, Benutzergruppe, erfasst, deaktiviert, aktiv);

-- ---------- tbl_buchung ----------
TRUNCATE TABLE stg_buchung;
LOAD DATA LOCAL INFILE 'C:/Users/Giovanni/Documents/GitHub/M141/LB3-Praxisarbeit/csv/tbl_buchung.csv'
INTO TABLE stg_buchung
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Buchungs_ID, Personen_FS, Ankunft, Abreise, Land_FS);

-- ---------- tbl_positionen ----------
TRUNCATE TABLE stg_positionen;
LOAD DATA LOCAL INFILE 'C:/Users/Giovanni/Documents/GitHub/M141/LB3-Praxisarbeit/csv/tbl_positionen.csv'
INTO TABLE stg_positionen
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Positions_ID, Buchungs_FS, Konto, Anzahl, Preis, Rabatt, Benutzer_FS, erfasst, Leistung_Text, Leistung_FS);

-- ---------- Importkontrolle ----------
SELECT 'stg_land'       AS tbl, COUNT(*) AS zeilen FROM stg_land
UNION ALL SELECT 'stg_leistung',   COUNT(*) FROM stg_leistung
UNION ALL SELECT 'stg_personen',   COUNT(*) FROM stg_personen
UNION ALL SELECT 'stg_benutzer',   COUNT(*) FROM stg_benutzer
UNION ALL SELECT 'stg_buchung',    COUNT(*) FROM stg_buchung
UNION ALL SELECT 'stg_positionen', COUNT(*) FROM stg_positionen;
