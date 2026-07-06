# Demo-Skript (10–15 Min) – Backpacker_LB3 auf der eigenen Cloud

*M141 · LB3 · Live-System: eigene Homelab-Cloud `cloud-db-giovanni` (CT 9003, `192.168.1.62:3306`, TLS erzwungen)*

> **Hinweis:** Frühere Versionen dieses Skripts zielten auf **Aiven** — Aiven wurde
> evaluiert, aber bewusst zugunsten der **eigenen Homelab-Cloud** verworfen
> (volle Kontrolle, kein Vendor-Lock, Max-Bonus «eigene Cloud-DB»).
> Die produktive Demo läuft ausschliesslich gegen die eigene Cloud.

## Setup vor der Demo (~2 Min)

| Schritt | Befehl / Aktion |
|---|---|
| 1 | SSH auf den Proxmox-Host → **`/root/preflight_demo.sh`** → muss **GO** zeigen (21 Checks, Auto-Heal) |
| 2 | Drei Terminal-Fenster (Tabs): ① `giovanni_benutzer` ② `giovanni_manager` ③ `giovanni_dba` |
| 3 | In jedem Terminal: `mysql -h 192.168.1.62 -u <user> -p --ssl-verify-server-cert --ssl-ca=/root/cloud-ca-giovanni.pem backpacker_lb3_giovanni` |
| 4 | LP-Cheat-Sheet `sql/dql/70_tests_cloud.sql` im Editor offen |

## Zeitplan

| Min | Phase | Inhalt |
|:--:|---|---|
| 0:00 | **Intro (1 min)** | Aufgabe kurz vorstellen, Repo zeigen, Personalisierung zeigen |
| 1:00 | **Cloud-Tour (1 min)** | Eigene Cloud zeigen: `pct status 9003` + `pct config 9003` (LXC, unprivilegiert), Firewall-Allowlist `9003.fw` (kein 0.0.0.0/0), gehärtete `my.cnf` (`require_secure_transport=ON`, eigene CA) |
| 2:00 | **Login mit 3 Usern (2 min)** | jeweils `SELECT CURRENT_USER(), CURRENT_ROLE();` — alle per TLS |
| 4:00 | **Positiv-Tests Empfang (1 min)** | Tab ①: SELECT Person, UPDATE Telefon, INSERT/UPDATE/DELETE Buchung |
| 5:00 | **Negativ-Tests Empfang (2 min)** | Tab ①: `SELECT Password …` → ER 1143 · `DELETE FROM tbl_personen` → ER 1142 · `INSERT INTO tbl_leistung` → ER 1142 |
| 7:00 | **Positiv-Tests Manager (1 min)** | Tab ②: INSERT `tbl_leistung`, UPDATE `Password`, SELECT `tbl_positionen` |
| 8:00 | **Negativ-Tests Manager (1 min)** | Tab ②: `INSERT INTO tbl_buchung` → ER 1142 · `UPDATE tbl_positionen` → ER 1142 |
| 9:00 | **DBA-Tour (1 min)** | Tab ③: `SHOW GRANTS`, `SHOW CREATE TABLE tbl_buchung` (FKs sichtbar), Index-Listen |
| 10:00 | **Datenkonsistenz (1 min)** | Tab ③: `sql/dql/70_tests_cloud.sql` einspielen — Zeilenzahlen, FK-Anzahl, Charset, TLS |
| 11:00 | **TLS-Pflicht (1 min)** | `mysql … --skip-ssl` → **ERROR 3159** «insecure transport prohibited» |
| 12:00 | **Migration-Drill (1 min)** | `sql/migration/migrate_local_to_selfhosted.sh` zeigen (Dump + Restore + DCL per TLS, idempotent, < 60 s — 2-fach verifiziert in `VERIFICATION.md`) |
| 13:00 | **LP-Testscript (1–2 min)** | LP führt eigene SQL aus → Tab ③ |
| 14:30 | **Fazit (30 sek)** | Was lief gut, was würde ich anders machen → Verweis auf `Fazit.md` |

## SQL-Cheat-Sheet (Demo-Snippets)

```sql
-- Identität + TLS
SELECT CURRENT_USER(), CURRENT_ROLE(), @@hostname;
SHOW STATUS LIKE 'Ssl_version';   -- erwartet TLSv1.3

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

-- TLS-Pflicht-Beweis (aus einem NEUEN Terminal, ohne TLS)
--   mysql -h 192.168.1.62 -u giovanni_dba -p --skip-ssl -e "SELECT 1;"
--   → ERROR 3159: Connections using insecure transport are prohibited

-- LP-Testscript
SOURCE sql/dql/70_tests_cloud.sql;
```

## Risiko-Mitigation

| Risiko | Plan B |
|---|---|
| Demo-DB inkonsistent (kaputte Probe) | **Golden Snapshot**: `pct rollback 9003 golden-db-ready && pct start 9003` → Preflight erneut → GO (< 1 Min) |
| Dienst/CT down kurz vor der Demo | Preflight heilt automatisch (CT-Start, MariaDB-Start, CA neu ziehen) |
| Kein Zugriff aufs Homelab von der Schule | VPN (IKEv2) — die Firewall-Allowlist erlaubt den VPN-Pfad; Fallback: lokale MariaDB-Demo (gleiche Scripts) |
| Demo überzieht | Letzte 2 Punkte (Migration-Drill, LP-Testscript) sind als Nachweise dokumentiert (`VERIFICATION.md`, `screenshots/cloud_*`) |

## Was demonstriert wird, in einer Zeile pro Punkt

- Die **eigene Cloud-DB** läuft personalisiert, gehärtet und mit TLS-Pflicht — selbst gebaut statt gemietet.
- 3 Cloud-User mit unterschiedlichen Rollen leben tatsächlich auf der Cloud-Instanz.
- Spalten-Privilegien werden positiv UND negativ vorgeführt.
- Migration ist scriptbasiert, idempotent und reproduzierbar (zweifach verifiziert).
