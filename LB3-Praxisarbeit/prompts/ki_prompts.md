# KI-Prompts – M141 LB3 (Urheber: Giovanni Merola)

Diese Datei dokumentiert die wesentlichen Prompts, die im Verlauf der LB3-Praxisarbeit gegenüber KI-Assistenten (z. B. Claude / ChatGPT) verwendet wurden. Sie dient der Nachvollziehbarkeit (Punkt "Urheberbeweis" im Rahmen).

> **Hinweis zur Provider-Pivot:** Der ursprüngliche Prompt A-01 spricht noch von "AWS-Cloud", weil das die initiale Annahme war. Nach Klärung der Zugriffsrechte (kein TBZ-AWS-Account verfügbar, siehe `MS_A_Cloud_Evaluation.md`) wurde der Cloud-Anbieter auf **Aiven for MySQL** gewechselt. Die alten Prompts werden bewusst nicht nachträglich umgeschrieben, um die Iterations-Historie ehrlich abzubilden.
>
> **Finale Pivot (06.07.2026):** Aiven wurde evaluiert, aber bewusst zugunsten der **eigenen Homelab-Cloud** verworfen (volle Kontrolle, kein Vendor-Lock, Max-Bonus «eigene Cloud-DB»). Die Aiven-bezogenen Prompts (Abschnitte E/F) bleiben als ehrliche Historie erhalten. Für die eigene Cloud kamen KI-gestützt hinzu: Setup-/Härtungs-Skript (`sql/repro/setup_cloud_selfhosted.sh`), Cloud-DCL (`04_selfhosted_cloud_users.sql`), TLS-Migrations-Wrapper (`migrate_local_to_selfhosted.sh`), Demo-Preflight (`preflight_demo.sh`) und das Live-Audit (`VERIFICATION.md`).

Format: **#** · *Phase* · *Prompt* · *Output-Datei*

---

## A. Anforderungen / Definition (MS A)

**A-01** · MS A
> "Schreibe mir eine SMART-Anforderungsdefinition für die LB3-Praxisarbeit zur Migration der Backpacker-Access-DB auf MariaDB lokal und in die AWS-Cloud. Personalisiert mit Name 'Giovanni Merola'. Inkl. funktionale + nicht-funktionale Anforderungen, Risiken und Abnahmekriterien."
→ `docs/MS_A_Anforderungsdefinition.md`

**A-02** · MS A
> "Vergleiche Aiven for MySQL, Azure DB for MariaDB, Google CloudSQL MySQL und Self-Managed Hetzner für ein Schulprojekt. Bewertungsmatrix mit gewichteten Kriterien. Empfehlung mit Begründung."
→ `docs/MS_A_Cloud_Evaluation.md`

## B. Normalisierung & Schema (MS B 1.1)

**B-01** · MS B 1.1
> "Analysiere das gegebene `backpacker_ddl_lb3.sql` (MyISAM, latin1, viel TEXT, kein FK) und entwirf eine 2.NF-Variante in InnoDB/utf8mb4 mit FKs, Indizes und CHECK-Constraints. Stelle Begründungen pro Datentyp-Änderung dar."
→ `docs/MS_B_1_1_ERD_2NF.md`, `sql/ddl/02_create_tables.sql`

**B-02** · MS B 1.1
> "Erzeuge ein Mermaid erDiagram für das normalisierte Schema mit allen FK-Beziehungen 1:n."
→ `docs/MS_B_1_1_ERD_2NF.md` Abschnitt 3

## C. Zugriffsmatrix & DCL (MS B 1.2/1.3)

**C-01** · MS B 1.2
> "Übersetze die Zugriffsmatrix aus dem README in eine personalisierte Tabelle (Rollen role_benutzer, role_management) und beschreibe Spaltenrechte für tbl_benutzer.Password und tbl_benutzer.deaktiviert."
→ `docs/MS_B_1_2_Zugriffsmatrix.md`

**C-02** · MS B 1.3
> "Erstelle vollständige MariaDB-DCL-Scripts mit CREATE ROLE, GRANTs (inkl. Spaltenrechte), CREATE USER und SET DEFAULT ROLE für die Datenbank backpacker_lb3_giovanni. Inklusive Revoke-Script."
→ `sql/dcl/01_roles_users.sql`, `sql/dcl/02_revoke_all.sql`

## D. CSV-Import & Cleanup (MS B 1.4)

**D-01** · MS B 1.4
> "Schreibe LOAD DATA INFILE Statements für die 6 CSV-Dateien (utf8mb4, ENCLOSED BY '\"', NULL-Token wird 'NULL' als String). Zuerst in stg_* Staging-Tabellen, danach Cleanup-INSERT in die Zieltabellen mit FK-Lookup, NULL-Normalisierung, Type-Cast."
→ `sql/dml/10_import_csv.sql`, `sql/dml/20_cleanup_and_load.sql`

