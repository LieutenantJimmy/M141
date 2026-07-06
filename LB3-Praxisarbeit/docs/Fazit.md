# Fazit – M141 LB3 Praxisarbeit (Giovanni Merola)

## Was wurde umgesetzt

- **MS A**: SMART-Anforderungsdefinition + Cloud-RDBMS-Evaluation (AWS → Aiven → **finaler Entscheid: eigene Cloud**). *Aiven wurde evaluiert, aber bewusst zugunsten der eigenen Homelab-Cloud verworfen — volle Kontrolle, kein Vendor-Lock, Max-Bonus.*
- **MS B**: Lokale MariaDB-Datenbank `backpacker_lb3_giovanni` in 2.NF mit InnoDB-Engine, Foreign Keys, Indizes und CHECK-Constraints. CSV-Import via Staging-Tabellen mit anschliessender Datenbereinigung. Rollenkonzept mit Spaltenrechten umgesetzt, vollständig getestet (positive und negative Testfälle).
- **MS C (produktiv, eigene Cloud)**: Selbstgehostete Cloud-DB `cloud-db-giovanni` (unprivilegierter MariaDB-LXC, Endpoint `192.168.1.62:3306`) aufgesetzt und gehärtet: **TLS erzwungen** (TLSv1.3, eigene CA mit SAN), IP-Allowlist mit Default-Deny (kein `0.0.0.0/0`), `local-infile=0`, `skip-name-resolve`, Slow-/Error-Log, Least-Privilege-User. 8 Härtungspunkte einzeln live belegt (`VERIFICATION.md`). *(Die evaluierte Aiven-Variante inkl. Härtungs-Äquivalenten bleibt als `MS_C_Cloud_Setup.md`/`config/my_aiven.cnf` dokumentiert.)*
- **MS D**: Automatisierte Migration per TLS (Dump + Restore + DCL) — **idempotent, zweifach verifiziert**, Row-Counts lokal=Cloud identisch, in unter 1 Minute reproduzierbar.
- **Kapitel 4**: Vollständige, nachvollziehbare Dokumentation; alle KI-Prompts protokolliert; alle SQL-Scripts versioniert.

## Was gelernt wurde

1. Eine sauber normalisierte Datenbasis ist die halbe Migration. Sentinel-Werte und freie TEXT-Spalten verursachen den grössten Cleanup-Aufwand.
2. MariaDB-Rollen + Spaltenrechte sind ein sehr effektives Mittel, um Geheimnisse (Passwort-Hash, Deaktivierungs-Status) feingranular zu schützen.
3. *(aus der Aiven-Evaluation)* Managed-Anbieter exponieren MySQL-Parameter über eine "Advanced configuration" (Äquivalent zur AWS-Parameter-Group) und wenden Änderungen online an — bequem, aber die Mechanik dahinter bleibt verborgen. Genau deshalb fiel der finale Entscheid auf die **eigene Cloud**: TLS-Zertifikate, Firewall und `my.cnf`-Härtung selbst zu bauen zeigt die Kompetenz, statt sie zu mieten.
4. Eine Mischung aus `mysqldump` + separates DCL-Script ist robuster als ein All-in-One-Dump, weil Rollen-/User-Definitionen in der Cloud ohnehin nicht 1:1 übernehmbar sind.
5. Eigene Infrastruktur heisst eigene Verantwortung: Der Ausfall des ersten Ziel-Hosts (freya) mitten im Setup wurde durch host-agnostische, idempotente Skripte aufgefangen — Re-Deployment auf einem zweiten Host in unter einer Stunde, plus Golden Snapshot als Demo-Sicherheitsnetz.

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
