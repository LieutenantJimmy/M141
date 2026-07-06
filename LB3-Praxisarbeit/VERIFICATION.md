# VERIFICATION — Rigor-Audit mit Live-Beweisen

*M141 LB3 · Backpacker_LB3 · Giovanni Merola & Agustin · Audit-Lauf: 07.07.2026*

Jede Behauptung unten wurde **live gegen die produktive Cloud-DB** ausgeführt
(`cloud-db-giovanni`, CT 9003, `192.168.1.62:3306`, alle Verbindungen per TLS mit
CA-Verifikation). Die Ausgaben sind **unverändert eingefügt** (nur
Passwort-Warnzeilen entfernt). Sicherheitsnetz: Proxmox-Snapshot
`golden-db-ready`; alle Schreib-Proben sind net-zero.

> **Deklarierte Abweichung:** Die Migrations-**Quelle** auf dem Audit-Host ist der
> kanonische, im Repo eingecheckte Dump `backpacker_lb3_giovanni_dump.sql`
> (die lokale MariaDB lief auf dem ausgefallenen Host freya). Die Quell-Zeilenzahlen
> wurden verifiziert, indem der Dump in eine Scratch-DB restauriert, gezählt und
> die Scratch-DB wieder entfernt wurde (net-zero).

---

## 1) Migration ist idempotent (2 komplette Läufe, 0 Fehler)

**Quell-Zeilenzahlen** (Dump → Scratch-DB `verify_local_source` → zählen → DROP):

```text
| verify_local_source.tbl_personen   | 2036 |
| verify_local_source.tbl_benutzer   |   11 |
| verify_local_source.tbl_land       |   82 |
| verify_local_source.tbl_leistung   |    8 |
| verify_local_source.tbl_buchung    | 1006 |
| verify_local_source.tbl_positionen | 1746 |
(Scratch-DB wieder entfernt - net-zero)
```

**Migrations-Lauf A** (CREATE IF NOT EXISTS → Dump-Restore → DCL-Apply, alles per TLS):

```text
Restore A: OK
DCL A: OK
Fehler-Ausgabe Lauf A: []
| tbl_personen   | 2036 |   | tbl_leistung   |    8 |
| tbl_benutzer   |   11 |   | tbl_buchung    | 1006 |
| tbl_land       |   82 |   | tbl_positionen | 1746 |
```

**Migrations-Lauf B (identische Wiederholung):**

```text
Restore B: OK
DCL B: OK
Fehler-Ausgabe Lauf B: []
| tbl_personen   | 2036 |   | tbl_leistung   |    8 |
| tbl_benutzer   |   11 |   | tbl_buchung    | 1006 |
| tbl_land       |   82 |   | tbl_positionen | 1746 |
```

✅ **Quelle = Lauf A = Lauf B** (2036/11/82/8/1006/1746), **beide Läufe fehlerfrei**
(leere stderr). Die Migration konvergiert bei Wiederholung auf denselben Zustand
→ idempotent und gefahrlos wiederholbar.

## 2) Test-Suiten vollständig & grün

**2a) Daten-Konsistenz (`50_data_consistency.sql`) gegen die Cloud-DB** — alle
Muss-0-Prüfungen liefern 0 (verwaiste FKs, Sentinels, Rückwärtsbuchungen,
Duplikate); Indizes, 5 FKs und utf8mb4 überall bestätigt. Kernstück T-D-08:

```text
| rabatt_check_verletzt |
|                     0 |
| stornos_anzahl_negativ | stornos_preis_negativ | stornos_zeilen_total |
|                     21 |                     1 |                   22 |
```

➜ **Erklärung der 22 Zeilen:** Der einzige *erzwungene* CHECK (`chk_pos_rabatt`,
Rabatt 0–100) hat **0 Verletzungen**. Die 22 Positionen mit negativer
`Anzahl`/`Preis` sind **bewusst erlaubte Stornos/Korrekturen** des Quellsystems
(im DDL kommentiert, Testfall T-D-08b) — Geschäftslogik, kein Datenfehler.

**2b) Cloud-Tests (`70_tests_cloud.sql`):** C-D-01 Counts wie oben ✅ ·
C-D-02 `fk_anzahl = 5` ✅ · C-D-03 `utf8mb4` ✅ · C-D-04 `have_ssl=YES`,
`require_secure_transport=ON` ✅ · C-D-05/06 Rollen + Grants vorhanden ✅ ·
C-D-07 `Giovanni-Test` = 1 ✅ · Reports R-01…R-03 liefern plausible Resultate ✅.

**2c) Rollen-Tests (positiv/negativ, net-zero)** — 8/8 wie erwartet:

```text
[P1 benutzer SELECT personen]            n = 2036                      OK
[P2 benutzer INSERT+DELETE buchung]      ok                            OK
[N1 benutzer DELETE personen]   ERROR 1142 ... DELETE command denied   OK
[N2 benutzer SELECT Password]   ERROR 1143 ... for column 'Password'   OK
[N3 benutzer UPDATE deaktiviert] ERROR 1143 ... column 'deaktiviert'   OK
[P3 manager INSERT+DELETE leistung]      ok                            OK
[N4 manager INSERT buchung]     ERROR 1142 ... INSERT command denied   OK
[N5 manager UPDATE positionen]  ERROR 1142 ... UPDATE command denied   OK
```

