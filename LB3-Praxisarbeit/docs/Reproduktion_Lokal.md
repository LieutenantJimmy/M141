# Reproduktion der lokalen Datenbasis (Nachweis)

*Autor: Giovanni Merola · M141 · LB3 · Reproduktions-Lauf: 2026-07-02*

Dieses Dokument belegt, dass die lokale Datenbasis **vollständig aus den im Repo abgelegten Skripten und CSV-Dateien reproduzierbar** ist. Der Lauf wurde auf einer frisch installierten MariaDB-Instanz (Testserver, keine Altdaten) End-to-End durchgeführt.

## 1. Umgebung

| Aspekt | Wert |
|---|---|
| DBMS | MariaDB 11.8.6 (Debian-Paket, frisch installiert) |
| Datenbank | `backpacker_lb3_giovanni` |
| Treiber-Script | [`sql/repro/run_lb3_local.sh`](../sql/repro/run_lb3_local.sh) |
| Eingespielte Skripte | `sql/ddl/01–03`, `sql/dml/10–40`, `sql/dcl/01`, `sql/dql/50` |
| Quelldaten | `csv/*.csv` (unverändert) |

## 2. Ablauf (One-Shot)

```bash
bash sql/repro/run_lb3_local.sh
```

Das Script installiert MariaDB (falls nötig), setzt `local_infile`, biegt den CSV-Pfad
auf das lokale `csv/`-Verzeichnis um und fährt die komplette Pipeline durch:
DDL → Staging-Import → Bereinigung/Load → Drop-Staging → DCL → Testdatensatz →
Konsistenz-Tests → Rollen-Tests (positiv/negativ) → `mysqldump`-Backup.

## 3. Ergebnis (verifizierte Zeilenzahlen)

| Tabelle | nach Bereinigung | + Testdatensatz (`40_…`) |
|---|--:|--:|
| tbl_personen | 2035 | **2036** |
| tbl_benutzer | 10 *(1 Duplikat verworfen)* | **11** |
| tbl_land | 81 *(von 85 Roh-Zeilen; Duplikate/Leer verworfen)* | **82** |
| tbl_leistung | 7 | **8** |
| tbl_buchung | 1005 | **1006** |
| tbl_positionen | 1745 | **1746** |

Datenkonsistenz (`50_data_consistency.sql`): verwaiste FKs = 0, Sentinel `Land_FS=0`
(438 Roh-Werte) → NULL, Sentinel `deaktiviert='1000-01-01'` → NULL, Rückwärts-Buchungen = 0,
`chk_pos_rabatt`-Verletzungen = 0. **22 Positionen mit negativer `Anzahl`/`Preis`** sind
*bewusst erlaubte* Stornos/Korrekturen (siehe DDL-Kommentar in `02_create_tables.sql`,
Testfall T-D-08b) und stellen keinen Fehler dar.

Rollen-Tests: alle Positiv-Fälle OK, alle Negativ-Fälle liefern die erwarteten
`ERROR 1142` (Tabelle verweigert) bzw. `ERROR 1143` (Spalte `Password`/`deaktiviert`
verweigert). Rohe Ausgaben: `screenshots/local_tests_*.txt`, gerenderte Bilder:
`screenshots/local_tests_*.png`.

## 4. Backup / DB-Dump

Der Lauf erzeugt `backpacker_lb3_giovanni_dump.sql` (+ `.sql.gz`) im Projekt-Root —
Struktur **und** Daten, `--single-transaction`, `utf8mb4`. Dies ist der geforderte
DB-Dump (Backup) für die Abgabe und dient zugleich als Migrationsquelle (MS D).
