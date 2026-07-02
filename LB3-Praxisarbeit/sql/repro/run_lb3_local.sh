#!/usr/bin/env bash
# ================================================================
# M141 LB3 - Backpacker_LB3 - Reproduktions-Driver (Giovanni Merola)
# Laeuft auf freya (Debian 13). Installiert MariaDB, fuehrt die
# gesamte lokale Pipeline aus und erfasst alle Proof-Outputs.
# ================================================================
set -uo pipefail
DB=backpacker_lb3_giovanni
BASE=/root/lb3
OUT=$BASE/out
mkdir -p "$OUT"
CSV=$BASE/csv

echo "### [1/9] MariaDB installieren ###"
export DEBIAN_FRONTEND=noninteractive
if ! command -v mariadb >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq mariadb-server mariadb-client >/dev/null
fi
systemctl enable --now mariadb >/dev/null 2>&1
mariadb --version | tee "$OUT/00_version.txt"

# local_infile serverseitig sicherstellen
mysql -e "SET GLOBAL local_infile=1;"

# CSV-Pfad im Importskript auf Linux umbiegen
sed -i "s#C:/Users/Giovanni/Documents/GitHub/M141/LB3-Praxisarbeit/csv/#$CSV/#g" "$BASE/sql/dml/10_import_csv.sql"

MYSQL="mysql --local-infile=1"

echo "### [2/9] DDL: Datenbank + Schema + Staging ###"
$MYSQL < "$BASE/sql/ddl/01_create_database.sql"    2>&1 | tee "$OUT/01_create_database.txt"
$MYSQL "$DB" < "$BASE/sql/ddl/02_create_tables.sql" 2>&1 | tee "$OUT/02_create_tables.txt"
$MYSQL "$DB" < "$BASE/sql/ddl/03_create_staging.sql" 2>&1 | tee "$OUT/03_create_staging.txt"

echo "### [3/9] DML: Import CSV -> Staging ###"
$MYSQL "$DB" < "$BASE/sql/dml/10_import_csv.sql"     2>&1 | tee "$OUT/10_import_csv.txt"

echo "### [4/9] DML: Cleanup + Load in Zieltabellen ###"
$MYSQL "$DB" < "$BASE/sql/dml/20_cleanup_and_load.sql" 2>&1 | tee "$OUT/20_cleanup_and_load.txt"
$MYSQL "$DB" < "$BASE/sql/dml/30_drop_staging.sql"   2>&1 | tee "$OUT/30_drop_staging.txt"

echo "### [5/9] DCL: Rollen + personalisierte User ###"
$MYSQL "$DB" < "$BASE/sql/dcl/01_roles_users.sql"    2>&1 | tee "$OUT/dcl_01_roles_users.txt"

echo "### [6/9] DML: Migrations-Testdatensatz Giovanni ###"
$MYSQL "$DB" < "$BASE/sql/dml/40_testdaten_migration.sql" 2>&1 | tee "$OUT/40_testdaten_migration.txt"

echo "### [7/9] DQL: Datenkonsistenz-Tests (T-D-01..12) ###"
$MYSQL "$DB" -t < "$BASE/sql/dql/50_data_consistency.sql" 2>&1 | tee "$OUT/50_data_consistency.txt"

echo "### [7b] phpMyAdmin-Aequivalent: DB-Uebersicht + FK-Constraints ###"
$MYSQL "$DB" -t -e "
SELECT TABLE_NAME AS 'Tabelle', ENGINE AS 'Engine', TABLE_ROWS AS 'Zeilen (ca.)', TABLE_COLLATION AS 'Kollation'
FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB' ORDER BY TABLE_NAME;
SELECT 'ECHTE Zeilenzahlen' AS Hinweis;
SELECT 'tbl_personen' t, COUNT(*) n FROM tbl_personen
UNION ALL SELECT 'tbl_benutzer', COUNT(*) FROM tbl_benutzer
UNION ALL SELECT 'tbl_land', COUNT(*) FROM tbl_land
UNION ALL SELECT 'tbl_leistung', COUNT(*) FROM tbl_leistung
UNION ALL SELECT 'tbl_buchung', COUNT(*) FROM tbl_buchung
UNION ALL SELECT 'tbl_positionen', COUNT(*) FROM tbl_positionen;
" 2>&1 | tee "$OUT/pma_db_uebersicht.txt"

