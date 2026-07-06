# Screenshots – LB3 Backpacker_LB3 – Giovanni Merola

Hier liegen die personalisierten Nachweise (mit sichtbarem "giovanni"), die zur Verteidigung der Praxisarbeit gehören.

> **Reproduktion der lokalen Nachweise (2026-07-02).** Die lokalen Nachweise (`local_*`) wurden auf einer frisch aufgesetzten **MariaDB**-Instanz End-to-End nachgefahren (kompletter Pipeline-Lauf `sql/ddl/01` → `sql/dql/50`, Treiber-Script: [`sql/repro/run_lb3_local.sh`](../sql/repro/run_lb3_local.sh)). Zu jedem `local_*.png` liegt die **rohe Konsolen-Ausgabe** als gleichnamiges `local_*.txt` daneben — die Bilder sind nur die gerenderte Form derselben echten Ausgabe. Alle Objektnamen (`backpacker_lb3_giovanni`, `giovanni_benutzer/manager/dba`) sind personalisiert.

| Datei | Inhalt | Quelle |
|---|---|---|
| `local_phpmyadmin_db_uebersicht.png` / `.txt`* | DB `backpacker_lb3_giovanni`, 6 Tabellen (InnoDB) mit echten Zeilenzahlen + Kollation | MariaDB CLI (`information_schema.TABLES`) |
| `local_phpmyadmin_fk_constraints.png` / `.txt`* | Alle 5 FK-Constraints mit ON UPDATE/DELETE-Regeln | MariaDB CLI (`REFERENTIAL_CONSTRAINTS`) |
| `local_users_grants.png` / `.txt` | `SHOW GRANTS` für alle 3 User + beide Rollen (Spaltenrechte auf `tbl_benutzer` sichtbar) | MariaDB CLI |
| `local_tests_data.png` / `.txt` | Ergebnisse `50_data_consistency.sql` (T-D-01 … T-D-12) | MariaDB CLI |
| `local_tests_roles_positiv.png` / `.txt` | Positive Rollen-Tests (A/B, erwartet OK) | MariaDB CLI |
| `local_tests_roles_negativ.png` / `.txt` | Negativ-Tests mit echten `ERROR 1142` / `ERROR 1143` | MariaDB CLI |

*Die beiden `phpmyadmin_*`-Bilder tragen den historischen XAMPP-Dateinamen, zeigen bei der Reproduktion aber die äquivalente CLI-Ausgabe aus `information_schema` (gleiche Nachweis-Aussage).*

> **Zwei Nachweis-Stände (bewusst dokumentiert).** `screenshots/local_test_run_giovanni_2026-06-30.txt` ist der **ursprüngliche Abgabe-Lauf vom 30.06.2026** (MariaDB 10.6). Der kanonische, aktuelle Nachweis-Satz sind die `local_tests_*` / `local_users_grants` / `local_phpmyadmin_*` (Reproduktion 02.07.2026 auf MariaDB 11.8). **Beide zeigen identische Ergebnisse** (2036/11/82/8/1006/1746). Einziger Darstellungsunterschied: der 30.06-Lauf weist die Prüfung noch unter dem kombinierten Alias `verletzte_checks = 22` aus; im kanonischen `local_tests_data.txt` ist sie zur Klarheit in **`rabatt_check_verletzt = 0`** (erzwungener CHECK) und **`stornos_zeilen_total = 22`** (bewusst erlaubte negative Anzahl/Preis) aufgeteilt — dieselben 22 Zeilen, kein Fehler.

**Cloud-Nachweise (eigene Cloud, `cloud_*`) — LIVE deployt 06.07.2026 auf `192.168.1.62:3306`:**

Zu jedem `cloud_*.png` liegt die rohe Konsolen-Ausgabe als gleichnamiges `.txt` daneben.

| Datei | Inhalt | Quelle |
|---|---|---|
| `cloud_rds_dashboard.png` / `.txt` | Cloud-DBMS-Übersicht: LXC `cloud-db-giovanni` läuft, MariaDB 11.8.6, Endpoint `192.168.1.62:3306` | Proxmox `pct` (Homelab) |
| `cloud_rds_konfiguration.png` / `.txt` | Verbindungs-Info + gehärtete `my.cnf` (`require_secure_transport`, TLS-Certs, `local-infile=0`, slow/error log) | MariaDB CLI |
| `cloud_rds_security_group.png` / `.txt` | Firewall-Allowlist (`9003.fw`): nur benötigte Quell-IPs auf `:3306`, kein `0.0.0.0/0`, `policy_in: DROP` | Proxmox-Firewall |
| `cloud_verbindung_giovanni.png` / `.txt` | TLS-Login als `giovanni_dba@%`, Server `cloud-db-giovanni`, TLSv1.3 / `TLS_AES_256_GCM_SHA384` | MariaDB CLI (TLS) |
| `cloud_migration_run.png` / `.txt` | Automatisierte Migration per TLS: DB anlegen → Dump-Restore → DCL → Smoke-Test | MariaDB CLI (TLS) |
| `cloud_tls_required.png` / `.txt` | Negativ: Login **ohne** TLS → `ERROR 3159 … insecure transport prohibited`; positiv mit TLS OK | MariaDB CLI |
| `cloud_tests_data.png` / `.txt` | `70_tests_cloud.sql`: Counts 2036/11/82/8/1006/1746, FK=5, utf8mb4, Rollen | MariaDB CLI (TLS) |
| `cloud_demo_3_users.png` / `.txt` | Demo: `giovanni_benutzer/manager/dba` verbinden per TLS, Rollen erzwungen (`ERROR 1142`/`1143`) | MariaDB CLI (TLS) |

> **Hinweis Cloud-Nachweise (`cloud_*`).** Dies ist die **eigene Cloud-DB** (selbstgehosteter MariaDB-LXC auf dem Proxmox-Homelab, TLS erzwungen) — siehe `docs/MS_C_Cloud_SelfHosted.md`. Alle Nachweise sind mit dem Setup-/Migrations-Tooling im Repo **reproduzierbar** (`sql/repro/setup_cloud_selfhosted.sh`, `sql/migration/migrate_local_to_selfhosted.sh`). Die öffentliche CA liegt als `cloud-ca-giovanni.pem` bei. Für die LB3-Demo verbinden sich die drei Cloud-User live per TLS (siehe `docs/Demo_Skript.md`).

**Wichtig**: Jeder Screenshot muss den personalisierten Namen ("giovanni") **sichtbar** enthalten (Prompt, DB-Name, User, Identifier), gemäss Vorgabe "Urheberbeweis" im Aufgaben-Rahmen.
