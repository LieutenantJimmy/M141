# MS B 1.2 – Zugriffsmatrix (Backpacker_LB3 – Giovanni Merola)

*Autor: Giovanni Merola · M141 · LB3*

Die Zugriffsmatrix definiert, welche **Rollen** (Benutzergruppen) auf welchen **Tabellen/Attributen** welche **DML-Operationen** ausführen dürfen.

Legende: **S** = SELECT, **I** = INSERT, **U** = UPDATE, **D** = DELETE, **–** = nicht möglich, **(–)** = entzogen.

## 1. Rolle `role_benutzer` (Empfang, Reception)

| Tabelle / Attribut          | S | I | U | D |
|-----------------------------|:-:|:-:|:-:|:-:|
| `tbl_personen` (alle Attr.) | x |   | x |   |
| `tbl_benutzer.Password`     | – | – | – | – |
| `tbl_benutzer.deaktiviert`  | x | – | – | – |
| `tbl_benutzer` restliche Attribute | x | x | x | – |
| `tbl_buchung`               | x | x | x | x |
| `tbl_positionen`            | x | x | x | x |
| `tbl_land`                  | x |   |   |   |
| `tbl_leistung`              | x |   |   |   |

### Begründung
- Empfangsmitarbeitende erfassen Gäste (`tbl_personen` S/U) und Buchungen.
- Sie sehen das Aktivitäts-Datum eines Benutzers, dürfen aber **kein Passwort** und **kein Deaktivierungsdatum** ändern.
- Stammdaten (`tbl_land`, `tbl_leistung`) sind nur lesbar (Pflege durch Management).
- DELETE auf `tbl_personen` ist ausgeschlossen, weil Personen aus Compliance-Gründen nicht physisch gelöscht werden.

## 2. Rolle `role_management` (Geschäftsleitung)

| Tabelle / Attribut          | S | I | U | D |
|-----------------------------|:-:|:-:|:-:|:-:|
| `tbl_positionen`            | x |   |   |   |
| `tbl_buchung`               | x |   |   |   |
| restliche Tabellen (`tbl_personen`, `tbl_benutzer`, `tbl_land`, `tbl_leistung`) | x | x | x | x |

### Begründung
- Das Management führt **Stammdaten-Pflege** (Personen, Benutzerkonten, Länder, Leistungskatalog).
- Auf operativen Buchungs-/Positionsdaten hat das Management **read-only**, um nicht versehentlich Umsätze zu ändern.
- Benutzer-Pflege (Passwort-Resets, Deaktivierung) ist exklusiv beim Management.

## 3. Vollständige Cross-Tabellen-Übersicht

| Tabelle | role_benutzer | role_management |
|---|---|---|
| `tbl_personen` | S, U | S, I, U, D |
| `tbl_benutzer` (Password) | — | S, I, U, D |
| `tbl_benutzer` (deaktiviert) | S | S, I, U, D |
| `tbl_benutzer` (Rest) | S, I, U | S, I, U, D |
| `tbl_buchung` | S, I, U, D | S |
| `tbl_positionen` | S, I, U, D | S |
| `tbl_land` | S | S, I, U, D |
| `tbl_leistung` | S | S, I, U, D |

## 4. Personalisierte Benutzer

| User | Rolle | Zweck |
|---|---|---|
| `giovanni_benutzer` | `role_benutzer` | Test-Account Empfang (Beispiel) |
| `giovanni_manager`  | `role_management` | Test-Account Management |
| `giovanni_dba`      | (Admin, alle Rechte) | Wartungs-/Migrations-Account |

Die Umsetzung erfolgt in `sql/dcl/01_roles_users.sql` (siehe MS B 1.3). Es wird **MariaDB Roles** verwendet (`CREATE ROLE …`, `GRANT … TO role`, `GRANT role TO user`, `SET DEFAULT ROLE`).

## 5. Spezialfall Spaltenrechte (`tbl_benutzer.Password`, `…deaktiviert`)

MariaDB unterstützt Spaltenrechte. Daher:

```sql
-- ROLE_BENUTZER darf NICHT auf Password zugreifen, daher SELECT nur auf
-- die erlaubten Spalten:
GRANT SELECT (Benutzer_ID, Benutzername, Vorname, Name, Benutzergruppe,
              erfasst, deaktiviert, aktiv) ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
GRANT INSERT (Benutzername, Vorname, Name, Benutzergruppe, aktiv)
         ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
GRANT UPDATE (Benutzername, Vorname, Name, Benutzergruppe, aktiv)
         ON backpacker_lb3_giovanni.tbl_benutzer TO role_benutzer;
-- DELETE NICHT vergeben
-- Password NICHT vergeben → bleibt für role_benutzer unsichtbar
```

---

*Stand: 30.06.2026 – Giovanni Merola*