$MYSQL "$DB" -t -e "
SELECT rc.CONSTRAINT_NAME AS 'FK-Constraint', rc.TABLE_NAME AS 'Tabelle',
       kcu.COLUMN_NAME AS 'Spalte', rc.REFERENCED_TABLE_NAME AS 'Ref-Tabelle',
       kcu.REFERENCED_COLUMN_NAME AS 'Ref-Spalte',
       rc.UPDATE_RULE AS 'ON UPDATE', rc.DELETE_RULE AS 'ON DELETE'
FROM information_schema.REFERENTIAL_CONSTRAINTS rc
JOIN information_schema.KEY_COLUMN_USAGE kcu
  ON kcu.CONSTRAINT_NAME=rc.CONSTRAINT_NAME AND kcu.CONSTRAINT_SCHEMA=rc.CONSTRAINT_SCHEMA
WHERE rc.CONSTRAINT_SCHEMA='$DB' ORDER BY rc.TABLE_NAME;
" 2>&1 | tee "$OUT/pma_fk_constraints.txt"

echo "### [8/9] DCL-Beweis: SHOW GRANTS je User/Rolle ###"
$MYSQL -t -e "SELECT User, Host, default_role FROM mysql.user WHERE User LIKE 'giovanni_%';" 2>&1 | tee "$OUT/users_grants.txt"
for u in giovanni_benutzer giovanni_manager giovanni_dba; do
  echo "===== SHOW GRANTS FOR '$u'@'localhost' =====" | tee -a "$OUT/users_grants.txt"
  $MYSQL -e "SHOW GRANTS FOR '$u'@'localhost';" 2>&1 | tee -a "$OUT/users_grants.txt"
done
echo "===== SHOW GRANTS FOR role_benutzer =====" | tee -a "$OUT/users_grants.txt"
$MYSQL -e "SHOW GRANTS FOR role_benutzer;"   2>&1 | tee -a "$OUT/users_grants.txt"
echo "===== SHOW GRANTS FOR role_management =====" | tee -a "$OUT/users_grants.txt"
$MYSQL -e "SHOW GRANTS FOR role_management;" 2>&1 | tee -a "$OUT/users_grants.txt"

echo "### [9/9] Rollen-Tests POSITIV + NEGATIV ###"
BEN="mysql -u giovanni_benutzer -pBenutzer!Giovanni-2026 -h 127.0.0.1 $DB"
MAN="mysql -u giovanni_manager  -pManager!Giovanni-2026  -h 127.0.0.1 $DB"

