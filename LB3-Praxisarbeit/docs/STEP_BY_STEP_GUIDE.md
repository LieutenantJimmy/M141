# Step-by-Step Guide (No Git Version)
n> **⚠ HISTORISCHES ARBEITSDOKUMENT (Aiven-Route).** Die PARTs 7–10 beschreiben die **evaluierte Aiven-Alternative** — Aiven wurde bewusst zugunsten der **eigenen Homelab-Cloud** verworfen (volle Kontrolle, kein Vendor-Lock, Max-Bonus). Produktiv/live: `docs/MS_C_Cloud_SelfHosted.md` + `VERIFICATION.md`. Upload-Ziel ist GitHub (nicht GitLab).

*For: Giovanni Merola · M141 LB3 · Backpacker DB Migration*

Final output: a complete folder you drag-and-drop into GitLab Web IDE. No git commands.

**Cloud provider: Aiven for MySQL** (replaces AWS RDS — AWS access wasn't available, Aiven gives the LB3 "+ Bonus" per the rubric "Andere oder eigene Cloud-DB gibt +").

---

## PART 1–6 (Already completed ✅)

You've already done:
- Installed local MariaDB / set up local DB `backpacker_lb3_giovanni` with all data (personen=2036, benutzer=11, land=82, leistung=8, buchung=1006, positionen=1746 — inkl. Migrations-Testdatensatz)
- Roles + users created and tested
- All 6 local screenshots taken

If you ever need to redo, see the previous chat for the exact commands.

---

## PART 7 — Set up Aiven for MySQL (10 min)

### 7.1 Create Aiven account

1. Browser → https://console.aiven.io/signup
2. Sign up with email — **no credit card required for the 30-day trial / USD 300 credit**.
3. Verify the e-mail link Aiven sends you.
4. Sign in. You should see "Welcome to Aiven" / dashboard.

### 7.2 Create the MySQL service

1. Big button: **"+ Create service"** (or **"Services" → "Create service"**).
2. Fill the form:
   - **Service**: select **MySQL** (icon).
   - **Service plan**: **Hobbyist** (free in trial, 17 €/mo after).
   - **Cloud Provider**: **DigitalOcean** (Aiven manages this — you don't need a DigitalOcean account).
   - **Region**: **do-ams** (Amsterdam, NL — DSGVO-konform).
   - **Service name**: `backpacker-aiven-giovanni`.
3. Click **Create service** at the bottom.
4. Wait ~3–5 min until status changes from "Building" to **"Running"** (green dot).

### 7.3 Grab connection details

Once the service is running, click on it. On the **Overview** tab you'll see a card "Connection information":

- **Host**: something like `backpacker-aiven-giovanni-giovanni-m141-lb3.aivencloud.com`
- **Port**: a 5-digit number (e.g. `12345`) — Aiven uses a custom port, NOT 3306.
- **User**: `avnadmin`
- **Password**: click "Show" — copy it into Notepad.
- **Default DB**: `defaultdb`

**Important — download the CA certificate**:
- Same card, scroll down → button **"Show CA certificate"** → click **"Download"** → file is `ca.pem`.
- Move that file to:
  `C:\Users\Giovanni\Documents\GitHub\M141\LB3-Praxisarbeit\sql\migration\aiven-ca.pem`
  (rename to `aiven-ca.pem`).

### 7.4 Lock down the IP-allowlist (sécurité)

1. Same service page → scroll down to **"Allowed IP addresses"** card.
2. Default is `0.0.0.0/0` (everyone). **Remove it** by clicking the trash icon.
3. Get your public IP: https://whatismyipaddress.com
4. In Aiven → **+ Add address** → type `<your-IP>/32` (e.g. `85.1.2.3/32`) → save.
5. Result: only your machine can reach the service.

### 7.5 Set Advanced Configuration (TLS + sql_mode)

1. Same service page → top tab **"Advanced configuration"**.
2. Add the following options (button **"+ Add configuration option"** for each):

| Option | Value |
|---|---|
| `mysql.sql_mode` | `STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO` |
| `mysql.slow_query_log` | `true` |
| `mysql.long_query_time` | `1` |
| `mysql.wait_timeout` | `600` |

3. **Save** at the bottom.

(TLS is already enforced by Aiven at the service level — no extra option needed.)

### 7.6 Create the application database

1. Same service page → tab **"Databases"**.
2. **+ Create database** → name: `backpacker_lb3_giovanni` → save.

That's the schema container our migration will populate.

---

## PART 8 — Take the 4 cloud screenshots (5 min)

Use **Win+Shift+S** for each. Save in `screenshots\` with these exact names:

**8.1 Aiven service dashboard:**
- Console → click `backpacker-aiven-giovanni` → Overview tab.
- Make sure status shows **Running** and the service name `backpacker-aiven-giovanni` is visible.
- Screenshot → `cloud_rds_dashboard.png` *(keep the filename — the README still lists it under that name; the content shows Aiven instead of RDS)*

**8.2 Connection info / configuration:**
- Same Overview tab, "Connection information" card visible.
- Make sure host/user/port are visible but **black out the password** (use Snip & Sketch eraser, or just don't show "Show" clicked).
- Screenshot → `cloud_rds_konfiguration.png`

**8.3 IP allowlist:**
- Same page, scroll to "Allowed IP addresses" — should show your IP/32 only.
- Screenshot → `cloud_rds_security_group.png`

**8.4 Advanced configuration:**
- Tab "Advanced configuration" — your 4 added options visible.
- Screenshot → `cloud_rds_parameter_group.png`

---

## PART 9 — Run the migration (10 min)

### 9.1 Open PowerShell

File Explorer → navigate to `C:\Users\Giovanni\Documents\GitHub\M141\LB3-Praxisarbeit\sql\migration\` → click the address bar → type `powershell` → Enter.

### 9.2 Set env vars and run migration

Replace `<HOST>`, `<PORT>`, `<PWD>` with your Aiven values from 7.3:

```powershell
$env:CLOUD_HOST = "<HOST>"
$env:CLOUD_PORT = "<PORT>"
$env:CLOUD_USER = "avnadmin"
$env:CLOUD_PWD  = "<PWD>"

.\migrate_local_to_cloud.ps1
```

Expected output: "dump done", "schema created", "restore done", "DCL applied", final smoke-test showing row counts. Screenshot the PowerShell window → `cloud_migration_run.png`.

If the MariaDB client is not on PATH, set:
```powershell
$env:MARIADB_BIN = "C:\Program Files\MariaDB 11.7\bin"   # adjust to your actual path
```

### 9.3 TLS connection test (positive)

```powershell
& "$env:MARIADB_BIN\mysql.exe" -h $env:CLOUD_HOST -P $env:CLOUD_PORT -u avnadmin -p"$env:CLOUD_PWD" --ssl-mode=REQUIRED --ssl-ca=aiven-ca.pem backpacker_lb3_giovanni -e "SELECT VERSION(), @@hostname, @@have_ssl;"
```

Expected: MySQL 8.x, hostname starts with `mysql-...`, `@@have_ssl = YES`.
Screenshot → `cloud_verbindung_giovanni.png`.

### 9.4 TLS-required negative test

```powershell
& "$env:MARIADB_BIN\mysql.exe" -h $env:CLOUD_HOST -P $env:CLOUD_PORT -u avnadmin -p"$env:CLOUD_PWD" --ssl-mode=DISABLED backpacker_lb3_giovanni -e "SELECT 1;"
```

Expected error: "Connections using insecure transport are prohibited". Screenshot → `cloud_tls_required.png`.

### 9.5 Cloud test suite

```powershell
Get-Content ..\dql\70_tests_cloud.sql | & "$env:MARIADB_BIN\mysql.exe" -h $env:CLOUD_HOST -P $env:CLOUD_PORT -u avnadmin -p"$env:CLOUD_PWD" --ssl-mode=REQUIRED --ssl-ca=aiven-ca.pem backpacker_lb3_giovanni
```

Screenshot output → `cloud_tests_data.png`.

### 9.6 3-user demo screenshot

Open 3 PowerShell windows side by side. In each, login as a different role:

Window 1 (Empfang):
```powershell
& "$env:MARIADB_BIN\mysql.exe" -h <HOST> -P <PORT> -u giovanni_benutzer -p"Cloud!Benutzer-Giovanni-2026" --ssl-mode=REQUIRED --ssl-ca="<full path>\aiven-ca.pem" backpacker_lb3_giovanni
```

Window 2: `-u giovanni_manager -p"Cloud!Manager-Giovanni-2026"`
Window 3: `-u giovanni_dba -p"Cloud!Dba-Giovanni-2026"`

In each window run: `SELECT CURRENT_USER(), CURRENT_ROLE();`

Arrange the 3 windows so all 3 user names are visible → screenshot the whole desktop → `cloud_demo_3_users.png`.

---

## PART 10 — Upload to GitLab via Web IDE (5 min)

1. https://gitlab.com → sign in (or sign up).
2. Top-right **+** → **New project/repository** → **Create blank project**.
3. Project name: `lb3-backpacker-giovanni`. Visibility: **Private**. Uncheck "Initialize with README". Click **Create project**.
4. Press `.` on the keyboard (with your repo page in focus) → opens the GitLab Web IDE.
5. In the Web IDE left panel → right-click the empty file tree → **Upload files**.
6. Open File Explorer separately → navigate into `C:\Users\Giovanni\Documents\GitHub\M141\LB3-Praxisarbeit\` → select ALL files + folders (Ctrl+A) → drag-drop into Web IDE.
7. Wait for upload to finish.
8. Click **Source Control** icon (branching-tree, left edge).
9. Commit message: `M141 LB3 Praxisarbeit – Giovanni Merola`.
10. Click **Commit & Push** → confirm to `main`.

### Update the repo URL in docs (optional, cleaner)

1. Copy repo URL from the address bar in GitLab.
2. Open `README_Praxisarbeit.md` and `docs\MS_A_Anforderungsdefinition.md` → replace `https://gitlab.com/giovanni-m141/lb3-backpacker-giovanni` with your real URL.
3. Re-upload these two files via Web IDE → commit → push.

---

## PART 11 — Final checks before the demo (5 min)

- [ ] Bewertungsmatrix Excel: B4 = `Giovanni Merola`, D4 = 0 (Einzelarbeit-Bonus bewusst verzichtet), D28 = 41.5, D30 = 5.77.
- [ ] All 10 screenshots in `screenshots\` (6 local + 4 cloud + migration + verbindung + tls + tests + demo = ~10 total).
- [ ] GitLab repo shows all folders.
- [ ] Aiven service is **Running** (keep it up until demo day).
- [ ] Practice once with `docs\Demo_Skript.md` (14 min demo).

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `mysql` not found | Set `$env:MARIADB_BIN = "C:\Program Files\MariaDB 11.7\bin"` (adjust your path) |
| ERROR 1148 LOCAL INFILE | This is only for local CSV import. Cloud doesn't need LOCAL INFILE for the dump-based migration. |
| ERROR 1045 Access denied (Aiven) | Re-copy the Aiven password from the console — extra spaces are common when copy-pasting. |
| Aiven "Can't connect" | Your IP changed (mobile/work network). Update the IP-allowlist with your current `whatismyipaddress.com` value. |
| SSL connection error | Make sure `aiven-ca.pem` is in `sql\migration\` and the `--ssl-ca` path is correct (use full path if in doubt). |
| `CREATE ROLE` syntax error on Aiven | MySQL 8 supports roles natively, syntax should work. If you get an error, re-check `sql\dcl\03_cloud_users.sql` for the MySQL-8 specific `SET DEFAULT ROLE … TO …` (not `FOR …`) syntax. |

When something errors, paste it here.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        