# LB1 Spick

09.06.2026 · ~45 min · 20% der Note · Stoff Tag 3 (Engines/Transaktionen) + Tag 4 (Sicherheit)

---

## Teil 1 — Spick (Reference)

### Storage Engines

| | InnoDB | MyISAM |
|---|---|---|
| Default? | ✅ ab 5.5 | – |
| Transaktionen | ✅ | ❌ |
| Lock-Level | Row | Table |
| Foreign Keys | ✅ | ❌ |
| Crash-safe | ✅ Redo Log | ❌ |
| Use Case | **immer** | Read-only Legacy |

Wechseln: `ALTER TABLE x ENGINE=InnoDB;`

### ACID
- **A**tomicity – alles oder nichts
- **C**onsistency – Regeln (Constraints, FKs) bleiben gültig
- **I**solation – Transaktionen sehen einander nicht halb-fertig
- **D**urability – COMMIT überlebt Crash

### Transaktion
```sql
START TRANSACTION;   -- oder BEGIN;
UPDATE konto SET saldo = saldo - 100 WHERE id=1;
UPDATE konto SET saldo = saldo + 100 WHERE id=2;
COMMIT;              -- oder ROLLBACK;
```
`SET autocommit=0;` zum Ausschalten des Standard-Autocommit.

### Isolation Levels (locker → streng)

| Level | Dirty | Non-Repeatable | Phantom |
|---|---|---|---|
| READ UNCOMMITTED | ❌ | ❌ | ❌ |
| READ COMMITTED | ✅ | ❌ | ❌ |
| **REPEATABLE READ** (Default) | ✅ | ✅ | ❌* |
| SERIALIZABLE | ✅ | ✅ | ✅ |

*InnoDB blockt Phantoms via Gap Locks.*
Setzen: `SET TRANSACTION ISOLATION LEVEL READ COMMITTED;`

### Locking & Deadlock
- **S-Lock** (Shared) = viele lesen, niemand schreibt.
- **X-Lock** (Exclusive) = einer schreibt, sonst nichts.
- **Deadlock** = 2 Txns warten gegenseitig → InnoDB killt eine mit Error 1213.

### User & Auth — DIE wichtigste Regel
**Ein User = `'name'@'host'`.** `'gigi'@'localhost'` und `'gigi'@'%'` sind **zwei verschiedene User**.

| Host | Bedeutung |
|---|---|
| `localhost` | nur dieser Rechner (oft socket) |
| `127.0.0.1` | nur lokaler TCP |
| `%` | von überall |
| `192.168.4.%` | nur dieses Subnet |

```sql
CREATE USER 'foo'@'%' IDENTIFIED BY 'pw';
DROP USER 'foo'@'%';
SET PASSWORD FOR 'foo'@'%' = PASSWORD('neu');
SELECT user, host FROM mysql.user;
SHOW GRANTS FOR 'foo'@'%';
```

### GRANT / REVOKE (DCL)
```sql
GRANT SELECT, INSERT ON shop.* TO 'foo'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
REVOKE INSERT ON shop.* FROM 'foo'@'%';
FLUSH PRIVILEGES;     -- nur nach manuellem Edit von mysql.user
```
Scope: `*.*` (alles) · `db.*` (eine DB) · `db.tbl` (eine Table) · `db.tbl(col)` (eine Spalte).
`WITH GRANT OPTION` = User darf seine Rechte weitergeben.

### Netzwerk & Config

| Setting | Effekt |
|---|---|
| `bind-address = 0.0.0.0` | remote OK |
| `bind-address = 127.0.0.1` | nur localhost |
| `port = 3306` | Standard-Port |
| `skip-networking` | TCP komplett aus |

Config-Datei:
- Linux + MariaDB: `/etc/mysql/mariadb.conf.d/50-server.cnf`
- XAMPP/Windows: `C:\xampp\mysql\bin\my.ini`
- Neu laden: `sudo systemctl restart mariadb`

Firewall: `sudo ufw allow 3306`.

### Auth Plugins
- `mysql_native_password` — alt, SHA1
- `caching_sha2_password` — MySQL 8 default
- `ed25519` — MariaDB modern
- `unix_socket` — Login als OS-User ohne Passwort (root@localhost auf Ubuntu)

### DDL / DML / DCL / TCL
- **DDL** = CREATE, ALTER, DROP
- **DML** = SELECT, INSERT, UPDATE, DELETE
- **DCL** = GRANT, REVOKE
- **TCL** = COMMIT, ROLLBACK, SAVEPOINT

---

## Teil 2 — Likely-to-come Q&A

Format ähnlich wie der Day-1 Checkpoint: Multiple Choice + kurze Definitionen + 1-2 praktische SQL-Aufgaben.

### Multiple Choice (kommt fast sicher)

**Q:** Welche Engine unterstützt Transaktionen?
**A:** InnoDB.

**Q:** Was bedeutet das "I" in ACID?
**A:** Isolation.

**Q:** Standard-Port MariaDB / MySQL?
**A:** 3306.

