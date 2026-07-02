#!/usr/bin/env bash
# ============================================================
# M141 LB3 – Automatisierte Migration in die EIGENE Cloud-DB
# Quelle:  lokale MariaDB (XAMPP / Testserver)
# Ziel:    cloud-db-giovanni  (192.168.1.62:3306, TLS erzwungen)
# Autor:   Giovanni Merola · 02.07.2026
#
# Überträgt Struktur + Daten (mysqldump) und danach die
# Zugriffsberechtigungen (04_selfhosted_cloud_users.sql) – alles
# ausschliesslich über TLS gegen die selbstsignierte CA der
# eigenen Cloud.
#
# Passwörter NIE im Repo: per Umgebungsvariable übergeben:
#   export LOCAL_PWD=""                       # lokale root-DB (leer wenn unix_socket)
#   export CLOUD_ADMIN_PWD="CloudAdmin!Giovanni-2026"
#   ./migrate_local_to_selfhosted.sh
# ============================================================
set -Eeuo pipefail

DB="backpacker_lb3_giovanni"
CLOUD_HOST="192.168.1.62"
CLOUD_PORT="3306"
CLOUD_USER="giovanni_admin"
CA="/etc/mysql/certs/ca.pem"          # von cloud-db-giovanni kopieren (öffentlich)
DCL="$(dirname "$0")/../dcl/04_selfhosted_cloud_users.sql"
DUMPDIR="$(dirname "$0")/dumps"
DUMP="$DUMPDIR/${DB}_$(date +%Y%m%d).sql"

die() { printf '\nFEHLER (Zeile %s): %s\n' "${1:-?}" "${2:-abgebrochen}" >&2; exit 1; }
trap 'die "$LINENO" "Migration abgebrochen"' ERR

# ---- Preflight -----------------------------------------------------------
: "${CLOUD_ADMIN_PWD:?Setze CLOUD_ADMIN_PWD (siehe Passwort-Manager)}"
command -v mysql    >/dev/null 2>&1 || die "$LINENO" "mysql-Client fehlt"
command -v mysqldump >/dev/null 2>&1 || die "$LINENO" "mysqldump fehlt"
[ -f "$CA" ]  || die "$LINENO" "CA-Zertifikat nicht gefunden: $CA (von cloud-db-giovanni kopieren)"
[ -f "$DCL" ] || die "$LINENO" "Cloud-DCL nicht gefunden: $DCL"
LOCAL_PWD_ARG=""; [ -n "${LOCAL_PWD:-}" ] && LOCAL_PWD_ARG="-p${LOCAL_PWD}"
mkdir -p "$DUMPDIR"

# gemeinsame Cloud-Verbindungsargumente (TLS erzwungen + CA-Verifikation)
CLOUD_ARGS=(-h "$CLOUD_HOST" -P "$CLOUD_PORT" -u "$CLOUD_USER" "-p${CLOUD_ADMIN_PWD}"
            --ssl-verify-server-cert --ssl-ca="$CA")

echo "==> 0) Preflight: TLS-Verbindung zur Cloud-DB testen"
mysql "${CLOUD_ARGS[@]}" -e "SELECT 1;" >/dev/null 2>&1 \
  || die "$LINENO" "keine TLS-Verbindung zu ${CLOUD_HOST}:${CLOUD_PORT} (Endpoint online? Firewall? CA korrekt?)"
echo "    TLS-Verbindung OK"

echo "==> 1) Cloud-DB anlegen (falls nicht vorhanden)"
mysql "${CLOUD_ARGS[@]}" \
  -e "CREATE DATABASE IF NOT EXISTS $DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "==> 2) Lokale DB dumpen -> $DUMP"
# shellcheck disable=SC2086  # LOCAL_PWD_ARG ist bewusst wortgetrennt (leer = kein -p)
mysqldump -u root $LOCAL_PWD_ARG \
  --single-transaction --routines --events \
  --default-character-set=utf8mb4 "$DB" > "$DUMP"
[ -s "$DUMP" ] || die "$LINENO" "Dump ist leer - lokale DB '$DB' vorhanden?"
echo "    Dump: $(du -h "$DUMP" | cut -f1)"

echo "==> 3) Dump per TLS in die Cloud-DB einspielen"
mysql "${CLOUD_ARGS[@]}" --default-character-set=utf8mb4 "$DB" < "$DUMP"

echo "==> 4) Zugriffsberechtigungen (DCL) automatisiert übertragen"
mysql "${CLOUD_ARGS[@]}" "$DB" < "$DCL"

echo "==> 5) Smoke-Test: Zeilenzahlen + TLS-Status"
mysql "${CLOUD_ARGS[@]}" "$DB" -t \
  -e "SELECT 'tbl_personen' t, COUNT(*) c FROM tbl_personen
      UNION ALL SELECT 'tbl_benutzer',   COUNT(*) FROM tbl_benutzer
      UNION ALL SELECT 'tbl_land',       COUNT(*) FROM tbl_land
      UNION ALL SELECT 'tbl_leistung',   COUNT(*) FROM tbl_leistung
      UNION ALL SELECT 'tbl_buchung',    COUNT(*) FROM tbl_buchung
      UNION ALL SELECT 'tbl_positionen', COUNT(*) FROM tbl_positionen;
      SHOW STATUS LIKE 'Ssl_cipher';"

echo "==> FERTIG — Fenster als cloud_migration_run.png sichern."
