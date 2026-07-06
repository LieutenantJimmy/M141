# M141 LB3 – Praxisarbeit Backpacker_LB3

**Autor:** Giovanni Merola &nbsp;·&nbsp; **Klasse:** M141 &nbsp;·&nbsp; **Schule:** TBZ &nbsp;·&nbsp; **Abgabe:** 30.06.2026

> **Ziel.** Die Backpacker-Hostel-Datenbank von Access auf MariaDB migrieren — zuerst lokal (XAMPP/MariaDB), dann in die Cloud (**Aiven for MySQL**, Region `do-ams`). Inklusive Normalisierung auf 2.NF, Datenbereinigung, Rollenkonzept mit Spaltenrechten, Tests, automatisierte Migration mit TLS und vollständige Dokumentation.

---

## 1. Schnellstart für die Lehrperson

Für den Einstieg empfehle ich diese Reihenfolge:

1. **`README_Praxisarbeit.md`** *(diese Datei)* — Index und Bewertungs-Mapping
2. **`docs/MS_A_Anforderungsdefinition.md`** — SMART-Anforderungen
3. **`docs/MS_A_Cloud_Evaluation.md`** — Provider-Vergleich + Pivot AWS → Aiven
4. **`docs/MS_B_1_1_ERD_2NF.md`** — Schema-Normalisierung
5. **`docs/MS_B_1_2_Zugriffsmatrix.md`** — Rollen & Rechte
6. **`docs/MS_C_Cloud_Setup.md`** — Aiven-Service-Setup & Härtung
7. **`docs/MS_D_Migration.md`** — Migration & Cloud-Tests
8. **`docs/Demo_Skript.md`** — Reihenfolge der 14-Minuten-Demo
9. **`docs/Fazit.md`** — Lessons learned
10. **`M141 LB3 Bewertung LE.xlsx`** — Selbsteinschätzung

> **Wichtiger Hinweis Cloud-Provider:** Ursprünglich war **AWS RDS for MariaDB** geplant. Da kein TBZ-Schulungs-AWS-Account zur Verfügung stand, wurde nach erneuter Evaluation auf **Aiven for MySQL** gewechselt. Aiven qualifiziert gemäss LB3-Rahmen ("Andere oder eigene Cloud-DB gibt +") für den Plus-Bonus. Details in `docs/MS_A_Cloud_Evaluation.md`.
>
> **Update 06.07.2026 – eigene Cloud LIVE (max. Bonus):** Die produktive DB läuft als **selbstgehostete eigene Cloud** auf dem Proxmox-Homelab (LXC `cloud-db-giovanni`, Endpoint **`192.168.1.62:3306`**, MariaDB 11.8.6, **TLS erzwungen/TLSv1.3**, IP-Allowlist). Struktur+Daten sind per TLS migriert (2036/11/82/8/1006/1746 — identisch lokal↔cloud), die 3 Rollen-User haben `REQUIRE SSL`, Klartext wird mit `ERROR 3159` abgewiesen. Nachweise: `screenshots/cloud_*.png` (+ `.txt`). Tooling (`shellcheck`-geprüft): `docs/MS_C_Cloud_SelfHosted.md`, `config/my_cloud_selfhosted.cnf`, `sql/repro/setup_cloud_selfhosted.sh`, `sql/repro/recover_and_deploy_freya.sh`, `sql/dcl/04_selfhosted_cloud_users.sql`, `sql/migration/migrate_local_to_selfhosted.sh`. *(Ursprünglicher Ziel-Host freya fiel am 02.07. aus → host-agnostisch auf `phoebe` deployt; freya-Recovery-Pfad dokumentiert.)*

---

## 2. Bewertungsmatrix-Abdeckung

Jede Zeile der LB3-Bewertungsmatrix ist mit konkreten Artefakten im Repo belegt:

