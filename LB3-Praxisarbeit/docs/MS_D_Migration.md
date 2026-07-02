# MS D – Automatisierte Migration (Lokal → Cloud) + Testprotokolle

*Autor: Giovanni Merola · M141 · LB3 · 30.06.2026*

## 3.1 Berechtigungen automatisiert übertragen

Die Rollen-/User-Definitionen werden **nicht** mit `mysqldump` übertragen (lokale `mysql.*`-Tabellen sind in der Cloud nicht änderbar), sondern als **separates DCL-Script** im Cloud-System angewandt:

`sql/dcl/03_cloud_users.sql`

Das Migrationsskript ruft dieses Script direkt nach dem Restore auf:

```bash
mysql -h $CLOUD_HOST -u $CLOUD_USER -p$CLOUD_PWD \
      --ssl-mode=REQUIRED --ssl-ca=aiven-ca.pem \
      backpacker_lb3_giovanni < ../dcl/03_cloud_users.sql
```

→ Damit sind die Cloud-User `giovanni_benutzer@%`, `giovanni_manager@%` und `giovanni_dba@%` **mit identischen Berechtigungen** und zusätzlich `REQUIRE SSL` angelegt.

### Test (3.1)

| TC | Aktion | Erwartet | Resultat |
|---|---|---|---|
| C-R-01 | `SHOW GRANTS FOR 'giovanni_benutzer'@'%'` | Liste enthält `role_benutzer` und Spalten-Grants | ✅ |
| C-R-02 | `SHOW GRANTS FOR 'giovanni_manager'@'%'` | enthält `role_management` | ✅ |
| C-R-03 | Login mit `giovanni_benutzer` **ohne** TLS | Fehler "Access denied. … Connections using insecure transport are prohibited" | ✅ |
| C-R-04 | Login mit `giovanni_benutzer` **mit** TLS | OK | ✅ |
| C-R-05 | Negativ-Test DELETE `tbl_personen` als `giovanni_benutzer` | ER 1142 | ✅ |
| C-R-06 | Negativ-Test SELECT `Password` als `giovanni_benutzer` | ER 1143 | ✅ |
| C-R-07 | Positiv-Test INSERT `tbl_leistung` als `giovanni_manager` | OK | ✅ |
| C-R-08 | Positiv-Test SELECT `tbl_positionen` als `giovanni_manager` | OK | ✅ |

---

## 3.2 Struktur und Daten automatisiert übertragen

### Mechanismus

1. **Dump** der lokalen DB mit `mysqldump --single-transaction --routines --triggers --events --databases backpacker_lb3_giovanni`.
2. **Restore** in Aiven via `mysql … < dump.sql` über TLS.
3. **DCL-Apply** wie in 3.1.
4. **Smoke-Test** mit `70_tests_cloud.sql`.

Wrapper-Scripts:
- `sql/migration/migrate_local_to_cloud.sh` (Linux/macOS Bash)
- `sql/migration/migrate_local_to_cloud.ps1` (Windows PowerShell, XAMPP)

Zeitmessung (gemessen, Aiven Hobbyist Plan · 10 GB · do-ams):

| Phase | Dauer |
|---|---|
| mysqldump | ~ 6 s |
| Restore | ~ 38 s |
| DCL Apply | ~ 1 s |
| Smoke-Test | ~ 2 s |
| **Total** | **~ 47 s** (< 5 Min NFA-06 ✅) |

### Test (3.2)

| TC | Aktion | Erwartet | Resultat |
|---|---|---|---|
| C-S-01 | Zeilen in Cloud == Zeilen lokal | identische Counts pro Tabelle | ✅ |
| C-S-02 | FK-Anzahl in Cloud | 5 (siehe DDL) | ✅ |
| C-S-03 | Charset DB | utf8mb4 | ✅ |
| C-S-04 | `tbl_personen` mit Name='Giovanni-Test' | ≥ 1 (Testdatensatz aus `40_testdaten_migration.sql`) | ✅ |
| C-S-05 | `EXPLAIN SELECT * FROM tbl_buchung WHERE Personen_FS=42` zeigt Index `idx_buchung_personen` | Index used | ✅ |
| C-S-06 | `tbl_positionen` checks aktiv | Verstoss INSERT → Fehler | ✅ |

---

## 3.3 Testen der Daten (Lokal & Cloud)

### A) Datenkonsistenz – siehe `sql/dql/50_data_consistency.sql` (lokal) und `sql/dql/70_tests_cloud.sql` (cloud)

Hinweis: Das Skript `sql/dml/40_testdaten_migration.sql` fügt vor dem Dump **einen** zusätzlichen Migrations-Testdatensatz ein
("Giovanni-Test"). Dieser ist sowohl lokal als auch in der Cloud enthalten — die Counts sind also identisch.

| TC | Prüfung | Lokal | Cloud |
|---|---|---|---|
| D-01 | Zeilenzahl tbl_personen | 2036 (inkl. Test-Datensatz) ✅ | 2036 ✅ |
| D-02 | Zeilenzahl tbl_buchung | 1006 ✅ | 1006 ✅ |
| D-03 | Zeilenzahl tbl_positionen | 1746 ✅ | 1746 ✅ |
| D-04 | Sentinel `Land_FS=0` | 0 ✅ | 0 ✅ |
| D-05 | Sentinel `deaktiviert='1000-01-01'` | 0 ✅ | 0 ✅ |
| D-06 | FK Anzahl | 5 ✅ | 5 ✅ |
| D-07 | Index Anzahl auf FKs | ≥ 6 ✅ | ≥ 6 ✅ |
| D-08 | CHECK-Verletzungen | 0 ✅ | 0 ✅ |

### B) Rollen-Tests – siehe `sql/dql/60_tests_roles.sql` (lokal) und identische Statements gegen Cloud-Endpoint

| TC | Lokal | Cloud |
|---|---|---|
| A-01 SELECT als Benutzer | ✅ | ✅ |
| A-04 SELECT Password als Benutzer | ✅ blockiert | ✅ blockiert |
| B-04 INSERT tbl_buchung als Manager | ✅ blockiert | ✅ blockiert |
| C-R-03 Login ohne TLS | – | ✅ blockiert (REQUIRE SSL) |

### C) Performance-Stichprobe (Cloud)

| Query | Lokal | Cloud |
|---|---|---|
| `SELECT * FROM tbl_buchung WHERE Personen_FS=42` | 4 ms | 8 ms |
| `SELECT SUM(p.Anzahl*p.Preis) … GROUP BY u.Benutzername` | 41 ms | 67 ms |

### D) Fazit MS D

- Migration in **< 1 Minute** reproduzierbar.
- Datenkonsistenz und Rollen-Verhalten **identisch** zwischen Lokal & Cloud.
- TLS-Pflicht zusätzlich in der Cloud durchgesetzt.

---

*Sign-off Migration & Cloud-Test: Giovanni Merola, 30.06.2026*
