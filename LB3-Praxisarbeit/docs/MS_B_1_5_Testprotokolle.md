# MS B 1.5 – Testprotokolle (Lokal · MariaDB XAMPP)

*Autor: Giovanni Merola · M141 · LB3 · 30.06.2026*

## 1. Methodik

Jeder Testfall ist als **TC-ID**, **Pre-Condition**, **Schritt**, **Erwartet** und **Resultat** dokumentiert. Status-Werte: ✅ bestanden · ❌ fehlgeschlagen · ⚠ teilweise.

Die SQL-Befehle der Tests sind in `sql/dql/60_tests_roles.sql` und `sql/dql/50_data_consistency.sql`.

> **Reproduzierbarkeit.** Alle unten protokollierten Resultate wurden auf einer frisch aufgesetzten **MariaDB**-Instanz End-to-End nachgefahren (Pipeline `01`→`50`). Die rohen Konsolen-Ausgaben liegen unverändert im Repo unter `screenshots/local_*.txt` bzw. als personalisierte Screenshots unter `screenshots/local_*.png`.

---

## 2. Testfälle Rollen / Zugriffsmatrix

### 2.1 Rolle `role_benutzer` (User: `giovanni_benutzer`)

| TC | Aktion | Erwartet | Resultat |
|---|---|---|---|
| A-01 | `SELECT * FROM tbl_personen` | OK, Liste Gäste | ✅ 2035 Zeilen |
| A-02 | `UPDATE tbl_personen SET Telefon='+41000' WHERE Personen_ID=1` | OK, 1 row affected | ✅ |
| A-03 | `DELETE FROM tbl_personen WHERE Personen_ID=1` | ER 1142 (Access denied) | ✅ Error 1142 |
| A-04 | `SELECT Password FROM tbl_benutzer` | ER 1143 (column denied) | ✅ Error 1143 |
| A-05 | `SELECT Benutzer_ID, Benutzername, deaktiviert FROM tbl_benutzer` | OK | ✅ |
| A-06 | `UPDATE tbl_benutzer SET deaktiviert=CURDATE()` | ER 1143 (column denied) | ✅ Error 1143 |
| A-07a | `INSERT INTO tbl_buchung …` | OK | ✅ |
| A-07b | `UPDATE tbl_buchung … WHERE …` | OK | ✅ |
| A-07c | `DELETE FROM tbl_buchung WHERE Buchungs_ID=@bid` | OK | ✅ |
| A-08 | `INSERT INTO tbl_leistung …` | ER 1142 | ✅ Error 1142 |
| A-09 | `INSERT INTO tbl_positionen …` | OK | ✅ |
| A-10 | `DELETE FROM tbl_positionen WHERE Positions_ID=…` | OK | ✅ |

### 2.2 Rolle `role_management` (User: `giovanni_manager`)

| TC | Aktion | Erwartet | Resultat |
|---|---|---|---|
| B-01 | `SELECT * FROM tbl_personen` | OK | ✅ |
| B-02a | `INSERT INTO tbl_leistung …` | OK | ✅ |
| B-02b | `DELETE FROM tbl_leistung …` | OK | ✅ |
| B-03 | `UPDATE tbl_benutzer SET Password=SHA2(…)` | OK | ✅ |
| B-04 | `INSERT INTO tbl_buchung …` | ER 1142 | ✅ Error 1142 |
| B-05 | `UPDATE tbl_positionen SET Preis=0` | ER 1142 | ✅ Error 1142 |
| B-06 | `DELETE FROM tbl_buchung` | ER 1142 | ✅ Error 1142 |
| B-07 | `INSERT INTO tbl_land (Land) VALUES ('Atlantis')` | OK | ✅ |
| B-08 | `DELETE FROM tbl_land WHERE Land='Atlantis'` | OK | ✅ |

### 2.3 User `giovanni_dba` (Admin)

| TC | Aktion | Erwartet | Resultat |
|---|---|---|---|
| C-01 | `SHOW GRANTS` | enthält `ALL PRIVILEGES … WITH GRANT OPTION` | ✅ |
| C-02 | `DROP TABLE tbl_test` *(erst angelegt)* | OK | ✅ |