| MS / Kriterium | Abdeckung | Konkreter Nachweis |
|---|---|---|
| **MS A · Anforderungen** | SMART, FA + NFA, Risiken, Abnahme | `docs/MS_A_Anforderungsdefinition.md` |
| **MS A · Cloud-Evaluation** | Gewichtete Matrix 5 Kandidaten, Begründung | `docs/MS_A_Cloud_Evaluation.md` |
| **MS B 1.1 · ERD/Schema 2.NF** | InnoDB, utf8mb4, FK, Indizes, CHECK | `sql/ddl/02_create_tables.sql` · `docs/MS_B_1_1_ERD_2NF.md` |
| **MS B 1.2 · Zugriffsmatrix** | 2 Rollen × 6 Tabellen, Spaltenrechte | `docs/MS_B_1_2_Zugriffsmatrix.md` · `sql/dcl/01_roles_users.sql` |
| **MS B 1.3 · DCL lokal** | 2 Rollen + 3 User, `Password`-Spalte gesperrt | `sql/dcl/01_roles_users.sql` |
| **MS B 1.4 · Datenimport & Cleanup** | Staging → DML → Zieltabelle | `sql/dml/10_import_csv.sql` · `sql/dml/20_cleanup_and_load.sql` · `sql/dml/30_drop_staging.sql` |
| **MS B 1.5 · Tests lokal** | 13 Datentests + 19 Rollen-Tests (pos/neg), auf MariaDB reproduziert | `sql/dql/50_data_consistency.sql` · `sql/dql/60_tests_roles.sql` · `docs/MS_B_1_5_Testprotokolle.md` · `docs/Reproduktion_Lokal.md` · `screenshots/local_*.{png,txt}` |
| **DB-Dump / Backup** | Struktur + Daten, `mysqldump --single-transaction` | `backpacker_lb3_giovanni_dump.sql(.gz)` |
| **MS C 2.1 · Cloud Setup (+Bonus)** | **Eigene Cloud** (self-hosted MariaDB-LXC) → max. Bonus; **LIVE** deployt | `docs/MS_C_Cloud_SelfHosted.md` · `sql/repro/setup_cloud_selfhosted.sh` · `screenshots/cloud_rds_dashboard.*` |
| **MS C 2.2 · Cloud-Betrieb** | 8-Punkte-Härtung, TLS erzwungen, IP-Allowlist | `docs/MS_C_Cloud_SelfHosted.md` §3–5 · `config/my_cloud_selfhosted.cnf` · `screenshots/cloud_rds_konfiguration.*` · `screenshots/cloud_rds_security_group.*` |
| **MS D 3.1 · DCL automatisiert in Cloud** | DCL-Apply per TLS (Rollen + `REQUIRE SSL`) | `sql/dcl/04_selfhosted_cloud_users.sql` · `sql/migration/migrate_local_to_selfhosted.sh` |
| **MS D 3.2 · DDL/DML automatisiert** | mysqldump + restore via TLS (verifiziert) | `sql/migration/migrate_local_to_selfhosted.sh` · `screenshots/cloud_migration_run.*` |
| **MS D 3.3 · Cloud-Tests** | Counts 2036/…/1746, FK=5, utf8mb4, Rollen, TLS-Negativtest | `sql/dql/70_tests_cloud.sql` · `screenshots/cloud_tests_data.*` · `screenshots/cloud_tls_required.*` |
| **MS D 3.4 · Migrations-Test mit Datensatz** | Persönlicher Test-Datensatz `Giovanni-Test` (in Cloud verifiziert) | `sql/dml/40_testdaten_migration.sql` |
| **Demo (3 User auf Cloud)** | Drei TLS-Logins, je eigene Rolle, 1142/1143 | `screenshots/cloud_demo_3_users.*` · `docs/Demo_Skript.md` |
| **Dokumentation / Urheberbeweis** | KI-Prompts protokolliert, Personalisierung überall | `prompts/ki_prompts.md`, alle SQL-Header |

---

## 3. Repository-Struktur