## 3) Die 8 Härtungspunkte — je eine Live-Probe

**H1 — TLS erzwungen.** Klartext-Verbindung wird abgewiesen:

```text
$ mysql --skip-ssl ...
ERROR 3159 (08004): Connections using insecure transport are prohibited
while --require_secure_transport=ON.
require_secure_transport = ON
```

**H2 — Eigene CA + SAN-Zertifikat.** Kette gültig, SAN korrekt, Session TLS 1.3
mit aktiver CA-Verifikation (`--ssl-verify-server-cert`):

```text
/etc/mysql/certs/server-cert.pem: OK        (openssl verify -CAfile ca.pem)
X509v3 Subject Alternative Name: IP Address:192.168.1.62, DNS:cloud-db-giovanni
Ssl_version  TLSv1.3
```

**H3 — IP-Allowlist** und **H4 — Default-Deny.** Kompilierte Firewall-Chain des
Containers (`iptables-save`, Chain `veth9003i0-IN`): exakt die vier erlaubten
Quellen auf `:3306`, danach **DROP** — kein `0.0.0.0/0`:

```text
-A veth9003i0-IN -s 192.168.1.40/32 -p tcp -m tcp --dport 3306 -j ACCEPT
-A veth9003i0-IN -s 192.168.1.30/32 -p tcp -m tcp --dport 3306 -j ACCEPT
-A veth9003i0-IN -s 192.168.1.2/32  -p tcp -m tcp --dport 3306 -j ACCEPT
-A veth9003i0-IN -s 10.10.0.0/24    -p tcp -m tcp --dport 3306 -j ACCEPT
-A veth9003i0-IN -s 192.168.1.0/24  -p icmp -j ACCEPT
-A veth9003i0-IN -j PVEFW-Drop
-A veth9003i0-IN -j DROP
```

**H5 — `local-infile` aus:** `local_infile = OFF` ✅
**H6 — keine DNS-Lookups:** `skip_name_resolve = ON` ✅
**H7 — Beobachtbarkeit:** `slow_query_log = ON | long_query_time = 2` ·
`log_error = /var/log/mysql/error.log` · beide Logdateien existieren und wachsen ✅
**H8 — Least Privilege.** App-Rolle versucht Verbotenes:

```text
$ giovanni_benutzer: DROP TABLE tbl_land;
ERROR 1142 (42000): DROP command denied to user 'giovanni_benutzer'@'...'
for table `backpacker_lb3_giovanni`.`tbl_land`
```

## 4) DCL-Grants korrekt (SHOW GRANTS, live)

```text
===== 'giovanni_benutzer'@'%' =====
GRANT `role_benutzer` TO `giovanni_benutzer`@`%`
GRANT USAGE ON *.* TO `giovanni_benutzer`@`%` ... REQUIRE SSL
SET DEFAULT ROLE `role_benutzer` FOR `giovanni_benutzer`@`%`

===== 'giovanni_manager'@'%' =====
GRANT `role_management` TO `giovanni_manager`@`%`
GRANT USAGE ON *.* TO `giovanni_manager`@`%` ... REQUIRE SSL
SET DEFAULT ROLE `role_management` FOR `giovanni_manager`@`%`

===== 'giovanni_dba'@'%' =====
GRANT USAGE ON *.* TO `giovanni_dba`@`%` ... REQUIRE SSL
GRANT ALL PRIVILEGES ON `backpacker_lb3_giovanni`.* ... WITH GRANT OPTION
```

Alle drei User: **REQUIRE SSL** gesetzt, Rollen korrekt zugewiesen und als
Default-Rolle aktiv (Rollen-Grants im Detail: `sql/dcl/04_selfhosted_cloud_users.sql`,
Nachweis `screenshots/cloud_demo_3_users.txt`).

**Spalte `Password`:** Für `role_benutzer` **nie lesbar** — Live-Beweis:

```text
[role_benutzer -> SELECT Password]
ERROR 1143 (42000): SELECT command denied ... for column 'Password' in table 'tbl_benutzer'
```

*(Präzisierung gemäss Zugriffsmatrix: `role_management` hat auf `tbl_benutzer`
volles S/I/U/D — das Management darf Passwort-**Hashes** lesen/setzen; das ist
die dokumentierte, gewollte Ausnahme. Für die Empfangs-Rolle ist die Spalte
vollständig gesperrt.)*

---

## Fazit

| Prüfblock | Ergebnis |
|---|---|
| 1 · Migration idempotent (2 Läufe, 0 Fehler, identische Counts) | ✅ |
| 2 · Test-Suiten (Konsistenz, Cloud, Rollen pos/neg) | ✅ alle grün |
| 3 · 8/8 Härtungspunkte live belegt | ✅ |
| 4 · DCL-Grants + Password-Spaltenschutz | ✅ |
| Abschliessender Preflight (21 Checks) | ✅ **GO** |

# ✅ GO — Deliverable verifiziert, Demo-Umgebung produktionsbereit.

*Reproduktion dieses Audits: `sql/repro/preflight_demo.sh` (Schnellcheck) bzw. die
Kommandos oben; Wiederherstellung im Fehlerfall: `pct rollback 9003 golden-db-ready`.*
