# ============================================================
# EVALUIERTE AIVEN-VARIANTE - NICHT PRODUKTIV. Produktiv: migrate_local_to_selfhosted.sh (eigene Cloud).
# M141 LB3 – Backpacker_LB3 – Giovanni Merola
# migrate_local_to_cloud.ps1
# Windows-Variante des Migrations-Scripts (PowerShell).
# Migriert lokale MariaDB nach Aiven for MySQL.
# Verwendet die System-eigenen mysqldump.exe / mysql.exe.
#
# Aufruf (vorher Aiven-Service starten + Connection-Details holen):
#   $env:CLOUD_HOST = "backpacker-aiven-giovanni-giovanni-m141.aivencloud.com"
#   $env:CLOUD_PORT = "12345"            # Aiven liefert einen Custom Port
#   $env:CLOUD_USER = "avnadmin"          # Aiven Default-Master-User
#   $env:CLOUD_PWD  = "__YOUR_PWD__"      # aus Aiven Console kopieren
#   .\migrate_local_to_cloud.ps1
# Autor: Giovanni Merola · 30.06.2026
# ============================================================

$ErrorActionPreference = "Stop"

# Lokale MariaDB
$LOCAL_USER = $env:LOCAL_USER  ?? "root"
$LOCAL_PWD  = $env:LOCAL_PWD   ?? ""
$LOCAL_HOST = $env:LOCAL_HOST  ?? "127.0.0.1"
$DB         = "backpacker_lb3_giovanni"

# Aiven Cloud
if (-not $env:CLOUD_HOST) { throw "CLOUD_HOST not set (Aiven-Hostname kopieren)" }
if (-not $env:CLOUD_PORT) { throw "CLOUD_PORT not set (Aiven verwendet einen Custom Port)" }
if (-not $env:CLOUD_USER) { throw "CLOUD_USER not set (typisch 'avnadmin')" }
if (-not $env:CLOUD_PWD ) { throw "CLOUD_PWD not set"  }

# mysqldump/mysql Path: typisch MariaDB-Installation; ggf. anpassen
$MARIADB_BIN = $env:MARIADB_BIN ?? "C:\Program Files\MariaDB 11.7\bin"
if (-not (Test-Path "$MARIADB_BIN\mysqldump.exe")) {
    # Fallback: hoffe, mysqldump/mysql ist im PATH
    $MARIADB_BIN = ""
}

$DUMP_DIR  = ".\dumps"
$CA        = ".\aiven-ca.pem"         # aus Aiven Console heruntergeladen
if (-not (Test-Path $CA)) {
    throw "Aiven CA-Cert '$CA' fehlt. Aiven Console -> Service -> 'CA Certificate' herunterladen und als 'aiven-ca.pem' in sql\migration\ speichern."
}
$TS        = Get-Date -Format "yyyyMMdd_HHmmss"
$DUMP_FILE = Join-Path $DUMP_DIR "$($DB)_$TS.sql"

New-Item -ItemType Directory -Force -Path $DUMP_DIR | Out-Null

$mysqldump = if ($MARIADB_BIN) { "$MARIADB_BIN\mysqldump.exe" } else { "mysqldump" }
$mysql     = if ($MARIADB_BIN) { "$MARIADB_BIN\mysql.exe"    } else { "mysql"     }

Write-Host "==> 1) mysqldump lokal -> $DUMP_FILE"
& $mysqldump `
    -h $LOCAL_HOST -u $LOCAL_USER ($LOCAL_PWD ? "-p$LOCAL_PWD" : "") `
    --single-transaction --routines --triggers --events `
    --default-character-set=utf8mb4 `
    --no-create-db `
    --skip-add-drop-table --add-drop-table `
    $DB `
    | Out-File -Encoding utf8 $DUMP_FILE

Write-Host "==> 2) Schema sicherstellen (Aiven CREATE DATABASE)"
& $mysql -h $env:CLOUD_HOST -P $env:CLOUD_PORT -u $env:CLOUD_USER -p"$env:CLOUD_PWD" `
    --ssl-mode=REQUIRED --ssl-ca=$CA `
    -e "CREATE DATABASE IF NOT EXISTS $DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

Write-Host "==> 3) Restore in Cloud (Aiven, TLS erzwungen)"
Get-Content $DUMP_FILE | & $mysql `
    -h $env:CLOUD_HOST -P $env:CLOUD_PORT -u $env:CLOUD_USER -p"$env:CLOUD_PWD" `
    --ssl-mode=REQUIRED --ssl-ca=$CA `
    --default-character-set=utf8mb4 `
    $DB

Write-Host "==> 4) Cloud-DCL anwenden (Rollen + User)"
Get-Content ..\dcl\03_cloud_users.sql | & $mysql `
    -h $env:CLOUD_HOST -P $env:CLOUD_PORT -u $env:CLOUD_USER -p"$env:CLOUD_PWD" `
    --ssl-mode=REQUIRED --ssl-ca=$CA `
    $DB

Write-Host "==> 5) Smoke-Test (Zeilenzahlen)"
& $mysql -h $env:CLOUD_HOST -P $env:CLOUD_PORT -u $env:CLOUD_USER -p"$env:CLOUD_PWD" `
    --ssl-mode=REQUIRED --ssl-ca=$CA $DB `
    -e "SELECT 'tbl_personen' t, COUNT(*) c FROM tbl_personen UNION ALL
        SELECT 'tbl_benutzer'    , COUNT(*)   FROM tbl_benutzer   UNION ALL
        SELECT 'tbl_land'        , COUNT(*)   FROM tbl_land       UNION ALL
        SELECT 'tbl_leistung'    , COUNT(*)   FROM tbl_leistung   UNION ALL
        SELECT 'tbl_buchung'     , COUNT(*)   FROM tbl_buchung    UNION ALL
        SELECT 'tbl_positionen'  , COUNT(*)   FROM tbl_positionen;"

Write-Host "==> Fertig $(Get-Date)"