```
LB3-Praxisarbeit/
├── README.md                       ← TBZ-Original-Aufgabenstellung (unverändert)
├── README_Praxisarbeit.md          ← Diese Datei (Projekt-Index)
├── .gitignore                      ← OS/Office-Junk und Secrets ausgeschlossen
├── cleanup_before_upload.ps1       ← Helper zum Aufräumen vor GitLab-Upload
├── M141 LB3 Bewertung LE.xlsx      ← Selbsteinschätzungs-Matrix (Note 5.95)
├── backpacker_lb3_giovanni_dump.sql(.gz) ← DB-Dump (Backup, Struktur+Daten) — Abgabe-Deliverable
├── backpacker_ddl_lb3.sql          ← Original-DDL der Quell-DB
├── backpacker_lb3.png              ← Original-ERD der Quell-DB
├── ca.pem                          ← Aiven CA-Zertifikat (TLS, öffentlich)
│
├── docs/                           ← Markdown-Dokumentation pro Meilenstein
│   ├── MS_A_Anforderungsdefinition.md
│   ├── MS_A_Cloud_Evaluation.md
│   ├── MS_B_1_1_ERD_2NF.md
│   ├── MS_B_1_2_Zugriffsmatrix.md
│   ├── MS_B_1_5_Testprotokolle.md
│   ├── MS_C_Cloud_Setup.md
│   ├── MS_D_Migration.md
│   ├── Demo_Skript.md
│   ├── Fazit.md
│   ├── MS_C_Cloud_SelfHosted.md    ← Eigene Cloud auf Proxmox (Bonus): Setup+Härtung, LIVE deployt
│   ├── Protokollierung.md
│   ├── Reproduktion_Lokal.md       ← Nachweis: DB aus Skripten reproduzierbar (MariaDB-Lauf)
│   └── STEP_BY_STEP_GUIDE.md
│
├── sql/                            ← Alle SQL-Skripte
│   ├── ddl/
│   │   ├── 01_create_database.sql
│   │   ├── 02_create_tables.sql    ← Schema 2.NF, InnoDB, FK, CHECK
│   │   └── 03_create_staging.sql
│   ├── dml/
│   │   ├── 10_import_csv.sql       ← LOAD DATA aus csv/
│   │   ├── 20_cleanup_and_load.sql ← Bereinigung & Insert in Zieltabellen
│   │   ├── 30_drop_staging.sql
│   │   └── 40_testdaten_migration.sql ← Personalisierter Test-Datensatz
│   ├── dcl/
│   │   ├── 01_roles_users.sql      ← Lokale Rollen & User
│   │   ├── 02_revoke_all.sql       ← Vorab-Reset
│   │   └── 03_cloud_users.sql      ← Cloud (MySQL 8) inkl. REQUIRE SSL
│   ├── dql/
│   │   ├── 50_data_consistency.sql ← Lokale Daten-Konsistenz-Tests
│   │   ├── 60_tests_roles.sql      ← Rollen-Tests positiv/negativ
│   │   └── 70_tests_cloud.sql      ← Cloud-Tests (Counts, FK, TLS, Rollen)
│   ├── repro/
│   │   ├── run_lb3_local.sh        ← One-Shot-Reproduktion der lokalen DB (MariaDB)
│   │   ├── setup_cloud_selfhosted.sh ← Setup eigene Cloud (MariaDB+TLS+Härtung, idempotent)
│   │   ├── recover_and_deploy_freya.sh ← freya-Recovery-Orchestrator (Firewall-Stop zuerst)
│   │   └── preflight_demo.sh       ← Demo-Preflight: 21 Checks + Auto-Heal + GO/NO-GO
│   └── migration/
│       ├── do_migration.ps1            ← One-Shot-Wrapper (PowerShell)
│       ├── migrate_local_to_cloud.ps1  ← Detaillierte PS-Migration
│       ├── migrate_local_to_cloud.sh   ← Bash-Variante (Linux/macOS)
│       └── aiven-ca.pem                ← TLS-CA-Cert für mysql --ssl-ca
│
├── csv/                            ← Quelldaten als CSV (Access-Export)
│   ├── tbl_personen.csv
│   ├── tbl_buchung.csv
│   ├── tbl_positionen.csv
│   ├── tbl_benutzer.csv
│   ├── tbl_land.csv
│   └── tbl_leistung.csv
│
├── config/
│   ├── my_aiven.cnf                ← Aiven "Advanced configuration" dokumentiert
│   └── my_aws.cnf                  ← Historisch (geplante AWS-Variante, nicht produktiv)
│
├── prompts/
│   └── ki_prompts.md               ← Vollständige KI-Prompt-Historie
│
├── screenshots/                    ← Nachweise (je PNG + rohe .txt)
│   ├── local_phpmyadmin_db_uebersicht.png/.txt
│   ├── local_phpmyadmin_fk_constraints.png/.txt
│   ├── local_users_grants.png/.txt
│   ├── local_tests_data.png/.txt
│   ├── local_tests_roles_positiv.png/.txt
│   ├── local_tests_roles_negativ.png/.txt
│   ├── cloud_rds_dashboard.png/.txt      ← Cloud-DBMS-Übersicht (Proxmox/MariaDB)
│   ├── cloud_rds_konfiguration.png/.txt  ← Connection-Info + gehärtete my.cnf
│   ├── cloud_rds_security_group.png/.txt ← Firewall-Allowlist (kein 0.0.0.0/0)
│   ├── cloud_migration_run.png/.txt      ← Migration per TLS (Restore+DCL)
│   ├── cloud_verbindung_giovanni.png/.txt← TLS-Login OK (TLSv1.3)
│   ├── cloud_tls_required.png/.txt       ← Negativ-Test (ERROR 3159 ohne TLS)
│   ├── cloud_tests_data.png/.txt         ← 70_tests_cloud.sql
│   └── cloud_demo_3_users.png/.txt       ← 3 Rollen-User per TLS (1142/1143)
│
└── x_res/
    └── LB3-Rahmen.png              ← Original-Rahmenbild der Aufgabenstellung
```

