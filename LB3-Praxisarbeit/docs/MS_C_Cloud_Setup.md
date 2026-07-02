# MS C – Cloud-DBMS (Aiven for MySQL) Setup & Betrieb

*Autor: Giovanni Merola · M141 · LB3 · 30.06.2026*

> **Hinweis Cloud-Provider-Pivot**:
> Ursprünglich war AWS RDS MariaDB geplant (siehe `MS_A_Cloud_Evaluation.md`). Da die Klasse keinen TBZ-Schulungs-AWS-Account erhalten hat und ein privater Account die nötigen VPC-/IAM-Berechtigungen nicht ohne Aufwand freischaltet, wurde nach erneuter Evaluation auf **Aiven for MySQL** gewechselt. Aiven qualifiziert gemäss LB3-Rahmen ("Andere oder eigene Cloud-DB gibt +") für den Plus-Bonus in MS C 2.1.

---

## 2.1 Setup Cloud DBMS (Aiven)

### A. Pre-Conditions

| # | Prüfung | Erwartet |
|---|---|---|
| 1 | Browser-Zugang | ✅ |
| 2 | Geschäfts- oder Privat-E-Mail für Aiven-Signup | ✅ |
| 3 | Lokale öffentliche IP bekannt (`https://whatismyipaddress.com`) | ✅ |
| 4 | Keine Kreditkarte nötig (Free Trial gewährt USD 300 Credit für 30 Tage) | ✅ |

### B. Schritte (Aiven Console)

1. Browser → https://console.aiven.io/signup
2. Mit E-Mail registrieren, Account-Name: `giovanni-m141`.
3. Nach E-Mail-Verifizierung → **"Create a new service"** Button.
4. Form ausfüllen:
   - **Service**: `MySQL`
   - **Service plan**: **Hobbyist** (im Trial kostenfrei, ansonsten ~17 €/Monat) oder **Startup-1** (höhere Limits, ~75 USD/Monat).
   - **Cloud Provider**: DigitalOcean (Aiven managt es)
   - **Region**: `do-ams` (Amsterdam, NL — DSGVO-konform)
   - **Service name**: `backpacker-aiven-giovanni`
5. **Create service** → Status wechselt von "Building" auf "Running" (~3–5 Min).

### C. Service-Konfiguration (Service-Detailseite)

1. Tab **"Overview"**: kopieren in Notizblock:
   - **Service URI** (komplett, enthält user/pwd)
   - **Host** (im realisierten Service: `backpacker-aiven-giovanni-giovannimerola1.h.aivencloud.com`)
   - **Port** (im realisierten Service: `13544`)
   - **Default DB** = `defaultdb`
   - **User** = `avnadmin`
   - **Password** (per Klick auf "Show")
   - **CA Certificate** (Button → herunterladen, Datei heisst `ca.pem`)

2. Tab **"Overview" → "Allowed IP addresses"**:
   - Standard ist `0.0.0.0/0` (offen für alle IPs)
   - **Aus Sicherheitsgründen ändern**: Klick **"Add address"** → eigene öffentliche IP/32 eingeben (z. B. `85.1.2.3/32`).
   - Speichern. Das ersetzt den `0.0.0.0/0`-Eintrag (oder Sie entfernen ihn manuell).

3. Tab **"Connection information" → "Connection details"**:
   - SSL Mode: **`require`** (von Aiven erzwungen, nicht änderbar).

### D. CA-Cert lokal speichern

Speichern Sie die heruntergeladene `ca.pem` als:
```
C:\Users\Giovanni\Documents\GitHub\M141\LB3-Praxisarbeit\sql\migration\aiven-ca.pem
```

### E. Test-Verbindung (MariaDB-Client aus CMD)

```
mysql -h <HOST> -P <PORT> -u avnadmin -p<PASSWORD> --ssl-mode=REQUIRED --ssl-ca=sql\migration\aiven-ca.pem defaultdb -e "SELECT VERSION(), @@hostname, @@have_ssl;"
```

Erwartete Ausgabe:
```
+-----------+--------------------+-----------+
| VERSION() | @@hostname         | @@have_ssl|
+-----------+--------------------+-----------+
| 8.4.8     | mysql-xxxxxxxx-xxx | YES       |
+-----------+--------------------+-----------+
```

→ Screenshot dieser Ausgabe als `cloud_verbindung_giovanni.png`.

### F. Application Database anlegen

`avnadmin` darf neue DBs erstellen. Per Aiven Console:
- Tab **"Databases"** → **"+ Create database"** → Name: `backpacker_lb3_giovanni` → speichern.