{
echo "################ ROLLEN-TESTS (personalisiert Giovanni) ################"
echo "Zeitpunkt: $(date '+%Y-%m-%d %H:%M:%S')  Host: $(hostname)  Server: freya/MariaDB"
echo
echo "========================================================"
echo " A) ROLE_BENUTZER  (User: giovanni_benutzer)"
echo "========================================================"
echo "[A-00] Identitaet + aktive Rolle"
$BEN -N -e "SELECT CURRENT_USER(), CURRENT_ROLE();" 2>&1
echo
echo "[A-01 POSITIV] SELECT COUNT(*) tbl_personen  -> erwartet OK"
$BEN -e "SELECT COUNT(*) AS personen_sichtbar FROM tbl_personen;" 2>&1
echo
echo "[A-02 POSITIV] UPDATE tbl_personen  -> erwartet OK"
$BEN -e "UPDATE tbl_personen SET Telefon='+41 000 000' WHERE Personen_ID=1; SELECT ROW_COUNT() AS geaendert;" 2>&1
echo
echo "[A-03 NEGATIV] DELETE tbl_personen  -> erwartet FEHLER 1142"
$BEN -e "DELETE FROM tbl_personen WHERE Personen_ID=1;" 2>&1
echo
echo "[A-04 NEGATIV] SELECT Password  -> erwartet FEHLER 1143 (Spalte gesperrt)"
$BEN -e "SELECT Password FROM tbl_benutzer LIMIT 1;" 2>&1
echo
echo "[A-05 POSITIV] SELECT erlaubte Spalten tbl_benutzer  -> erwartet OK"
$BEN -e "SELECT Benutzer_ID, Benutzername, aktiv, deaktiviert FROM tbl_benutzer LIMIT 3;" 2>&1
echo
echo "[A-06 NEGATIV] UPDATE Spalte deaktiviert  -> erwartet FEHLER 1143"
$BEN -e "UPDATE tbl_benutzer SET deaktiviert=CURDATE() WHERE Benutzer_ID=1;" 2>&1
echo
echo "[A-07 POSITIV] INSERT/UPDATE/DELETE tbl_buchung  -> erwartet OK"
$BEN -e "INSERT INTO tbl_buchung (Personen_FS,Ankunft,Abreise,Land_FS) VALUES (1,NOW(),NOW()+INTERVAL 1 DAY,1); SET @b:=LAST_INSERT_ID(); UPDATE tbl_buchung SET Abreise=NOW()+INTERVAL 3 DAY WHERE Buchungs_ID=@b; DELETE FROM tbl_buchung WHERE Buchungs_ID=@b; SELECT 'insert+update+delete ok' AS ergebnis;" 2>&1
echo
echo "[A-08 NEGATIV] INSERT tbl_leistung  -> erwartet FEHLER 1142 (nur SELECT)"
$BEN -e "INSERT INTO tbl_leistung (Beschreibung) VALUES ('Sollte verboten sein');" 2>&1
echo
echo "========================================================"
echo " B) ROLE_MANAGEMENT  (User: giovanni_manager)"
echo "========================================================"
echo "[B-00] Identitaet + aktive Rolle"
$MAN -N -e "SELECT CURRENT_USER(), CURRENT_ROLE();" 2>&1
echo
echo "[B-01 POSITIV] SELECT COUNT(*) tbl_personen  -> erwartet OK"
$MAN -e "SELECT COUNT(*) FROM tbl_personen;" 2>&1
echo
echo "[B-02 POSITIV] INSERT+DELETE tbl_leistung  -> erwartet OK"
$MAN -e "INSERT INTO tbl_leistung (Beschreibung) VALUES ('Manager-Testleistung Giovanni'); DELETE FROM tbl_leistung WHERE Beschreibung='Manager-Testleistung Giovanni'; SELECT 'insert+delete ok' AS ergebnis;" 2>&1
echo
echo "[B-03 POSITIV] UPDATE Password tbl_benutzer  -> erwartet OK"
$MAN -e "UPDATE tbl_benutzer SET Password=SHA2('NewPwd_Giovanni!2026',256) WHERE Benutzer_ID=1; SELECT ROW_COUNT() AS geaendert;" 2>&1
echo
echo "[B-04 NEGATIV] INSERT tbl_buchung  -> erwartet FEHLER 1142 (nur SELECT)"
$MAN -e "INSERT INTO tbl_buchung (Personen_FS,Ankunft,Abreise,Land_FS) VALUES (1,NOW(),NOW()+INTERVAL 1 DAY,1);" 2>&1
echo
echo "[B-05 NEGATIV] UPDATE tbl_positionen  -> erwartet FEHLER 1142"
$MAN -e "UPDATE tbl_positionen SET Preis=0 WHERE Positions_ID=1;" 2>&1
echo
echo "################ ENDE ROLLEN-TESTS ################"
} 2>&1 | tee "$OUT/tests_roles_full.txt"

echo "### Backup: mysqldump (Struktur + Daten) ###"
mysqldump --databases "$DB" --routines --events --single-transaction \
  --default-character-set=utf8mb4 > "$BASE/backpacker_lb3_giovanni_dump.sql" 2>>"$OUT/dump_err.txt"
gzip -kf "$BASE/backpacker_lb3_giovanni_dump.sql"
du -h "$BASE/backpacker_lb3_giovanni_dump.sql" "$BASE/backpacker_lb3_giovanni_dump.sql.gz" | tee "$OUT/dump_info.txt"

echo "### FERTIG. Outputs in $OUT ###"
find "$OUT" -maxdepth 1 -type f -printf '%s\t%p\n' | sort -k2
