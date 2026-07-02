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
| `cloud_rds_dashboard.png` | Aiven-Konsole: Service `backpacker-aiven-giovanni-giovannimerola1`, Status Running (do-ams) | Aiven Console |
| `cloud_rds_konfiguration.png` | "Connection information"-Card: Host, Port, User, DB sichtbar (Passwort maskiert) | Aiven Console |
| `cloud_rds_security_group.png` | "Allowed inbound IP addresses" mit eigener IP/32 (kein 0.0.0.0/0) | Aiven Console |
| `cloud_rds_parameter_group.png` *(optional)* | "Advanced configuration" mit sql_mode / slow_query_log / wait_timeout. Falls nicht vorhanden, deckt `cloud_tls_required.png` den TLS-Pflicht-Nachweis ab. | Aiven Console |
| `cloud_verbindung_giovanni.png` | mysql-Login per TLS auf Cloud-Endpoint, Name "giovanni" im Prompt | Terminal |
| `cloud_migration_run.png` | Konsolen-Output von `migrate_local_to_cloud.sh` | Terminal |
| `cloud_tls_required.png` | Login ohne `--ssl-mode=REQUIRED` → "Insecure transport prohibited" | Terminal |
| `cloud_tests_data.png` | `70_tests_cloud.sql` Output | Terminal |
| `cloud_demo_3_users.png` | 3 Terminal-Tabs mit `giovanni_benutzer`, `giovanni_manager`, `giovanni_dba` | Terminal |

> **Hinweis Cloud-Nachweise (`cloud_*`).** Die Cloud-Screenshots dokumentieren den Aiven-Service, auf dem die Migration vorgeführt wurde. Der Aiven-Service selbst kann nicht ohne Live-Zugang zur Aiven-Konsole reproduziert werden; die zugehörigen echten Konsolen-Ausgaben liegen als `cloud_tests_results.txt` bei. Für die LB3-Demo werden die drei Cloud-User (`giovanni_benutzer/manager/dba`) live per TLS verbunden (siehe `docs/Demo_Skript.md`).

**Wichtig**: Jeder Screenshot muss den personalisierten Namen ("giovanni") **sichtbar** enthalten (Prompt, DB-Name, User, Identifier), gemäss Vorgabe "Urheberbeweis" im Aufgaben-Rahmen.
