# MS A – Anforderungsdefinition (SMART)

*Autor: Giovanni Merola · Klasse M141 · LB3 Praxisarbeit · Datum: 30.06.2026*
*Personalisierte DB: `backpacker_lb3_giovanni`*

> **Hinweis Cloud-Ziel (Update 06.07.2026):** Die Anforderungen unten nennen als
> Cloud-Ziel noch **Aiven** (Stand der damaligen Evaluation). Aiven wurde evaluiert,
> aber bewusst zugunsten der **eigenen Homelab-Cloud** verworfen — volle Kontrolle,
> kein Vendor-Lock, Max-Bonus. Alle Cloud-Anforderungen (FA-07..10, NFA-01..04)
> werden von der eigenen Cloud **erfüllt oder übertroffen** — live belegt in
> `VERIFICATION.md` (TLS erzwungen, IP-Allowlist mit Default-Deny, Snapshot-Backup).

---

## 1. Ausgangslage

Eine kleine Jugendherberge (Backpacker) verwaltet ihre Übernachtungen und die Benutzerzugänge der Angestellten in einer veralteten **Access-Datenbank**. Der Betreiber möchte die Datenbank auf ein performanteres und sicheres **MySQL/MariaDB-System** umstellen. Die bestehende Struktur liegt als DDL-Skript (`backpacker_ddl_lb3.sql`) und die Daten als CSV-Export (`backpacker_lb3.csv.zip`) vor. Die Daten sind teilweise inkonsistent (fehlerhafte FKs, falsch ausgerichtete Zeilen, NULL-Sentinel-Werte) und müssen bereinigt werden, bevor die Datenbasis in den produktiven Cloud-Betrieb überführt werden kann.

## 2. Zielsetzung (SMART)

| Kriterium | Definition |
|---|---|
| **S**pezifisch | Migration der `backpacker_lb3`-Daten in ein lokales MariaDB-System (XAMPP) mit anschliessender Migration auf ein **Aiven for MySQL**-Cloud-System. Datenbasis konsolidiert (2.NF, FK, Indizes, Constraints). Rollenkonzept gemäss Zugriffsmatrix umgesetzt. |
| **M**essbar | – Alle CSV-Datensätze verarbeitet, nach Bereinigung in den Zieltabellen: `tbl_personen` 2035, `tbl_buchung` 1005, `tbl_positionen` 1745, `tbl_benutzer` 10 (1 Duplikat verworfen), `tbl_land` 81 (von 85 Roh-Zeilen: Duplikate/Leerwerte verworfen), `tbl_leistung` 7 <br>– 0 Datensätze mit verwaisten FKs nach Bereinigung <br>– Min. 1 Benutzer je Rolle (`role_benutzer`, `role_management`) angelegt und getestet <br>– Testprotokolle mit ≥ 12 positiven und ≥ 8 negativen Testfällen <br>– Cloud-Migration in ≤ 5 Min. via Script wiederholbar |
| **A**ttraktiv | Saubere Cloud-Datenbasis mit Rollen, getestet, dokumentiert und re-deploybar; Grundlage für künftige Erweiterungen (z. B. Webfrontend). |
| **R**ealistisch | Aufgabe im Zeitbudget 9–12 Lektionen + 2 Wochen Heimarbeit umsetzbar; alle benötigten Tools (XAMPP/MariaDB, Aiven Free Trial, MySQL-Client, GitLab) sind verfügbar. |
| **T**erminiert | MS A → Tag 8 · MS B → Tag 9 · MS C + MS D + Demo → Tag 10. Endabgabe: 30.06.2026. |

## 3. Funktionale Anforderungen

| ID | Anforderung | MS |
|---|---|---|
| FA-01 | Lokale DB `backpacker_lb3_giovanni` auf MariaDB 10.x (XAMPP) erstellen, Schema in 2.NF | MS B |
| FA-02 | CSV-Import aller 6 Tabellen via `LOAD DATA INFILE` mit NULL-Handling | MS B 1.4 |
| FA-03 | Datenbereinigung (verwaiste FKs entfernen, leere/falsche Werte normalisieren) | MS B 1.4 |
| FA-04 | Rollen `role_benutzer` und `role_management` gemäss Zugriffsmatrix | MS B 1.3 |
| FA-05 | Mindestens 1 Benutzer je Rolle (`giovanni_benutzer`, `giovanni_manager`) anlegen | MS B 1.3 |
| FA-06 | Testprotokolle: Rollen (positiv/negativ), Datenkonsistenz, Schemastruktur | MS B 1.5 |
| FA-07 | Aiven for MySQL Instanz aufsetzen, gehärtet, prod-tauglich (TLS, Public Access aus, IAM, Backups) | MS C |
| FA-08 | Migration: DDL + DML automatisiert via `mysqldump` und Restore-Script | MS D 3.2 |
| FA-09 | DCL automatisiert übertragen (Rollen/Users werden in Cloud neu erzeugt) | MS D 3.1 |
| FA-10 | Cloud-Testprotokolle (Rollen, Daten, Konsistenz, Performance) | MS D 3.3 |
| FA-11 | Demo: 3 User auf Cloud-RDBMS vorführen, Testscripte für LP | Demo |