Alternativ via CLI:
```
mysql -h <HOST> -P <PORT> -u avnadmin -p<PASSWORD> --ssl-mode=REQUIRED --ssl-ca=sql\migration\aiven-ca.pem -e "CREATE DATABASE backpacker_lb3_giovanni CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### G. Was bewertet wird

| Kriterium | Erfüllung |
|---|---|
| **A1 / 2.1 – Installation und Setup** | ✅ Aiven Service `backpacker-aiven-giovanni` läuft, Region Amsterdam (do-ams), MySQL 8.4.8, personalisiert. |
| **Plus-Bonus (andere Cloud)** | ✅ Aiven statt AWS → qualifiziert für das *"+ "* in der LB3-Bewertung. |

---

## 2.2 Betrieb (Produktive Konfiguration & Härtung)

### A. Sicherheits-Checkliste

| # | Kontrolle | Status |
|---|---|---|
| S-01 | Nur erlaubte IPs (eigene IP/32 in Aiven Allowlist) | ✅ |
| S-02 | TLS-Pflicht (Aiven default, nicht abschaltbar) | ✅ |
| S-03 | Encryption at Rest (AES-256 von Aiven gemanaged) | ✅ |
| S-04 | Backup Retention (Hobbyist: 2 Tage PITR; Startup: 7 Tage) | ✅ |
| S-05 | Termination Protection (Aiven Console → Service → Termination Protection ON) | ✅ |
| S-06 | 2FA auf Aiven-Account | ✅ |
| S-07 | Master-Passwort nicht im Repo (in `__PWD__` Platzhalter) | ✅ |
| S-08 | DB-User mit `REQUIRE SSL` (zusätzlich zur Service-TLS-Pflicht) | ✅ |
| S-09 | Keine Wildcard-`%`-User mit Vollzugriff (App-User pro Rolle) | ✅ |
| S-10 | Slow Query Log aktiv (via Aiven Console → Advanced Configuration) | ✅ |

### B. Service-Konfiguration (Aiven-Äquivalent zur AWS Parameter Group)

Aiven exponiert MySQL-Parameter via **Service → "Advanced configuration"**. Folgende Werte werden gesetzt (entspricht logisch `config/my_aiven.cnf`):

| Parameter | Wert | Zweck |
|---|---|---|
| `character_set_server` | `utf8mb4` (Aiven-default) | Unicode |
| `collation_server` | `utf8mb4_unicode_ci` (auf DB-Ebene) | Konsistent |
| `default_storage_engine` | `InnoDB` | Engine |
| `sql_mode` | `STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO` | Strenge Prüfung |
| `time_zone` | `UTC` | Konsistent |
| `local_infile` | `OFF` (Default, nur über Admin-Override für Migration kurz `ON`) | Sicherheit |
| `slow_query_log` | `ON` | Performance-Monitoring |
| `long_query_time` | `1` | Threshold 1 s |
| `general_log` | `OFF` | nur ad-hoc |
| `wait_timeout` | `600` | Session-Cleanup |
| `max_connections` | Plan-abhängig (~60) | Kontrolle |

Anwenden: Aiven Console → Service `backpacker-aiven-giovanni` → **"Advanced configuration"** → "Add configuration option" pro Parameter. Aiven wendet die Änderung **online** an (kein Reboot nötig, ggf. Connection-Drop).

### C. Cloud-User mit TLS

Siehe `sql/dcl/03_cloud_users.sql` – legt `giovanni_benutzer`, `giovanni_manager`, `giovanni_dba` an mit `REQUIRE SSL` und `%`-Host. Wird gegen die Aiven-Cloud-Instanz ausgeführt.

### D. Operativer Betrieb

| Tätigkeit | Mechanismus |
|---|---|
| Tägliche Backups | Aiven automatisiert (Hobbyist: 2 Tage PITR; Startup: 7 Tage) |
| Manueller Snapshot vor Migration | Aiven Console → "Backups" → "Create backup" (oder Service → Fork) |
| Monitoring | Aiven Console → Metrics-Tab (CPU, Mem, Conn, Disk) |
| Patching | Von Aiven gemanaged, mit Wartungsfenster Konfigurierbar |
| Restore-Drill | Aiven Console → "Backups" → Backup auswählen → "Fork from backup" → Test-Service erstellen → verifizieren → löschen |
| Logs | Aiven Console → "Logs" Tab; oder Integration mit Datadog/Loki |

### E. Was bewertet wird

| Kriterium | Erfüllung |
|---|---|
| **A2 – Cloud DBMS für produktiven Betrieb gesichert** | ✅ 10-Punkte-Härtungs-Checkliste (S-01..S-10) |
| **C1 – Konfigurationen (.ini) für prod. Betrieb** | ✅ `config/my_aiven.cnf` dokumentiert alle Service-Parameter |

---

*Sign-off Cloud-Setup: Giovanni Merola, 30.06.2026*
