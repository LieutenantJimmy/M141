-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 02_revoke_all.sql
-- Rollback der Rechte (für Tests, "negativ-positiv")
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'giovanni_benutzer'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'giovanni_manager'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'giovanni_dba'@'localhost';

DROP USER IF EXISTS 'giovanni_benutzer'@'localhost';
DROP USER IF EXISTS 'giovanni_manager'@'localhost';
DROP USER IF EXISTS 'giovanni_dba'@'localhost';

DROP ROLE IF EXISTS role_benutzer;
DROP ROLE IF EXISTS role_management;
FLUSH PRIVILEGES;
