# Fazit – M141 LB3 Praxisarbeit (Giovanni Merola)

## Was wurde umgesetzt

- **MS A**: SMART-Anforderungsdefinition + Cloud-RDBMS-Evaluation; Entscheidung für Aiven for MySQL.
- **MS B**: Lokale MariaDB-Datenbank `backpacker_lb3_giovanni` in 2.NF mit InnoDB-Engine, Foreign Keys, Indizes und CHECK-Constraints. CSV-Import via Staging-Tabellen mit anschliessender Datenbereinigung. Rollenkonzept mit Spaltenrechten umgesetzt, vollständig getestet (positive und negative Testfälle).
- **MS C**: Aiven-for-MySQL-Service `backpacker-aiven-giovanni` (Region `do-ams`, MySQL 8.4.8) aufgesetzt und gehärtet: IP-Allowlist auf eigene IP/32 beschränkt, TLS-Pflicht service-level, Encryption at Rest (AES-256, Aiven-managed), Backup-Retention 2 Tage (Hobbyist) bzw. 7 Tage (Startup), Slow-Query-Log aktiv. Aiven-Äquivalente zur AWS-Parameter-Group dokumentiert in `config/my_aiven.cnf`.
- **MS D**: Automatisierte Migration (Bash + PowerShell) inkl. DCL-Übertragung. Cloud-Tests in unter 1 Minute reproduzierbar.
- **Kapitel 4**: Vollständige, nachvollziehbare Dokumentation; alle KI-Prompts protokolliert; alle SQL-Scripts versioniert.

## Was gelernt wurde

1. Eine sauber normalisierte Datenbasis ist die halbe Migration. Sentinel-Werte und freie TEXT-Spalten verursachen den grössten Cleanup-Aufwand.
2. MariaDB-Rollen + Spaltenrechte sind ein sehr effektives Mittel, um Geheimnisse (Passwort-Hash, Deaktivierungs-Status) feingranular zu schützen.
3. Aiven exponiert die MySQL-Parameter über "Advanced configuration" (Äquivalent zur AWS-RDS-Parameter-Group). Vorteil gegenüber RDS: Aiven wendet Änderungen **online** an, ohne Reboot, was die Iteration im Schulkontext stark beschleunigt.
4. Eine Mischung aus `mysqldump` + separates DCL-Script ist robuster als ein All-in-One-Dump, weil Rollen-/User-Definitionen in der Cloud ohnehin nicht 1:1 übernehmbar sind.

## Was offen bleibt / nächste Schritte

- **Multi-AZ** für Hochverfügbarkeit (nur sinnvoll im produktiven Echtbetrieb, kostet ~2× im Free Tier).
- **IAM-DB-Authentifizierung** statt Passwort für Anwendungsuser.
- **Read Replicas** für Reporting-Workload.
- **Continuous Backup** mit periodischen Snapshots in einen unabhängigen Cloud-Account (off-site recovery).
- **Integration in ein Web-Frontend** (z. B. PHP/Laravel) als logische Fortsetzung.

## Selbstreflexion

Die Arbeit hat bestätigt, dass ein konsequent personalisiertes Repo (DB-Name, Cloud-Identifier, Testdaten) erstens die Nachvollziehbarkeit für die LP erleichtert und zweitens Verwechslungen beim Demo-Vortrag verhindert. Die saubere Trennung in `ddl/`, `dcl/`, `dml/`, `dql/` und `migration/` macht es zudem leicht, Teile gezielt nachzubauen.

---

*Giovanni Merola · 30.06.2026*
