-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 40_testdaten_migration.sql
-- Erzeugt personalisierte Testdaten für Migrationstest
-- (eine vollständige End-to-End-Buchung mit Position)
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

-- 1. Test-Land (idempotent)
INSERT IGNORE INTO tbl_land (Land) VALUES ('Testland-Giovanni Merola');
SET @land_id := (SELECT Land_ID FROM tbl_land WHERE Land='Testland-Giovanni Merola');

-- 2. Test-Leistung
INSERT IGNORE INTO tbl_leistung (Beschreibung) VALUES ('Migrations-Testleistung Giovanni');
SET @leistung_id := (SELECT LeistungID FROM tbl_leistung WHERE Beschreibung='Migrations-Testleistung Giovanni');

-- 3. Test-Person
INSERT INTO tbl_personen (Titel, Vorname, Name, Strasse, PLZ, Ort, Anrede, Telefon, erfasst, Sprache)
VALUES ('Test', 'Migra', 'Giovanni-Test', 'Testweg 1', '8000', 'Zürich', 'Frau', '+41000', NOW(), 'de');
SET @person_id := LAST_INSERT_ID();

-- 4. Test-Benutzer (Empfang)
INSERT INTO tbl_benutzer (Benutzername, Password, Vorname, Name, Benutzergruppe, aktiv)
VALUES (CONCAT('a_test_',RIGHT(UNIX_TIMESTAMP(),8)), SHA2('Test!Giovanni-2026',256), 'Giovanni', 'Test', 1, 1);
SET @benutzer_id := LAST_INSERT_ID();

-- 5. Test-Buchung
INSERT INTO tbl_buchung (Personen_FS, Ankunft, Abreise, Land_FS)
VALUES (@person_id, NOW(), NOW() + INTERVAL 2 DAY, @land_id);
SET @buchung_id := LAST_INSERT_ID();

-- 6. Test-Position
INSERT INTO tbl_positionen
    (Buchungs_FS, Konto, Anzahl, Preis, Rabatt, Benutzer_FS, erfasst, Leistung_Text, Leistung_FS)
VALUES
    (@buchung_id, 3000, 2, 49.50, 10.00, @benutzer_id, NOW(),
     'Migrations-Testleistung Giovanni (Test)', @leistung_id);

-- 7. Kontrolle
SELECT b.Buchungs_ID, p.Vorname, p.Name, l.Land,
       po.Anzahl, po.Preis, po.Rabatt, u.Benutzername
FROM tbl_buchung b
JOIN tbl_personen p ON p.Personen_ID = b.Personen_FS
JOIN tbl_land l     ON l.Land_ID     = b.Land_FS
JOIN tbl_positionen po ON po.Buchungs_FS = b.Buchungs_ID
JOIN tbl_benutzer u    ON u.Benutzer_ID  = po.Benutzer_FS
WHERE p.Name = 'Giovanni-Test';