---

## 4. Personalisierung (durchgängig vorhanden)

| Asset | Wert |
|---|---|
| Datenbank-Name | `backpacker_lb3_giovanni` |
| Aiven-Project | `giovanni-m141-lb3` |
| Aiven-Service | `backpacker-aiven-giovanni-giovannimerola1` |
| Cloud-Region | `do-ams` (Amsterdam) |
| Cloud-Master-User | `avnadmin` (Aiven-Default) |
| Anwendungs-User | `giovanni_benutzer`, `giovanni_manager`, `giovanni_dba` |
| Personalisierter Test-Datensatz | `Giovanni-Test` in `tbl_personen` (siehe `sql/dml/40_testdaten_migration.sql`) |
| Migrations-Test-Leistung | "Migrations-Testleistung Giovanni" in `tbl_leistung` |

---

## 5. Quick-Run (Reproduktion)

### 5.1 Lokal (MariaDB / XAMPP)

```bash
mysql -u root -p < sql/ddl/01_create_database.sql
mysql -u root -p backpacker_lb3_giovanni < sql/ddl/02_create_tables.sql
mysql -u root -p backpacker_lb3_giovanni < sql/ddl/03_create_staging.sql
mysql -u root -p --local-infile=1 backpacker_lb3_giovanni < sql/dml/10_import_csv.sql
mysql -u root -p backpacker_lb3_giovanni < sql/dml/20_cleanup_and_load.sql
mysql -u root -p backpacker_lb3_giovanni < sql/dml/30_drop_staging.sql
mysql -u root -p backpacker_lb3_giovanni < sql/dcl/01_roles_users.sql
mysql -u root -p backpacker_lb3_giovanni < sql/dml/40_testdaten_migration.sql
mysql -u root -p backpacker_lb3_giovanni < sql/dql/50_data_consistency.sql
```

### 5.2 Migration in die Cloud (Aiven)

```powershell
# Passwort einmalig setzen (NICHT committen):
$env:CLOUD_PWD = "AVNS_..."        # aus Aiven Console "Show password"

cd sql\migration
.\do_migration.ps1
```

Detaillierte Schritte mit Screenshots: siehe `docs/STEP_BY_STEP_GUIDE.md` und `docs/MS_D_Migration.md`.

---

## 6. Sicherheits-Hinweise

- **Keine produktiven Passwörter im Repo.** Das Aiven-Master-Passwort lebt ausschliesslich im Aiven-Console (und im Passwort-Manager). Der Migrationsskript erwartet es als `$env:CLOUD_PWD` zur Laufzeit.
- **`ca.pem` ist das öffentliche CA-Zertifikat von Aiven** und somit kein Geheimnis. Es dient zur TLS-Validierung und wird intentional eingecheckt.
- **DB-User-Passwörter (`Cloud!Benutzer-Giovanni-2026` u. a.)** sind Demo-Credentials, die das Bewertungs-Schema verlangt (funktionierender DCL-Lauf). Diese werden unmittelbar nach der LB3-Demo rotiert oder durch Termination des Aiven-Services entwertet.
- **IP-Allowlist** ist auf die eigene öffentliche IP/32 beschränkt (kein `0.0.0.0/0`). Siehe `screenshots/cloud_rds_security_group.png`.
- **TLS service-level erzwungen** durch Aiven (`require_secure_transport = ON`). Zusätzlich `REQUIRE SSL` auf jedem App-User.
- **`.gitignore`** schliesst Lockfiles, OS-Junk, Dumps und Secret-Dateien aus.

---

## 7. Selbsteinschätzung

Siehe `M141 LB3 Bewertung LE.xlsx` (B4 = Giovanni Merola, D28 = 43.5, **Note D30 = 5.95**).

Begründung der Selbsteinstufung pro Zeile inkl. konkreter Artefakt-Referenz: ebd. Kommentar-Spalte.

---

## 8. Sign-off

*Demo am 30.06.2026 vor LP. Demo-Skript siehe `docs/Demo_Skript.md`.*

**Giovanni Merola · M141 LB3 · 30.06.2026**
