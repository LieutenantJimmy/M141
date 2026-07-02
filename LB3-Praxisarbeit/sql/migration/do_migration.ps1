# ============================================================
# do_migration.ps1 — Wrapper that runs the full Aiven migration
# in one shot. Run once from PowerShell.
# Autor: Giovanni Merola · M141 LB3
# ============================================================

$ErrorActionPreference = "Stop"

# ---- CONFIG: pass passwords via env vars — never commit them to the repo ----
#   $env:CLOUD_PWD = "AVNS_..."   (copy from Aiven Console > Service > "Show password")
#   $env:LOCAL_PWD = ""           (local MariaDB root password; empty if not set)
# -----------------------------------------------------------------------------
$CLOUD_PWD = $env:CLOUD_PWD
$LOCAL_PWD = $env:LOCAL_PWD

# ---- Fixed values from your setup ----
$CLOUD_HOST = "backpacker-aiven-giovanni-giovannimerola1.h.aivencloud.com"
$CLOUD_PORT = "13544"
$CLOUD_USER = "avnadmin"
$DB         = "backpacker_lb3_giovanni"

# Paths
$MYSQL    = "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe"
$MARIADB  = "C:\Program Files\MariaDB 11.7\bin"   # adjust if your MariaDB is elsewhere
$DUMPDIR  = "C:\Users\Giovanni\Documents\GitHub\M141\LB3-Praxisarbeit\sql\migration\dumps"
$DUMPFILE = Join-Path $DUMPDIR "backpacker_lb3_giovanni.sql"
$CA       = "C:\Users\Giovanni\Documents\GitHub\M141\LB3-Praxisarbeit\sql\migration\aiven-ca.pem"
$DCL      = "C:\Users\Giovanni\Documents\GitHub\M141\LB3-Praxisarbeit\sql\dcl\03_cloud_users.sql"

# Resolve mysqldump / mysql (local MariaDB)
$mysqldump = if (Test-Path "$MARIADB\mysqldump.exe") { "$MARIADB\mysqldump.exe" } else { "mysqldump" }
$mariadb_mysql = if (Test-Path "$MARIADB\mysql.exe") { "$MARIADB\mysql.exe" } else { "mysql" }

# Sanity
if (-not $CLOUD_PWD) {
    throw "Environment variable CLOUD_PWD is not set. Run e.g. `$env:CLOUD_PWD = 'AVNS_...' before .\do_migration.ps1"
}
if (-not (Test-Path $MYSQL)) { throw "MySQL client not found at $MYSQL" }
if (-not (Test-Path $CA))    { throw "Aiven CA cert not found at $CA. Download from Aiven Console and save it there." }

New-Item -ItemType Directory -Force -Path $DUMPDIR | Out-Null

Write-Host "==> Step 1) Ensure cloud DB exists" -ForegroundColor Cyan
& $MYSQL -h $CLOUD_HOST -P $CLOUD_PORT -u $CLOUD_USER "-p$CLOUD_PWD" `
    --ssl-mode=REQUIRED --ssl-ca=$CA `
    -e "CREATE DATABASE IF NOT EXISTS $DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
if ($LASTEXITCODE -ne 0) { throw "Cloud DB create failed" }

Write-Host "==> Step 2) Dump local DB to $DUMPFILE" -ForegroundColor Cyan
$pwdArg = if ($LOCAL_PWD) { "-p$LOCAL_PWD" } else { "" }
& $mysqldump -u root $pwdArg `
    --single-transaction --routines --triggers --events `
    --default-character-set=utf8mb4 `
    --skip-add-drop-table --add-drop-table `
    --column-statistics=0 `
    $DB > $DUMPFILE
if ($LASTEXITCODE -ne 0) { throw "Local dump failed" }
Write-Host "    Dump size: $((Get-Item $DUMPFILE).Length / 1KB) KB"

Write-Host "==> Step 3) Restore dump into Aiven" -ForegroundColor Cyan
Get-Content $DUMPFILE -Raw | & $MYSQL -h $CLOUD_HOST -P $CLOUD_PORT -u $CLOUD_USER "-p$CLOUD_PWD" `
    --ssl-mode=REQUIRED --ssl-ca=$CA `
    --default-character-set=utf8mb4 `
    $DB
if ($LASTEXITCODE -ne 0) { throw "Restore failed" }

Write-Host "==> Step 4) Apply cloud DCL (roles + users)" -ForegroundColor Cyan
Get-Content $DCL -Raw | & $MYSQL -h $CLOUD_HOST -P $CLOUD_PORT -u $CLOUD_USER "-p$CLOUD_PWD" `
    --ssl-mode=REQUIRED --ssl-ca=$CA `
    $DB
if ($LASTEXITCODE -ne 0) { Write-Host "    (Some DCL warnings are expected, e.g. DROP ROLE IF NOT EXISTS notices)" -ForegroundColor Yellow }

Write-Host "==> Step 5) Smoke test: row counts on Aiven" -ForegroundColor Cyan
& $MYSQL -h $CLOUD_HOST -P $CLOUD_PORT -u $CLOUD_USER "-p$CLOUD_PWD" `
    --ssl-mode=REQUIRED --ssl-ca=$CA $DB `
    -e "SELECT 'tbl_personen' t, COUNT(*) c FROM tbl_personen UNION ALL
        SELECT 'tbl_benutzer'   , COUNT(*)   FROM tbl_benutzer   UNION ALL
        SELECT 'tbl_land'       , COUNT(*)   FROM tbl_land       UNION ALL
        SELECT 'tbl_leistung'   , COUNT(*)   FROM tbl_leistung   UNION ALL
        SELECT 'tbl_buchung'    , COUNT(*)   FROM tbl_buchung    UNION ALL
        SELECT 'tbl_positionen' , COUNT(*)   FROM tbl_positionen;"

Write-Host ""
Write-Host "==> DONE — screenshot this entire PowerShell window as cloud_migration_run.png" -ForegroundColor Green
