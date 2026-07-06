-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola (CLOUD-Variante)
-- 03_cloud_users.sql  (EVALUIERTE AIVEN-VARIANTE - nicht produktiv;
--                     produktiv: 04_selfhosted_cloud_users.sql, eigene Cloud)
-- Cloud-DCL für Aiven for MySQL 8:
--   Rollen + User mit REQUIRE SSL und %-Host.
-- Auszuführen NACHDEM die Schema-Migration in die Cloud-DB
-- backpacker_lb3_giovanni abgeschlossen ist.
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

-- Rollen identisch zur lokalen Variante
DROP ROLE IF EXISTS role_benutzer;
DROP ROLE IF EXISTS role_management;
CREATE ROLE role_benutzer;
CREATE ROLE role_management;

-- ROLE_BENUTZER (Empfang)
GRANT SELECT, UPDATE ON backpacker_lb3_giovanni.tbl_personen TO role_benutzer;

GRANT SELECT (Benutzer_ID, Benutzername, Vorname, Name, Benutzergruppe,
              erfasst, deaktiviert, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
GRANT INSERT (Benutzername, Vorname, Name, Benutzergruppe, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
GRANT UPDATE (Benutzername, Vorname, Name, Benutzergruppe, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;

GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_buchung    TO role_benutzer;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_positionen TO role_benutzer;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_land      TO role_benutzer;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_leistung  TO role_benutzer;

-- ROLE_MANAGEMENT
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_buchung    TO role_management;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_positionen TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_personen   TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_benutzer   TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_land       TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_leistung   TO role_management;

-- ----------------------------------------------------------------
-- Cloud-User mit TLS-Pflicht
-- ----------------------------------------------------------------
DROP USER IF EXISTS 'giovanni_benutzer'@'%';
DROP USER IF EXISTS 'giovanni_manager'@'%';
DROP USER IF EXISTS 'giovanni_dba'@'%';

-- MySQL 8 Syntax: IDENTIFIED BY ... REQUIRE SSL
CREATE USER 'giovanni_benutzer'@'%' IDENTIFIED BY 'Cloud!Benutzer-Giovanni-2026' REQUIRE SSL;
CREATE USER 'giovanni_manager'@'%'  IDENTIFIED BY 'Cloud!Manager-Giovanni-2026'  REQUIRE SSL;
CREATE USER 'giovanni_dba'@'%'      IDENTIFIED BY 'Cloud!Dba-Giovanni-2026'      REQUIRE SSL;

GRANT role_benutzer   TO 'giovanni_benutzer'@'%';
GRANT role_management TO 'giovanni_manager'@'%';
GRANT ALL PRIVILEGES  ON backpacker_lb3_giovanni.* TO 'giovanni_dba'@'%' WITH GRANT OPTION;

-- MySQL 8: SET DEFAULT ROLE wirkt direkt
SET DEFAULT ROLE role_benutzer   TO 'giovanni_benutzer'@'%';
SET DEFAULT ROLE role_management TO 'giovanni_manager'@'%';

FLUSH PRIVILEGES;

-- Kontrolle (MySQL 8 verwendet mysql.default_roles statt mysql.user.default_role)
SELECT User, Host, ssl_type FROM mysql.user WHERE User LIKE 'giovanni_%';
SELECT * FROM mysql.default_roles WHERE USER LIKE 'giovanni_%';
SHOW GRANTS FOR role_benutzer;
SHOW GRANTS FOR role_management;
SHOW GRANTS FOR 'giovanni_benutzer'@'%';
SHOW GRANTS FOR 'giovanni_manager'@'%';
