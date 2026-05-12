# Tag 1 – Einführung, DB-Engines, Installation

**Datum:** Di 12.05.2026
**Kompetenzmatrix:** A1, A2
**Offizielles Material:** [TBZ – 1.Tag](https://gitlab.com/ch-tbz-it/Stud/m141/m141/-/blob/main/1.Tag)

## Was heute lief

- Wiederholung Begriffe (DBS, DBMS, Datenbasis) und Client/Server
- DB-Modelle Übersicht: relational vs NoSQL-Familien
- Auftrag 1: DBMS-Vergleich MariaDB / MySQL / PostgreSQL → [RDBMS-Vergleich.md](./RDBMS-Vergleich.md)
- Auftrag 2: NoSQL-Modelle vergleichen → [NoSQL-Vergleich.md](./NoSQL-Vergleich.md)
- MariaDB installieren, User anlegen, mit drei Klienten testen → [Installation.md](./Installation.md) + [Status-Output.md](./Status-Output.md)
- Checkpoint → [Checkpoint.md](./Checkpoint.md)

## Begriffe in eigenen Worten

Wird im Modul immer wieder durcheinander gebracht, also fix mal sauber:

- **DBS** – das ganze System (Server + Software + Daten). "Wir betreiben einen DB-Server" meint das DBS.
- **DBMS** – das Programm dahinter, z.B. `mysqld` / `mariadbd`. Macht SQL parsen, Transaktionen, Auth.
- **Datenbank / Datenbasis** – die eigentlichen Daten + Schema. Tabellen `kunden`, `bestellungen` mit Inhalt.

Merksatz: DBMS = Software, Datenbank = Inhalt, DBS = alles zusammen.

**Client/Server:** Server stellt den Dienst bereit (Port 3306). Client verbindet sich (CLI, phpMyAdmin, DB Pro, Web-App, was auch immer). Mehrere Clients gleichzeitig → kein Problem.

**DB-Modelle:** relational dominiert. Daneben die NoSQL-Familien (Document, Key-Value, Wide Column, Graph) für Fälle wo RDBMS nicht passt. Details im NoSQL-Doc.

**MariaDB vs MySQL:** MariaDB ist ein Fork von MySQL 5.5 (2009, gestartet von Monty Widenius nachdem Oracle Sun gekauft hat). Funktional für unseren Kurs egal, wir nehmen MariaDB weil Open Source.

## Setup-Entscheid

Skript empfiehlt XAMPP auf Windows + MySQL Workbench. Hab stattdessen:

- **MariaDB direkt auf einer Ubuntu-VM** (Proxmox, VMID 4142) → realistischer als XAMPP, das wäre eh nur fürs Lokale
- **DB Pro** statt Workbench als GUI Client → Workbench ist mega dated
- **phpMyAdmin** wie im Skript

Funktional alles gleich, nur halt nicht XAMPP. Details und Befehle in der Installation-Doku.

## Stand

- [x] Begriffe verstanden
- [x] RDBMS-Vergleich
- [x] NoSQL-Vergleich
- [x] MariaDB installiert + läuft (`systemctl is-active mariadb` → active)
- [x] User `gigi` mit allen Rechten
- [x] phpMyAdmin erreichbar
- [x] `STATUS;` in CLI ausgeführt + dokumentiert
- [ ] `STATUS;` / Test-Query in DB Pro screenshotten (mach ich noch selber)
- [x] Checkpoint

## Reflexion

Was den ganzen Tag gefressen hat war die VM-Installation. Erst Subiquity-Installer in noVNC versucht — Tastatur war shit, hat Zeichen verschluckt im Network-Step. Dann auf cloud-init umgestellt mit `qm importdisk`, das lief sauber durch.

Lehre: für sowas Cloud-Image + cloud-init >> Klick-Installer. Werd ich nächstes Mal direkt so machen.

Vertiefen will ich noch:
- Storage Engines (kommt an Tag 3)
- DCL / GRANT-System (Tag 4 + 5)
