# Kapitel 4 – Protokollierung der Arbeitspakete

*Autor: Giovanni Merola · M141 · LB3 · Stand 30.06.2026*

## 1. Übersicht / Index

| MS / Kapitel | Datei | Stand |
|---|---|---|
| MS A – Anforderungsdefinition | `docs/MS_A_Anforderungsdefinition.md` | ✅ |
| MS A – Cloud-Evaluation | `docs/MS_A_Cloud_Evaluation.md` | ✅ |
| MS B 1.1 – ERD 2.NF | `docs/MS_B_1_1_ERD_2NF.md` | ✅ |
| MS B 1.2 – Zugriffsmatrix | `docs/MS_B_1_2_Zugriffsmatrix.md` | ✅ |
| MS B 1.3 – DCL (Roles) | `sql/dcl/01_roles_users.sql` | ✅ |
| MS B 1.4 – DDL/Import/Cleanup | `sql/ddl/*`, `sql/dml/*` | ✅ |
| MS B 1.5 – Testprotokolle lokal | `docs/MS_B_1_5_Testprotokolle.md` | ✅ |
| MS C – Cloud-Setup | `docs/MS_C_Cloud_Setup.md`, `config/my_aiven.cnf` | ✅ |
| MS D – Migration | `docs/MS_D_Migration.md`, `sql/migration/*` | ✅ |
| Kapitel 4 – Protokollierung | dieser Text | ✅ |
| Demo-Script | `docs/Demo_Skript.md` | ✅ |
| Bewertungsmatrix Selbsteinschätzung | `M141 LB3 Bewertung LE.xlsx` | ✅ |
| KI-Prompts | `prompts/ki_prompts.md` | ✅ |

## 2. Vorgehen (Working Log)

| Datum | Tag | Tätigkeit | Output |
|---|---|---|---|
| 06.05.2026 | T8 | Kick-off, Anforderungen aufgenommen, Cloud-Eval | `MS_A_*` |
| 07.05.2026 | – | Lokales XAMPP-Setup, DB-Schema in 2.NF | `02_create_tables.sql` |
| 08.05.2026 | – | Staging + CSV-Import + Cleanup-DML | `10_import_csv.sql`, `20_cleanup_and_load.sql` |
| 09.05.2026 | T9 | DCL, Rollen, Spaltenrechte, Tests | `01_roles_users.sql`, `60_tests_roles.sql` |
| 10.05.2026 | – | Konsistenz-Queries, Testprotokoll Lokal | `50_data_consistency.sql`, `MS_B_1_5_Testprotokolle.md` |
| 12.05.2026 | – | Aiven Instanz `backpacker-aiven-giovanni` aufgesetzt, gehärtet | `MS_C_Cloud_Setup.md` + Screenshots |
| 13.05.2026 | – | Migration-Wrapper + DCL-Apply + Cloud-Tests | `migrate_local_to_cloud.sh`, `70_tests_cloud.sql` |
| 14.05.2026 | – | Demo-Drill, Bewertungsmatrix-Selbsteinschätzung | `Demo_Skript.md` |
| 30.06.2026 | T10 | Endabnahme, Repo-Commit, Demo vor LP | – |

## 3. Repository-Struktur

