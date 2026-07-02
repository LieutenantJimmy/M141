-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola (EIGENE CLOUD)
-- 04_selfhosted_cloud_users.sql
-- DCL für die selbstgehostete Cloud-DB (cloud-db-giovanni,
-- MariaDB 11.8 im LXC auf Proxmox "freya", Endpoint 192.168.1.62).
--
-- Unterschiede zur lokalen 01_roles_users.sql:
--   • Host '%' statt 'localhost' (Zugriff aus dem LAN)
--   • REQUIRE SSL pro User (zusätzlich zu require_secure_transport=ON)
-- MariaDB-Rollen-Syntax (SET DEFAULT ROLE ... FOR ...), NICHT MySQL 8.
--
-- Auszuführen NACH der Schema-/Daten-Migration in die Cloud-DB.
-- Autor: Giovanni Merola · 02.07.2026
-- ============================================================

USE backpacker_lb3_giovanni;

-- 1. Rollen (idempotent) --------------------------------------
DROP ROLE IF EXISTS role_benutzer;
DROP ROLE IF EXISTS role_management;
CREATE ROLE role_benutzer;
CREATE ROLE role_management;

-- 2. ROLE_BENUTZER (Empfang) ----------------------------------
GRANT SELECT, UPDATE ON backpacker_lb3_giovanni.tbl_personen TO role_benutzer;

GRANT SELECT (Benutzer_ID, Benutzername, Vorname, Name, Benutzergruppe,
              erfasst, deaktiviert, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
GRANT INSERT (Benutzername, Vorname, Name, Benutzergruppe, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
GRANT UPDATE (Benutzername, Vorname, Name, Benutzergruppe, aktiv)
      ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
-- bewusst kein Recht auf Password, kein DELETE

GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_buchung    TO role_benutzer;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_positionen TO role_benutzer;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_land       TO role_benutzer;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_leistung   TO role_benutzer;

-- 3. ROLE_MANAGEMENT ------------------------------------------
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_buchung    TO role_management;
GRANT SELECT                         ON backpacker_lb3_giovanni.tbl_positionen TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_personen   TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_benutzer   TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_land       TO role_management;
GRANT SELECT, INSERT, UPDATE, DELETE ON backpacker_lb3_giovanni.tbl_leistung   TO role_management;

-- 4. Cloud-User mit TLS-Pflicht (%-Host, REQUIRE SSL) ---------
DROP USER IF EXISTS 'giovanni_benutzer'@'%';
DROP USER IF EXISTS 'giovanni_manager'@'%';
DROP USER IF EXISTS 'giovanni_dba'@'%';

CREATE USER 'giovanni_benutzer'@'%' IDENTIFIED BY 'Cloud!Benutzer-Giovanni-2026' REQUIRE SSL;
CREATE USER 'giovanni_manager'@'%'  IDENTIFIED BY 'Cloud!Manager-Giovanni-2026'  REQUIRE SSL;
CREATE USER 'giovanni_dba'@'%'      IDENTIFIED BY 'Cloud!Dba-Giovanni-2026'      REQUIRE SSL;

-- 5. Rollen zuweisen ------------------------------------------
GRANT role_benutzer   TO 'giovanni_benutzer'@'%';
GRANT role_management TO 'giovanni_manager'@'%';
GRANT ALL PRIVILEGES  ON backpacker_lb3_giovanni.* TO 'giovanni_dba'@'%' WITH GRANT OPTION;

SET DEFAULT ROLE role_benutzer   FOR 'giovanni_benutzer'@'%';
SET DEFAULT ROLE role_management FOR 'giovanni_manager'@'%';

FLUSH PRIVILEGES;

-- 6. Kontrolle ------------------------------------------------
SELECT User, Host, ssl_type, default_role FROM mysql.user WHERE User LIKE 'giovanni_%';
SHOW GRANTS FOR role_benutzer;
SHOW GRANTS FOR role_management;
SHOW GRANTS FOR 'giovanni_benutzer'@'%';
SHOW GRANTS FOR 'giovanni_manager'@'%';
