#!/usr/bin/env bash
# EVALUIERTE AIVEN-VARIANTE - NICHT PRODUKTIV. Produktiv: migrate_local_to_selfhosted.sh (eigene Cloud).
# ============================================================
# M141 LB3 – Backpacker_LB3 – Giovanni Merola
# migrate_local_to_cloud.sh
# Migrationsskript: Lokales MariaDB (XAMPP) -> Aiven for MySQL
#
# Voraussetzungen:
#   - mysqldump / mysql Client installiert (z. B. XAMPP /usr/bin)
#   - Aiven Endpoint, Master-User und Master-Passwort als ENV-Variablen
#   - SSL CA Bundle (aiven-ca.pem) im Arbeitsverzeichnis
#
# Usage:
#   export CLOUD_HOST=backpacker-aiven-giovanni-giovannimerola1.h.aivencloud.com
#   export CLOUD_PORT=13544
#   export CLOUD_USER=avnadmin
#   export CLOUD_PWD='__PWD__'        # NEVER commit a real password
#   export LOCAL_USER=root
#   export LOCAL_PWD=''
#   bash migrate_local_to_cloud.sh
# Autor: Giovanni Merola · 30.06.2026
# ============================================================

set -euo pipefail

LOCAL_USER="${LOCAL_USER:-root}"
LOCAL_PWD="${LOCAL_PWD:-}"
LOCAL_HOST="${LOCAL_HOST:-127.0.0.1}"
DB="backpacker_lb3_giovanni"

CLOUD_HOST="${CLOUD_HOST:?CLOUD_HOST not set}"
CLOUD_USER="${CLOUD_USER:?CLOUD_USER not set}"
CLOUD_PWD="${CLOUD_PWD:?CLOUD_PWD not set}"

CA_BUNDLE="${CA_BUNDLE:-./aiven-ca.pem}"
DUMP_DIR="${DUMP_DIR:-./dumps}"
TS=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="$DUMP_DIR/${DB}_${TS}.sql"

mkdir -p "$DUMP_DIR"

echo "==> 1) mysqldump lokal -> $DUMP_FILE"
mysqldump \
    -h "$LOCAL_HOST" \
    -u "$LOCAL_USER" \
    ${LOCAL_PWD:+-p"$LOCAL_PWD"} \
    --single-transaction \
    --routines --triggers --events \
    --set-gtid-purged=OFF \
    --default-character-set=utf8mb4 \
    --add-drop-database \
    --databases "$DB" > "$DUMP_FILE"

echo "    Dump-Grösse: $(du -h "$DUMP_FILE" | cut -f1)"

echo "==> 2) Restore in Cloud (TLS erzwungen)"
mysql \
    -h "$CLOUD_HOST" \
    -u "$CLOUD_USER" \
    -p"$CLOUD_PWD" \
    --ssl-mode=REQUIRED \
    --ssl-ca="$CA_BUNDLE" \
    --default-character-set=utf8mb4 < "$DUMP_FILE"

echo "==> 3) Cloud-DCL anwenden (Rollen + User)"
mysql \
    -h "$CLOUD_HOST" \
    -u "$CLOUD_USER" \
    -p"$CLOUD_PWD" \
    --ssl-mode=REQUIRED \
    --ssl-ca="$CA_BUNDLE" \
    "$DB" < ../dcl/03_cloud_users.sql

echo "==> 4) Quick Smoke-Test (Zeilenzahlen)"
mysql \
    -h "$CLOUD_HOST" \
    -u "$CLOUD_USER" \
    -p"$CLOUD_PWD" \
    --ssl-mode=REQUIRED \
    --ssl-ca="$CA_BUNDLE" \
    "$DB" -e "
        SELECT 'tbl_personen'   AS t, COUNT(*) FROM tbl_personen   UNION
        SELECT 'tbl_benutzer'   ,     COUNT(*) FROM tbl_benutzer   UNION
        SELECT 'tbl_land'       ,     COUNT(*) FROM tbl_land       UNION
        SELECT 'tbl_leistung'   ,     COUNT(*) FROM tbl_leistung   UNION
        SELECT 'tbl_buchung'    ,     COUNT(*) FROM tbl_buchung    UNION
        SELECT 'tbl_positionen' ,     COUNT(*) FROM tbl_positionen;"

echo "==> Fertig in $(date)"
