-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 60_tests_roles.sql
-- Positiv-/Negativ-Tests für Rollen.
-- Auszuführen als jeweiliger User per separater mysql-Session:
--   mysql -u giovanni_benutzer -p -h localhost backpacker_lb3_giovanni < 60_tests_roles.sql
-- Erwartungen sind im Kommentar pro Statement angegeben.
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;
SELECT CURRENT_USER() AS aktueller_user, CURRENT_ROLE() AS aktive_rolle;

-- ======================
-- A) ROLE_BENUTZER
-- ======================

-- A-01 POSITIV: SELECT auf tbl_personen
SELECT COUNT(*) AS personen_visible FROM tbl_personen;                         -- erwartet: OK

-- A-02 POSITIV: UPDATE eines Gastes
UPDATE tbl_personen SET Telefon='+41 000 000' WHERE Personen_ID = 1;            -- erwartet: OK

-- A-03 NEGATIV: DELETE auf tbl_personen  -> erwartet: 1142 ERROR
-- DELETE FROM tbl_personen WHERE Personen_ID = 1;

-- A-04 NEGATIV: SELECT Password
-- SELECT Password FROM tbl_benutzer LIMIT 1;                                   -- erwartet: 1143 ERROR (column denied)

-- A-05 POSITIV: SELECT erlaubte Spalten in tbl_benutzer
SELECT Benutzer_ID, Benutzername, aktiv, deaktiviert FROM tbl_benutzer LIMIT 5; -- erwartet: OK

-- A-06 NEGATIV: UPDATE deaktiviert  -> erwartet: 1143 ERROR
-- UPDATE tbl_benutzer SET deaktiviert = CURDATE() WHERE Benutzer_ID = 1;

-- A-07 POSITIV: INSERT/UPDATE/DELETE auf tbl_buchung
INSERT INTO tbl_buchung (Personen_FS, Ankunft, Abreise, Land_FS)
       VALUES (1, NOW(), NOW()+INTERVAL 1 DAY, 1);                              -- erwartet: OK
SET @bid := LAST_INSERT_ID();
UPDATE tbl_buchung SET Abreise = NOW() + INTERVAL 3 DAY WHERE Buchungs_ID=@bid; -- erwartet: OK
DELETE FROM tbl_buchung WHERE Buchungs_ID=@bid;                                 -- erwartet: OK

-- A-08 NEGATIV: INSERT in tbl_leistung  -> erwartet: 1142 ERROR
-- INSERT INTO tbl_leistung (Beschreibung) VALUES ('Sollte verboten sein');

-- ======================
-- B) ROLE_MANAGEMENT
-- ======================

-- B-01 POSITIV: SELECT auf tbl_personen
SELECT COUNT(*) FROM tbl_personen;                                              -- erwartet: OK

-- B-02 POSITIV: INSERT in tbl_leistung
INSERT INTO tbl_leistung (Beschreibung) VALUES ('Manager-Testleistung Giovanni');   -- erwartet: OK
DELETE FROM tbl_leistung WHERE Beschreibung='Manager-Testleistung Giovanni';        -- erwartet: OK

-- B-03 POSITIV: UPDATE Password
UPDATE tbl_benutzer SET Password = SHA2('NewPwd_Giovanni!2026',256) WHERE Benutzer_ID=1;   -- erwartet: OK

-- B-04 NEGATIV: INSERT in tbl_buchung  -> erwartet: 1142 ERROR (nur SELECT)
-- INSERT INTO tbl_buchung (Personen_FS, Ankunft, Abreise, Land_FS) VALUES (1, NOW(), NOW()+INTERVAL 1 DAY, 1);

-- B-05 NEGATIV: UPDATE tbl_positionen  -> erwartet: 1142 ERROR
-- UPDATE tbl_positionen SET Preis = 0 WHERE Positions_ID=1;
