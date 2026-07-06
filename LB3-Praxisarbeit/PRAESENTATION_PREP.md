# LB3-Präsentation — Spickzettel (10 Min Lesezeit)

*Backpacker_LB3 · M141 · Demo 07.07.2026 · Vorbereitungs-Guide für die Präsentierenden*

---

## a) Das grosse Bild (2 Sätze)

Wir haben die **Backpacker-Hostel-DB** von Access nach **MariaDB** migriert: zuerst **lokal** (Import → Bereinigung → Rollen → Tests), dann automatisiert in eine **eigene, selbst gehostete Cloud-DB** im Homelab. Die Cloud erzwingt **TLS**, hat eine **IP-Allowlist**, ein **Rollen-basiertes Zugriffsmodell** und ist mit positiven **und** negativen Tests komplett verifiziert.

## b) Architektur (Datenfluss)

```
CSV (Access-Export)
  └─> LOKALE MariaDB  ·  Staging-Import → Bereinigung → 2.NF-Schema (InnoDB, 5 FKs)
        └─> mysqldump (Struktur + Daten)
              └─> per TLS ──> EIGENE CLOUD:  LXC «cloud-db-giovanni» (CT 9003)
                              auf Proxmox-Host «phoebe» · Endpoint 192.168.1.62:3306
```

- **Wer verbindet wie:** nur `mysql`-CLI **mit TLS** (`--ssl-ca=cloud-ca-giovanni.pem`), und nur von **allowlisteten IPs** (Workstation, phoebe-Host, VPN). Klartext → **ERROR 3159**.
- **Warum LXC:** eigener «Server» mit eigener IP, eigener Firewall, eigener Config — funktional wie ein Managed-Cloud-Endpoint.

## c) DCL-Modell (Zugriffskontrolle)

**2 Rollen + 3 User** (alle Cloud-User mit **REQUIRE SSL**): `role_benutzer` (Empfang: Buchungen voll, Gäste ohne DELETE, **Spalte `Password` nie lesbar**, `deaktiviert` nur lesbar) und `role_management` (alles ausser Buchungen/Positionen = **nur SELECT**); dazu `giovanni_dba` (ALL auf die DB). → Erzwingt die **Zugriffsmatrix bis auf Spaltenebene**.

## d) DDL/DML-Migration (automatisiert)

**Ein Skript** (`migrate_local_to_selfhosted.sh`): Cloud-DB anlegen → **Dump einspielen** (Struktur + Daten, `--single-transaction`) → **DCL anwenden** → Smoke-Test. Alles **über TLS**, **idempotent/wiederholbar** (< 1 Min), Ergebnis: Zeilenzahlen **identisch lokal ↔ Cloud** (2036 / 11 / 82 / 8 / 1006 / 1746, inkl. Migrations-Testdatensatz **«Giovanni-Test»**).

## e) Härtung — 8 Punkte (Checkliste)

1. **TLS erzwungen** — `require_secure_transport=ON` + `REQUIRE SSL` je User
2. **Eigene CA** + Server-Zertifikat mit SAN auf die Endpoint-IP
3. **IP-Allowlist** — Proxmox-Firewall, kein `0.0.0.0/0`
4. **Default-Deny** — `policy_in: DROP` am Container
5. **`local-infile=0`** — kein LOAD DATA LOCAL serverseitig
6. **`skip-name-resolve`** — keine DNS-Lookups
7. **Beobachtbarkeit** — slow_query_log + error_log
8. **Least Privilege** — Admin- vs. App-User strikt getrennt (Rollen)

## f) Testresultate (alles grün ✅)

- **Lokal:** 13 Konsistenz-Checks (FKs, Sentinels, Duplikate, Checks) + **23 Rollen-Testfälle** (16 scriptbasiert, 7 Demo-only) positiv/negativ → erwartete **ERROR 1142/1143** treffen exakt ein.
- **Cloud:** Counts identisch, **5 FKs**, utf8mb4, Rollen greifen, **Klartext abgewiesen (3159)**, TLSv1.3-Session nachgewiesen.
- **Besonderheit ehrlich erklärt:** 22 Positionen mit negativer Anzahl/Preis = **bewusst erlaubte Stornos** (dokumentiert, kein Fehler); Rabatt-CHECK-Verstösse = **0**.
- Jeder Nachweis liegt doppelt vor: **Screenshot + rohe Konsolen-Ausgabe** (`screenshots/`).

## g) Wenn der Experte fragt …

- **«Warum eigene Cloud statt AWS/Aiven?»** → Kein TBZ-AWS-Schulungsaccount; Aiven wurde evaluiert (siehe `MS_A_Cloud_Evaluation.md`). Die **eigene Homelab-Cloud ist die Max-Bonus-Option** («eigene Cloud-DB gibt +») und zeigt genau die Kompetenzen, die ein Managed-Dienst versteckt: **TLS-Setup, Zertifikate, Firewall, Härtung — alles selbst gebaut und dokumentiert**. Trade-off (Betrieb/Verfügbarkeit in Eigenverantwortung) ist dokumentiert — inkl. real erlebtem Host-Ausfall und host-agnostischem Re-Deploy.
- **«Woher weiss ich, dass TLS wirklich erzwungen ist?»** → Live zeigen: Login **ohne** TLS → `ERROR 3159 … insecure transport prohibited`; **mit** TLS → OK, `Ssl_version = TLSv1.3`. Zusätzlich `REQUIRE SSL` pro User (doppelte Absicherung).
- **«Warum hat tbl_land 81/82 Zeilen statt 85?»** → Die 85 Roh-Zeilen enthielten **Duplikate/Leerwerte** (z. B. ‹Schweiz› doppelt) — die Bereinigung (INSERT IGNORE + UNIQUE-Key) verwirft sie kontrolliert; dito 1 doppelter Benutzername. Genau das war der Auftrag «Konsistenz prüfen».
- **«Was, wenn die Demo-DB gerade kaputt geht?»** → **Golden Snapshot**: `pct rollback 9003 golden-db-ready` → in < 1 Min zurück im verifizierten Zustand; danach Preflight erneut grün.

## h) Live-Demo (ein Satz)

SSH auf den Homelab-Host → **`/root/preflight_demo.sh`** (21 Checks, muss **GO** zeigen) → dann die **3 User** je per TLS verbinden (`benutzer` / `manager` / `dba`), pro User **1 erlaubte + 1 verbotene** Aktion zeigen (1142/1143) und zum Abschluss den **Klartext-Login scheitern lassen** (3159) — Details: `docs/Demo_Skript.md`.
