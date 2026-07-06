# MS A – Evaluation Cloud-RDBMS

*Autor: Giovanni Merola · M141 · LB3 · 30.06.2026*

## 1. Anforderungen an die Cloud-DB

| # | Anforderung | Gewicht |
|---|---|:--:|
| 1 | MariaDB- oder MySQL-kompatibel (Schema 1:1 portierbar) | 5 |
| 2 | Sichere Konfiguration ab Werk (TLS, IP-Allowlist, Authentifizierung) | 5 |
| 3 | Automatische Backups + Point-in-Time-Recovery | 4 |
| 4 | Free Trial / günstige Kostenstruktur (Schulprojekt) | 4 |
| 5 | Einfaches Setup / gute Doku | 3 |
| 6 | Monitoring & Logging | 3 |
| 7 | Verfügbar in EU-Region (DSGVO) | 4 |
| 8 | Skalierbarkeit (vertikal/horizontal) | 2 |
| 9 | **Zugang ohne Firmen-/Kreditkarten-Hürden für ein Schulprojekt** | 5 |

> *Kriterium 9 wurde nach der ersten Eval ergänzt, weil sich herausstellte, dass für die Klasse kein AWS-Schulungs-Abo bereitgestellt wurde und ein privater AWS-Account die geforderten VPC-Berechtigungen nicht freischaltet. Damit gewinnt ein DBaaS-Anbieter mit unkompliziertem Trial-Zugang massiv an Gewicht.*

## 2. Kandidaten

### 2.1 AWS RDS for MariaDB
- **Pro**: Vollständige MariaDB-Engine 10.6/10.11, Free-Tier (db.t3.micro 750 h/Monat im 1. Jahr, 20 GB), automatische Backups inkl. PITR (7 Tage default), KMS-Verschlüsselung, eu-central-1 (Frankfurt), CloudWatch-Integration.
- **Contra**: **Für diese Klasse blockiert** – kein TBZ-AWS-Schulungs-Abo verfügbar; privater AWS-Account erfordert Kreditkarten-Verifikation + komplette VPC/IAM-Einrichtung, die im Zeitbudget der Praxisarbeit nicht leistbar ist. AWS-Konsole zudem überladen für einen Erst-Einsatz.
- **Kosten**: 0 € im Free Tier — aber Onboarding-Kosten in Zeit hoch.

### 2.2 Azure Database for MariaDB
- **Pro**: Managed-Dienst, eingebaute Geo-Redundanz, einfaches Portal.
- **Contra**: Microsoft hat **Retirement angekündigt** (EOL Sep 2025 → Migration nötig). Damit für ein neues Schulprojekt 2026 ungeeignet.
- **Kosten**: kein langfristiges Free Tier mehr; ~25 €/Monat Burstable.

### 2.3 Google Cloud SQL for MySQL
- **Pro**: Einfaches Setup, Private IP, automatische Backups, EU-Regionen.
- **Contra**: Nur MySQL (kein nativer MariaDB-Mode), $300 Free-Credit ist zeitlich begrenzt (90 Tage), für Schul-Account ebenfalls KK + Firmen-Verifikation nötig.
- **Kosten**: ~10 €/Monat db-f1-micro außerhalb Free Trial.

### 2.4 Eigene MariaDB auf Cloud-VM (z. B. Hetzner CX11)
- **Pro**: Volle Kontrolle, günstig (~5 €/Monat Hetzner), exakt gleiche Engine wie lokal.
- **Contra**: Self-Managed → Backups, Patching, Härtung in Eigenverantwortung, höherer Aufwand. Nicht "managed" wie von der Aufgabe erwartet.

### 2.5 Aiven for MySQL  ⭐ neu evaluiert
- **Pro**:
  - **Managed DBaaS** mit MySQL 8 (MariaDB-kompatibel auf SQL-Ebene; alle DDL/DCL/DML-Scripts laufen 1:1, ggf. minimale Rolle-Syntax-Anpassung).
  - **TLS by default erzwungen** – keine zusätzliche Konfiguration nötig (CHECK-Konformität mit NFA-02).
  - **Automatische tägliche Backups + PITR** (7 Tage Retention default), Snapshots inklusive.
  - **30-Tage Free Trial mit USD 300 Credit ohne Kreditkarte** (nur Verification via E-Mail) → ideal für Schulprojekt.
  - **EU-Regionen**: Frankfurt, Amsterdam, Stockholm, Helsinki, Warschau u. a. (DSGVO ✓). In dieser Arbeit gewählt: `do-ams` (Amsterdam).
  - **Sehr aufgeräumte Web-Console**; weniger kognitive Last als AWS.
  - **Monitoring + Logs out-of-box** (Prometheus, Datadog Integration optional).
  - **IP-Allowlist** wie Security Group bei AWS – feingranular pro Service.
  - **Service-URL** direkt mit Port/User/Passwort/CA-Cert verfügbar.
- **Contra**:
  - MySQL statt MariaDB (für unser Schema irrelevant, da keine MariaDB-only Features genutzt werden).
  - Nach 30 Tagen / nach 300 USD: ab ~17 €/Monat (Hobbyist Plan). Für den Demo-Zeitraum unkritisch.
  - Default-Master-User heisst `avnadmin` (nicht frei wählbar wie bei AWS) – wird durch zusätzlichen Schema-User `admin_giovanni` gespiegelt.
- **Kosten Demo-Zeitraum**: 0 € (im Trial).

## 3. Bewertungsmatrix (überarbeitet)