**D-02** · MS B 1.4
> "Wandle Sentinel `1000-01-01` in der Spalte deaktiviert in NULL um. Wandle Land_FS=0 in tbl_buchung in NULL um."
→ `sql/dml/20_cleanup_and_load.sql` Cases

## E. Tests (MS B 1.5)

**E-01** · MS B 1.5
> "Schreibe 12 Datenqualitäts-Queries (Verwaiste FKs, Sentinel, doppelte Benutzernamen, CHECK-Verletzungen, Charset, Indexliste) mit kurzem Kommentar pro Query."
→ `sql/dql/50_data_consistency.sql`

**E-02** · MS B 1.5
> "Erstelle Positiv/Negativ-Tests pro Rolle (role_benutzer, role_management). Jeder Test soll mit dem erwarteten Result (OK, ER 1142, ER 1143) annotiert sein und in einer einzelnen mysql-Session lauffähig sein (Negative Cases auskommentiert)."
→ `sql/dql/60_tests_roles.sql`

**E-03** · MS B 1.5
> "Generiere eine personalisierte End-to-End-Test-Buchung (Person, Buchung, Position, Benutzer) für Migrationstest."
→ `sql/dml/40_testdaten_migration.sql`

## F. Cloud-Setup (MS C)

**F-01** · MS C
> "Erstelle eine Schritt-für-Schritt Anleitung für Aiven for MySQL Free Tier inkl. Härtung (TLS Pflicht, kein Public Access, Encryption, Backups, Audit-Plugin). Personalisiert mit Identifier `backpacker-aiven-giovanni`."
→ `docs/MS_C_Cloud_Setup.md`

**F-02** · MS C
> "Liefere eine my.cnf-äquivalente Parameter-Group-Konfiguration (require_secure_transport, sql_mode, server_audit_logging, …)."
→ `config/my_aiven.cnf`

**F-03** · MS C
> "DCL-Variante für Cloud mit REQUIRE SSL und Wildcard-Host."
→ `sql/dcl/03_cloud_users.sql`

## G. Migration (MS D)

**G-01** · MS D 3.2
> "Erstelle ein Bash-Script (Linux) und ein PowerShell-Script (Windows/XAMPP), das mysqldump + mysql restore + DCL-Apply + Smoke-Test gegen RDS macht. Mit ENV-Variablen, TLS und CA-Bundle."
→ `sql/migration/migrate_local_to_cloud.sh`, `sql/migration/migrate_local_to_cloud.ps1`

**G-02** · MS D 3.3
> "Cloud-Tests: Zeilenzahl, FK-Anzahl, Charset, TLS-Pflicht, Rollen-Tests, drei Beispiel-Reports."
→ `sql/dql/70_tests_cloud.sql`

## H. Dokumentation / Protokollierung

**H-01** · Kap. 4
> "Erstelle eine README/Protokollierung mit Repo-Struktur, Reproduktions-Snippet (One-Command), Abnahme-Checkliste, Working-Log nach Datum."
→ `docs/Protokollierung.md`, `README_Praxisarbeit.md`

**H-02** · Demo
> "Plane eine 10-15 min Demo mit 3 Cloud-Usern (Benutzer/Manager/DBA) inkl. SQL-Cheat-Sheet für die LP, Negativ-Demos und Time-Budget."
→ `docs/Demo_Skript.md`

**H-03** · Bewertung
> "Fülle die Bewertungsmatrix `M141 LB3 Bewertung LE.xlsx` als Selbsteinschätzung mit Punkte=3 (gut/erfüllt) und Punkte=4 (sehr gut/zusätzlich) sowie Begründung pro Zeile."
→ `M141 LB3 Bewertung LE.xlsx`

## I. Allgemeine Qualitätssicherung

**I-01** · QA
> "Reviewe alle SQL-Scripts auf Idempotenz (DROP IF EXISTS), Personalisierung (DB-Name enthält 'giovanni'), Konsistenz der Spaltenreihenfolge und auf Vermeidung von Hardcoded-Passwörtern."
→ Result: alle Scripts geprüft & überarbeitet.

---

**Hinweis Urheberbeweis**: Datenbankname (`backpacker_lb3_giovanni`), Master-User (`avnadmin`), Rolle-User (`giovanni_benutzer`, `giovanni_manager`, `giovanni_dba`), RDS-Identifier (`backpacker-aiven-giovanni`), Test-Datensatz `Personen.Name='Giovanni-Test'`, Testleistung `'Migrations-Testleistung Giovanni'` und Konfig-Datei `config/my_aiven.cnf` (Kommentar) tragen alle den personalisierten Namen.
