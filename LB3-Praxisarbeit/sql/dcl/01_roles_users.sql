-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 01_roles_users.sql
-- DCL: Rollen + personalisierte Benutzer gemäss Zugriffsmatrix
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

-- ----------------------------------------------------------------
-- 1. Rollen aufräumen (idempotent)
-- ----------------------------------------------------------------
DROP ROLE IF EXISTS role_benutzer;
DROP ROLE IF EXISTS role_management;

CREATE ROLE role_benutzer;
CREATE ROLE role_management;

-- ----------------------------------------------------------------
-- 2. ROLE_BENUTZER  (Empfang)
--    – tbl_personen:        S, U
--    – tbl_benutzer.Password:   keine Rechte
--    – tbl_benutzer.deaktiviert: nur S
--    – tbl_benutzer Rest:   S, I, U  (kein D)
--    – tbl_buchung:         S, I, U, D
--    – tbl_positionen:      S, I, U, D
--    – tbl_land, tbl_leistung: nur S
-- ----------------------------------------------------------------
GRANT SELECT, UPDATE ON backpacker_lb3_giovanni.tbl_personen TO role_benutzer;

GRANT SELECT (Benutzer_ID, Benutzername, Vorname, Name, Benutzergruppe,
              erfasst, deaktiviert, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
GRANT INSERT (Benutzername, Vorname, Name, Benutzergruppe, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
GRANT UPDATE (Benutzername, Vorname, Name, Benutzergruppe, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
-- bewusst kein GRANT auf Password und kein DELETE

GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_buchung    TO role_benutzer;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_positionen TO role_benutzer;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_land      TO role_benutzer;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_leistung  TO role_benutzer;

-- ----------------------------------------------------------------
-- 3. ROLE_MANAGEMENT
--    – tbl_buchung, tbl_positionen: nur S
--    – Rest: S, I, U, D
-- ----------------------------------------------------------------
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_buchung    TO role_management;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_positionen TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_personen   TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_benutzer   TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_land       TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_leistung   TO role_management;

-- ----------------------------------------------------------------
-- 4. Benutzer (personalisiert mit "giovanni")
--    Passwörter sind Beispiele – im Repo NUR Platzhalter "__PWD__"
--    verwenden und produktiv via Secrets Manager setzen.
-- ----------------------------------------------------------------
DROP USER IF EXISTS 'giovanni_benutzer'@'localhost';
DROP USER IF EXISTS 'giovanni_manager'@'localhost';
DROP USER IF EXISTS 'giovanni_dba'@'localhost';

CREATE USER 'giovanni_benutzer'@'localhost' IDENTIFIED BY 'Benutzer!Giovanni-2026';
CREATE USER 'giovanni_manager'@'localhost'  IDENTIFIED BY 'Manager!Giovanni-2026';
CREATE USER 'giovanni_dba'@'localhost'      IDENTIFIED BY 'Dba!Giovanni-2026';

-- Cloud-Variante (Wildcard-Host nur bei Bedarf, hier dokumentiert):
-- CREATE USER 'giovanni_benutzer'@'%' IDENTIFIED BY '__PWD__'
--   REQUIRE SSL;

-- ----------------------------------------------------------------
-- 5. Rollen zuweisen
-- ----------------------------------------------------------------
GRANT role_benutzer   TO 'giovanni_benutzer'@'localhost';
GRANT role_management TO 'giovanni_manager'@'localhost';
GRANT ALL PRIVILEGES  ON backpacker_lb3_giovanni.* TO 'giovanni_dba'@'localhost' WITH GRANT OPTION;

-- Default-Rolle = bei Login automatisch aktiv
SET DEFAULT ROLE role_benutzer   FOR 'giovanni_benutzer'@'localhost';
SET DEFAULT ROLE role_management FOR 'giovanni_manager'@'localhost';

FLUSH PRIVILEGES;

-- ----------------------------------------------------------------
-- 6. Kontrolle
-- ----------------------------------------------------------------
SELECT User, Host, default_role FROM mysql.user WHERE User LIKE 'giovanni_%';
SHOW GRANTS FOR role_benutzer;
SHOW GRANTS FOR role_management;
SHOW GRANTS FOR 'giovanni_benutzer'@'localhost';
SHOW GRANTS FOR 'giovanni_manager'@'localhost';