**Q:** Default Isolation Level?
**A:** REPEATABLE READ.

**Q:** Welche Engine macht Row-Level Locking?
**A:** InnoDB.

**Q:** Welche Befehle gehören zu DCL?
**A:** GRANT, REVOKE.

**Q:** Welche Isolation Levels verhindern Dirty Reads?
**A:** READ COMMITTED, REPEATABLE READ, SERIALIZABLE (alle ausser READ UNCOMMITTED).

**Q:** Was passiert nach ROLLBACK?
**A:** Alle Änderungen seit `START TRANSACTION` werden rückgängig gemacht.

**Q:** Welche Einstellung erlaubt Remote-Verbindungen?
**A:** `bind-address = 0.0.0.0` (oder die LAN-IP).

**Q:** Was bedeutet `'gigi'@'localhost'` ≠ `'gigi'@'%'`?
**A:** Zwei separate User mit eigenen Passwörtern und Rechten.

### Kurzantworten (kommen so gut wie immer)

**Q:** Erkläre ACID in einem Satz pro Buchstabe.
**A:** A = alles oder nichts. C = DB-Regeln (Constraints/FKs) bleiben gültig. I = Transaktionen sehen einander nicht halb-fertig. D = COMMIT überlebt Crash.

**Q:** Was ist ein Deadlock und wie reagiert InnoDB?
**A:** Zwei Transaktionen warten gegenseitig auf Locks → keine kommt weiter. InnoDB erkennt es automatisch und macht eine mit Error 1213 zurück. Die App muss die Transaktion neu probieren.

**Q:** Nenne 3 Unterschiede InnoDB vs MyISAM.
**A:** (1) Transaktionen ja/nein. (2) Row- vs Table-Lock. (3) Foreign Keys ja/nein. (Auch ok: crash-safe ja/nein.)

**Q:** Wofür ist der Host-Teil im User?
**A:** Schränkt ein, von welcher IP sich der User einloggen darf. Sicherheits-Massnahme.

**Q:** Wo liegt die MariaDB-Config auf Ubuntu und wie übernimmt man Änderungen?
**A:** `/etc/mysql/mariadb.conf.d/50-server.cnf`. Übernahme: `sudo systemctl restart mariadb`.

**Q:** Was bewirkt `WITH GRANT OPTION`?
**A:** Der User darf seine eigenen Rechte an andere User weitergeben.

### Praktisch (mind. 1 SQL-Schreibaufgabe kommt)

**Q:** SQL für User `shop_app` nur von 10.0.0.5, Passwort `geheim`, mit SELECT+INSERT auf `webshop.*`.
```sql
CREATE USER 'shop_app'@'10.0.0.5' IDENTIFIED BY 'geheim';
GRANT SELECT, INSERT ON webshop.* TO 'shop_app'@'10.0.0.5';
```

**Q:** Transaktion: 50 von Konto 1 auf Konto 2, Rollback wenn Konto 1 ins Minus.
```sql
START TRANSACTION;
UPDATE konto SET saldo = saldo - 50 WHERE id = 1;
-- prüfen ob saldo >= 0; falls nein:
ROLLBACK;
-- sonst:
UPDATE konto SET saldo = saldo + 50 WHERE id = 2;
COMMIT;
```

**Q:** Storage Engine einer Tabelle wechseln.
**A:** `ALTER TABLE kunden ENGINE = InnoDB;`

**Q:** User komplett löschen.
**A:** `DROP USER 'foo'@'%';`

### Szenario-Fragen (1-2 davon kommen)

**Q:** Server langsam, `SHOW PROCESSLIST` zeigt viele "Waiting for table lock". Engine + Lösung?
**A:** Wahrscheinlich MyISAM (table-lock). Lösung: `ALTER TABLE x ENGINE = InnoDB;` für Row-Level-Locks.

**Q:** App auf 10.0.0.50 kann sich nicht verbinden, Service läuft. Was prüfen?
**A:** (1) `bind-address` im Server — steht da `127.0.0.1`, nur lokal. (2) Existiert ein User mit passendem Host (`@'%'` oder `@'10.0.0.50'` oder `@'10.0.0.%'`)? (3) Firewall (Port 3306 offen?). (4) Network/Ping/`nc -zv ip 3306`.

---

## 60-Sek-Recall (kurz vor dem Test laut sagen)

1. ACID = Atomicity, Consistency, Isolation, Durability
2. Default Engine = InnoDB
3. Engine mit Transaktionen = InnoDB
4. Default Isolation Level = REPEATABLE READ
5. Standard Port = 3306
6. User-Format = `'name'@'host'`
7. Transaktion starten = `START TRANSACTION;`
8. Speichern / rückgängig = `COMMIT;` / `ROLLBACK;`
9. Rechte vergeben = `GRANT ... ON ... TO ...;`
10. Remote erlauben = `bind-address = 0.0.0.0`
11. Config neu laden = `systemctl restart mariadb`
12. Engine wechseln = `ALTER TABLE x ENGINE = InnoDB;`
