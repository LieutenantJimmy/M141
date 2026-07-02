# Demo-Skript (10–15 Min) – Backpacker_LB3 – Giovanni Merola auf Aiven

*Vortragender: Giovanni Merola · M141 · 30.06.2026*

## Setup vor der Demo

| Schritt | Befehl |
|---|---|
| 1 | Browser-Tab "Aiven Console / Service `backpacker-aiven-giovanni-giovannimerola1`" geöffnet |
| 2 | Drei Terminal-Fenster (Tabs):<br>① `giovanni_benutzer` ② `giovanni_manager` ③ `giovanni_dba` |
| 3 | In jedem Terminal: `mysql -h $CLOUD_HOST -u <user> -p --ssl-mode=REQUIRED --ssl-ca=aiven-ca.pem backpacker_lb3_giovanni` |
| 4 | LP-Cheat-Sheet `sql/dql/70_tests_cloud.sql` ausgedruckt / im Editor offen |

## Zeitplan

| Min | Phase | Inhalt |
|:--:|---|---|
| 0:00 | **Intro (1 min)** | Aufgabe kurz vorstellen, Repo-URL zeigen, Personalisierung zeigen |
| 1:00 | **Cloud-Tour (1 min)** | Aiven Console zeigen: Service `backpacker-aiven-giovanni-giovannimerola1` (Running, do-ams), "Allowed inbound IP addresses" (nur eigene IP/32), "Advanced configuration" (sql_mode, slow_query_log, …), Backups (PITR), Encryption at Rest |
| 2:00 | **Login mit 3 Usern (2 min)** | jeweils `SELECT CURRENT_USER(), CURRENT_ROLE();` |
| 4:00 | **Positiv-Tests Empfang (1 min)** | Tab ①: SELECT Person, UPDATE Telefon, INSERT/UPDATE/DELETE Buchung |
| 5:00 | **Negativ-Tests Empfang (2 min)** | Tab ①: `SELECT Password …` → ER 1143 · `DELETE FROM tbl_personen` → ER 1142 · `INSERT INTO tbl_leistung` → ER 1142 |
| 7:00 | **Positiv-Tests Manager (1 min)** | Tab ②: INSERT `tbl_leistung`, UPDATE `Password`, SELECT `tbl_positionen` |
| 8:00 | **Negativ-Tests Manager (1 min)** | Tab ②: `INSERT INTO tbl_buchung` → ER 1142 · `UPDATE tbl_positionen` → ER 1142 |
| 9:00 | **DBA-Tour (1 min)** | Tab ③: `SHOW GRANTS`, `SHOW CREATE TABLE tbl_buchung` (FKs sichtbar), Index-Listen |
| 10:00 | **Datenkonsistenz (1 min)** | Tab ③: `sql/dql/70_tests_cloud.sql` einspielen, Zeilenzahlen, FK-Anzahl, Charset, TLS |
| 11:00 | **TLS-Pflicht (1 min)** | Lokal `mysql … --ssl-mode=DISABLED` → "Insecure transport prohibited" |
| 12:00 | **Migration-Drill (1 min)** | `bash sql/migration/migrate_local_to_cloud.sh` zeigen (Dump + Restore in <60 s) |
| 13:00 | **LP-Testscript (1–2 min)** | LP führt eigene SQL aus → Tab ③ |
| 14:30 | **Fazit (30 sek)** | Was lief gut, was würde ich anders machen → Verweis auf `Fazit.md` |

## SQL-Cheat-Sheet (Demo-Snippets)

```sql
-- Identität
SELECT CURRENT_USER(), CURRENT_ROLE(), @@hostname;
SHOW STATUS LIKE 'Ssl_cipher';   -- MySQL 8.4: @@have_ssl entfernt → stattdessen Ssl_cipher prüfen

-- Empfang positiv
SELECT Personen_ID, Vorname, Name, Telefon FROM tbl_personen LIMIT 5;
UPDATE tbl_personen SET Telefon='+41 79 000 00 00' WHERE Personen_ID=1;

INSERT INTO tbl_buchung (Personen_FS, Ankunft, Abreise, Land_FS)
       VALUES (1, NOW(), NOW()+INTERVAL 1 DAY, 1);
SET @bid := LAST_INSERT_ID();
UPDATE tbl_buchung SET Abreise = NOW()+INTERVAL 3 DAY WHERE Buchungs_ID=@bid;
DELETE FROM tbl_buchung WHERE Buchungs_ID=@bid;

-- Empfang negativ (erwartet Fehler)
SELECT Password FROM tbl_benutzer LIMIT 1;       -- ER 1143
DELETE FROM tbl_personen WHERE Personen_ID=999;  -- ER 1142
INSERT INTO tbl_leistung (Beschreibung) VALUES ('xyz'); -- ER 1142

-- Manager positiv
INSERT INTO tbl_leistung (Beschreibung) VALUES ('Demo-Leistung Giovanni');
DELETE FROM tbl_leistung WHERE Beschreibung='Demo-Leistung Giovanni';
UPDATE tbl_benutzer SET Password = SHA2('NewPwd_Giovanni!2026',256) WHERE Benutzer_ID=1;

-- Manager negativ
INSERT INTO tbl_buchung (Personen_FS, Ankunft, Abreise, Land_FS)
       VALUES (1, NOW(), NOW()+INTERVAL 1 DAY, 1);                -- ER 1142
UPDATE tbl_positionen SET Preis=0 WHERE Positions_ID=1;            -- ER 1142

-- DBA Übersicht
SHOW GRANTS FOR 'giovanni_benutzer'@'%';
SHOW GRANTS FOR 'giovanni_manager'@'%';
SHOW CREATE TABLE tbl_buchung;

-- LP-Testscript
SOURCE sql/dql/70_tests_cloud.sql;
```

## Risiko-Mitigation

| Risiko | Plan B |
|---|---|
| Aiven nicht erreichbar | Lokales XAMPP demo (gleiche Scripts) |
| TLS-Cert lokal fehlt | Aiven Console → Service → "Show CA certificate" → herunterladen und als `aiven-ca.pem` ablegen. (Aiven nutzt eine eigene CA – das AWS-RDS-Bundle würde hier nicht passen.) |
| Demo überzieht | Letzte 2 Punkte (Migration-Drill, LP-Testscript) sind in Aufzeichnung verfügbar |

## Was demonstriert wird, in einer Zeile pro Punkt

- Cloud-DB läuft mit Personalisierung "giovanni", gehärtet, mit TLS-Pflicht.
- 3 Cloud-User mit unterschiedlichen Rollen leben tatsächlich auf der Cloud-Instanz.
- Spalten-Privilegien werden positiv UND negativ vorgeführt.
- Migration ist scriptbasiert, idempotent und reproduzierbar.