Skala 1 (schlecht) – 5 (sehr gut).

| Kriterium (Gewicht) | AWS RDS | Azure DB | Google CloudSQL | Self-Managed VM | **Aiven for MySQL** |
|---|:--:|:--:|:--:|:--:|:--:|
| MariaDB-/MySQL-kompatibel (5) | 5 (25) | 5 (25) | 4 (20) | 5 (25) | **5 (25)** |
| Sicherheit out-of-box (5) | 5 (25) | 4 (20) | 5 (25) | 2 (10) | **5 (25)** |
| Backups/PITR (4) | 5 (20) | 4 (16) | 5 (20) | 1 (4) | **5 (20)** |
| Kosten Schulprojekt (4) | 5 (20) | 1 (4) | 3 (12) | 4 (16) | **5 (20)** |
| Setup-Einfachheit (3) | 3 (9) | 4 (12) | 4 (12) | 2 (6) | **5 (15)** |
| Monitoring (3) | 5 (15) | 4 (12) | 5 (15) | 2 (6) | **4 (12)** |
| EU-Region/DSGVO (4) | 5 (20) | 5 (20) | 5 (20) | 5 (20) | **5 (20)** |
| Skalierbarkeit (2) | 5 (10) | 3 (6) | 5 (10) | 3 (6) | **5 (10)** |
| **Zugang/Onboarding (5)** | **1 (5)** | 2 (10) | 2 (10) | 4 (20) | **5 (25)** |
| **Total** | **149** | **125** | **144** | **113** | **🏆 172** |

## 4. Entscheidung

> **⚠ Finaler Entscheid (Update 06.07.2026): EIGENE CLOUD.** Die untenstehende
> Aiven-Entscheidung war das Ergebnis dieser Provider-Evaluation — **Aiven wurde
> evaluiert, aber bewusst zugunsten der eigenen Homelab-Cloud verworfen** (volle
> Kontrolle über TLS/Zertifikate/Firewall, kein Vendor-Lock, und gemäss
> LB3-Rahmen die **Max-Bonus-Option** «eigene Cloud-DB»). Produktiv deployt und
> live verifiziert: `docs/MS_C_Cloud_SelfHosted.md` + `VERIFICATION.md`.
> Der Aiven-Abschnitt bleibt als Nachweis der Evaluationstiefe erhalten.

→ *(evaluiert)* **Aiven for MySQL 8 · Service `backpacker-aiven-giovanni` · Region Amsterdam (Hobbyist Free-Trial)** als damaliges Cloud-Zielsystem.

**Begründung**:

1. Höchste Gesamtpunktzahl in der überarbeiteten Matrix (172 vs. 149 AWS).
2. **AWS war geplant, aber ohne TBZ-Schulungs-Account und ohne VPC-Berechtigungen praktisch blockiert.** Aiven löst das Onboarding-Problem komplett ohne Kreditkarte.
3. **Gemäss Bewertungsmatrix (LB3-Rahmen, MS C 2.1):** *"AWS ist Minimalanforderung. Andere oder eigene Cloud-DB gibt +"* — Aiven ist eine *andere* Cloud-DB und qualifiziert damit für den **Plus-Bonus**.
4. Sicherheits-Defaults bei Aiven (TLS-Pflicht, IP-Allowlist, KMS-äquivalente Encryption-at-Rest) erfüllen alle NFA-01..04.
5. MySQL 8 ist zu MariaDB 11 in den hier verwendeten Features (InnoDB, FK, CHECK, Rollen) zu ~99 % kompatibel; einziger Unterschied: `default_role`-Speicherort (`mysql.default_roles` statt `mysql.user`). Wird im Cloud-DCL berücksichtigt.

## 5. Personalisierter Setup-Plan (Aiven)

| Parameter | Wert |
|---|---|
| Aiven Project | `giovanni-m141-lb3` |
| Service Name | `backpacker-aiven-giovanni` |
| Cloud-Provider (unter Aiven) | DigitalOcean (von Aiven gemanaged) |
| Region | `do-ams` (Amsterdam, NL — DSGVO-konform) |
| Service Plan | **Free Trial / Hobbyist** |
| Engine | MySQL 8.x |
| Storage | inkludiert im Plan (10 GB) |
| Master User | `avnadmin` (Aiven-Default) + zusätzlich `admin_giovanni` als Schema-Owner |
| Master Passwort | von Aiven generiert (kopierbar aus Console) |
| Default DB | `defaultdb` (Aiven) + zusätzlich `backpacker_lb3_giovanni` |
| TLS | **erzwungen** (Aiven liefert `ca.pem` zum Download) |
| Public Access | Service erreichbar via Public Endpoint mit **IP-Allowlist** |
| IP-Allowlist | nur eigene öffentliche IP/32 |
| Backups | täglich, 2 Tage Retention im Trial (Hobbyist Plan: 7 Tage PITR) |
| Encryption at Rest | aktiv (AES-256, von Aiven gemanaged) |
| Verbindungs-URL | `mysql://avnadmin:__PWD__@backpacker-aiven-giovanni-giovannimerola1.h.aivencloud.com:13544/defaultdb?ssl-mode=REQUIRED` |
| Audit-Log | via Aiven Service Integrations (Datadog/Loki) optional |
| my.cnf-Äquivalent | Service-Parameter via Aiven-Console (siehe `config/my_aiven.cnf`) |

---

*Entscheidung getroffen am 30.06.2026 – Giovanni Merola*