```
m141-main-LB3-Praxisarbeit/
└── LB3-Praxisarbeit/
    ├── README.md                       (Original Aufgabenstellung TBZ)
    ├── README_Praxisarbeit.md          (Master README, Einstieg in die Arbeit)
    ├── backpacker_ddl_lb3.sql          (Original-DDL)
    ├── backpacker_lb3.csv.zip          (Original-Daten)
    ├── backpacker_lb3.png              (Original-ERD)
    ├── M141 LB3 Bewertung LE.xlsx      (Selbsteinschätzung)
    ├── docs/
    │   ├── MS_A_Anforderungsdefinition.md
    │   ├── MS_A_Cloud_Evaluation.md
    │   ├── MS_B_1_1_ERD_2NF.md
    │   ├── MS_B_1_2_Zugriffsmatrix.md
    │   ├── MS_B_1_5_Testprotokolle.md
    │   ├── MS_C_Cloud_Setup.md
    │   ├── MS_D_Migration.md
    │   ├── Protokollierung.md          (← Sie sind hier)
    │   ├── Demo_Skript.md
    │   └── Fazit.md
    ├── sql/
    │   ├── ddl/
    │   │   ├── 01_create_database.sql
    │   │   ├── 02_create_tables.sql
    │   │   └── 03_create_staging.sql
    │   ├── dcl/
    │   │   ├── 01_roles_users.sql       (lokal)
    │   │   ├── 02_revoke_all.sql
    │   │   └── 03_cloud_users.sql        (cloud, REQUIRE SSL)
    │   ├── dml/
    │   │   ├── 10_import_csv.sql
    │   │   ├── 20_cleanup_and_load.sql
    │   │   ├── 30_drop_staging.sql
    │   │   └── 40_testdaten_migration.sql
    │   ├── dql/
    │   │   ├── 50_data_consistency.sql
    │   │   ├── 60_tests_roles.sql
    │   │   └── 70_tests_cloud.sql
    │   └── migration/
    │       ├── migrate_local_to_cloud.sh
    │       └── migrate_local_to_cloud.ps1
    ├── config/
    │   ├── my_aiven.cnf                (produktiv, Aiven)
    │   └── my_aws.cnf                  (historisch, AWS-Variante)
    ├── prompts/
    │   └── ki_prompts.md
    ├── screenshots/                    (personalisierte Screenshots)
    └── x_res/                          (vorgegebene Ressourcen)
```

## 4. Reproduktion (One-Command-Setup)

```bash
# 1. Lokale DB erstellen + Tabellen
mysql -u root -p < sql/ddl/01_create_database.sql
mysql -u root -p backpacker_lb3_giovanni < sql/ddl/02_create_tables.sql
mysql -u root -p backpacker_lb3_giovanni < sql/ddl/03_create_staging.sql

# 2. CSVs entpacken nach ./csv/ (CSV-Pfad in 10_import_csv.sql anpassen)
unzip backpacker_lb3.csv.zip -d ./csv/

# 3. Import + Cleanup
mysql -u root -p --local-infile=1 backpacker_lb3_giovanni < sql/dml/10_import_csv.sql
mysql -u root -p backpacker_lb3_giovanni < sql/dml/20_cleanup_and_load.sql
mysql -u root -p backpacker_lb3_giovanni < sql/dml/30_drop_staging.sql

# 4. Rollen + User
mysql -u root -p backpacker_lb3_giovanni < sql/dcl/01_roles_users.sql

# 5. Testdaten
mysql -u root -p backpacker_lb3_giovanni < sql/dml/40_testdaten_migration.sql

# 6. Tests
mysql -u root -p backpacker_lb3_giovanni < sql/dql/50_data_consistency.sql
mysql -u giovanni_benutzer -p backpacker_lb3_giovanni < sql/dql/60_tests_roles.sql
mysql -u giovanni_manager  -p backpacker_lb3_giovanni < sql/dql/60_tests_roles.sql

# 7. Migration in die Cloud
export CLOUD_HOST=backpacker-aiven-giovanni-giovannimerola1.h.aivencloud.com
export CLOUD_PORT=13544
export CLOUD_USER=avnadmin
export CLOUD_PWD='__PWD__'   # paste from Aiven Console -> Service -> "Show password"
bash sql/migration/migrate_local_to_cloud.sh

# 8. Cloud-Tests
mysql -h $CLOUD_HOST -u $CLOUD_USER -p$CLOUD_PWD \
      --ssl-mode=REQUIRED --ssl-ca=aiven-ca.pem \
      backpacker_lb3_giovanni < sql/dql/70_tests_cloud.sql
```

## 5. Abnahme-Kriterien (Self-Check)

| Anf. ID | Beschreibung | Status |
|---|---|---|
| FA-01 | Lokale DB `backpacker_lb3_giovanni` 2.NF | ✅ |
| FA-02 | CSV-Import (LOAD DATA) | ✅ |
| FA-03 | Datenbereinigung | ✅ |
| FA-04 | Rollen aktiv | ✅ |
| FA-05 | min. 1 User pro Rolle | ✅ |
| FA-06 | Testprotokolle | ✅ |
| FA-07 | Aiven gehärtet | ✅ |
| FA-08 | Automatische Migration | ✅ |
| FA-09 | DCL automatisiert | ✅ |
| FA-10 | Cloud-Testprotokolle | ✅ |
| FA-11 | Demo-Script bereit | ✅ |
| NFA-01..10 | siehe Anforderungsdef. | ✅ |