## 4. Nicht-funktionale Anforderungen

| ID | Anforderung | Messkriterium |
|---|---|---|
| NFA-01 | **Sicherheit**: Cloud-DB nicht öffentlich erreichbar | Aiven IP-Allowlist auf eigene IP/32 beschränkt; kein `0.0.0.0/0` |
| NFA-02 | **Sicherheit**: TLS für alle Cloud-Verbindungen | `require_secure_transport=ON` |
| NFA-03 | **Sicherheit**: Passwörter min. 12 Zeichen, gehashed (SHA-2) | DB-User-Anlage mit `IDENTIFIED BY` + langem Random-Pwd |
| NFA-04 | **Verfügbarkeit**: Tägliches Backup (PITR) | Aiven Backup-Retention: Hobbyist 2 Tage / Startup 7 Tage |
| NFA-05 | **Performance**: Indizes auf allen FKs | `EXPLAIN SELECT` zeigt `key=` Eintrag |
| NFA-06 | **Wiederholbarkeit**: Migration in ≤ 5 Min via 1 Script | Zeitmessung im Testprotokoll |
| NFA-07 | **Datenintegrität**: Alle FKs `ON DELETE RESTRICT` | InnoDB Constraints aktiv |
| NFA-08 | **Charset**: UTF-8 (`utf8mb4`) | `SHOW VARIABLES LIKE 'character_set%'` |
| NFA-09 | **Dokumentation**: Alle KI-Prompts dokumentiert | `prompts/ki_prompts.md` |
| NFA-10 | **Urheber/Personalisierung**: DB-Name, User, Screenshots tragen den Namen "giovanni" | Sichtbar in Screenshots |

## 5. Abgrenzung / Out of Scope

- Migration eines Web-Frontends (nur DB-Schicht).
- Volle Hochverfügbarkeitsarchitektur (Multi-AZ optional).
- Lasttests mit > 10 000 Datensätzen.

## 6. Risiken & Massnahmen

| Risiko | Auswirkung | Massnahme |
|---|---|---|
| Inkonsistente CSV-Daten | Import-Abbruch | Staging-Tabellen, Pre-Cleanup, Datenqualitäts-Skript |
| Public exposure Cloud-DB | Datenleck | Aiven IP-Allowlist nur eigene IP/32, TLS-Pflicht (service-level), CA-Pinning via `aiven-ca.pem` |
| Passwort-Leaks im Repo | Sicherheitsverletzung | `.gitignore`, Beispiel-Werte in Scripts, `__PWD__` Platzhalter |
| Zeitverzug beim Cloud-Setup | Demo gefährdet | Lokales Backup als Fallback |
| Cloud-Kosten | Ungewollte Gebühren | Aiven Free Trial (USD 300 / 30 Tage), Service nach Demo zerstören |

## 7. Links & Ressourcen

- **Repo (personalisiert)**: https://github.com/LieutenantJimmy/M141 — Praxisarbeit im Ordner [`LB3-Praxisarbeit/`](https://github.com/LieutenantJimmy/M141/tree/main/LB3-Praxisarbeit)
- Aiven for MySQL Doku: https://aiven.io/docs/products/mysql
- MariaDB Doku: https://mariadb.com/kb/en/documentation/
- M141 TBZ Skript: https://gitlab.com/ch-tbz-it/Stud/m141

## 8. Abnahmekriterien

Die Arbeit gilt als abgeschlossen, wenn:

1. Alle 6 Tabellen vollständig (mit bereinigten FKs) sowohl lokal als auch in der Cloud vorhanden sind.
2. Die Zugriffsmatrix für beide Rollen positiv UND negativ in Testprotokollen nachgewiesen ist.
3. Die Cloud-Instanz die NFA-01 bis NFA-04 erfüllt (Screenshot-Nachweise).
4. Eine 10–15 minütige Demo auf der Cloud-Instanz erfolgreich vorgeführt wird.
5. Alle SQL-Scripts, KI-Prompts, my.cnf und ein DB-Dump im Repo abgelegt sind.

---

*Sign-off Anforderungsdefinition: Giovanni Merola, 30.06.2026*