> Hinweis: Negative Cases sind in `60_tests_roles.sql` standardmässig **auskommentiert**, damit das Script in einer Session durchläuft. Beim Vorführen werden sie einzeln entkommentiert und einzeln ausgeführt (→ siehe Demo-Script).

---

## 3. Testfälle Datenkonsistenz (Lokal)

Alle Abfragen aus `sql/dql/50_data_consistency.sql`.

| TC | Prüfung | Erwartet | Beobachtet |
|---|---|---|---|
| T-D-01 | Zeilenzahlen nach Bereinigung (vor Testdaten) | personen=2035, benutzer=10, land=81, leistung=7, buchung=1005, positionen=1745 | ✅ exakt (siehe `screenshots/local_tests_data.txt`) |
| T-D-02 | Verwaiste Buchungen ohne Person | 0 | ✅ 0 |
| T-D-03 | `Land_FS=0` (Sentinel) | 0 (durch Cleanup → NULL gesetzt) | ✅ 0 (438 Sentinel-Werte vor Cleanup eliminiert) |
| T-D-04 | Positionen ohne Buchung | 0 | ✅ 0 |
| T-D-05 | Positionen ohne `Leistung_FS` (Freitext-only) | > 0 erlaubt | ⚠ 1233 Positionen mit Freitext / NULL Leistung_FS (Leistung_Text vorhanden) |
| T-D-06 | `deaktiviert='1000-01-01'` Sentinel | 0 | ✅ 0 (→NULL) |
| T-D-07 | Buchungen mit Abreise < Ankunft | 0 | ✅ 0 |
| T-D-08a | Erzwungener CHECK `chk_pos_rabatt` (Rabatt 0–100) verletzt | 0 | ✅ 0 |
| T-D-08b | Negative `Anzahl`/`Preis` (bewusst erlaubt = Stornos/Korrekturen, siehe DDL-Kommentar) | informativ, > 0 möglich | ℹ 22 Zeilen (21× Anzahl<0, 1× Preis<0) — legitime Stornos, kein Fehler |
| T-D-09 | Doppelte Benutzernamen | 0 | ✅ 0 |
| T-D-10 | Indexliste enthält FK-Spalten | mind. 6 Indizes auf FKs | ✅ alle vorhanden |
| T-D-11 | FK-Constraints aktiv | 5 Stück | ✅ 5 |
| T-D-12 | Tabellen-Collation | `utf8mb4_unicode_ci` für alle 6 | ✅ |

---

## 4. Testdaten-Generator

Das Script `sql/dml/40_testdaten_migration.sql` erzeugt eine **personalisierte End-to-End-Buchung** ("Giovanni-Test") mit allen FK-Referenzen, die zur Verifikation einer Migration verwendet wird (siehe MS D 3.3).

Der Testdatensatz fügt in jede Tabelle genau **einen** Datensatz ein. Die Zeilenzahlen steigen dadurch von der bereinigten Basis auf den Migrations-Stand:

| Tabelle | nach Bereinigung | + Testdatensatz | Migrations-Stand |
|---|--:|--:|--:|
| tbl_personen | 2035 | +1 | **2036** |
| tbl_benutzer | 10 | +1 | **11** |
| tbl_land | 81 | +1 | **82** |
| tbl_leistung | 7 | +1 | **8** |
| tbl_buchung | 1005 | +1 | **1006** |
| tbl_positionen | 1745 | +1 | **1746** |

---

## 5. Fazit MS B

- Schema in 2.NF mit InnoDB, FKs, Indizes und CHECK-Constraints.
- CSV-Import mit Staging und Datenbereinigung erfolgreich.
- Zugriffsmatrix vollständig umgesetzt (Rollen + Spaltenrechte für `Password` / `deaktiviert`).
- Alle 13 Konsistenz-Prüfungen (T-D-01 … T-D-12, T-D-08 in a/b geteilt) und 19 Rollen-Testfälle bestanden bzw. nachvollziehbar dokumentiert.

→ Lokale Datenbasis ist **migrationsbereit** für Cloud (MS C/D).

---

*Sign-off Testprotokolle Lokal: Giovanni Merola, 30.06.2026*
