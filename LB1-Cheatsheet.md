# LB1 Cheatsheet — Tag 3 + 4

LB1: 09.06.2026, 20%, ~45 min. Inhalt: Transaktionen + Sicherheit.

## Storage Engines

| | InnoDB | MyISAM |
|---|---|---|
| Default? | ✅ ab MySQL 5.5 | ❌ |
| Transaktionen | ✅ | ❌ |
| Locking | Row-level | Table-level |
| Foreign Keys | ✅ | ❌ |
| Crash-safe | ✅ (redo log) | ❌ |
| Wann nehmen | **immer** | nur Read-only / Legacy |

Wechseln: `ALTER TABLE foo ENGINE=InnoDB;`

## ACID

- **A**tomicity — all or nothing
- **C**onsistency — Regeln (Constraints, FKs) bleiben gültig
- **I**solation — gleichzeitige Transaktionen sehen einander nicht halb-fertig
- **D**urability — nach COMMIT überlebt's einen Crash

## Transaktionen Syntax

```sql
START TRANSACTION;   -- oder: BEGIN;
UPDATE konto SET saldo = saldo - 100 WHERE id=1;
UPDATE konto SET saldo = saldo + 100 WHERE id=2;
COMMIT;              -- speichern
-- oder
ROLLBACK;            -- alles rückgängig
```

`AUTOCOMMIT=1` ist Standard → jede Query ist eine eigene Transaktion. `SET autocommit=0;` zum Ausschalten.

## Isolation Levels

| Level | Dirty Read | Non-Repeatable Read | Phantom Read |
|---|---|---|---|
| READ UNCOMMITTED | ❌ möglich | ❌ | ❌ |
| READ COMMITTED | ✅ verhindert | ❌ | ❌ |
| **REPEATABLE READ** *(Default MariaDB/MySQL)* | ✅ | ✅ | ❌* |
| SERIALIZABLE | ✅ | ✅ | ✅ |

*\* InnoDB verhindert Phantoms via Gap Locks*

- **Dirty Read** = liest uncommittete Daten anderer Transaktion
- **Non-Repeatable Read** = gleicher SELECT, anderes Resultat
- **Phantom Read** = neue Zeile taucht plötzlich auf

Setzen: `SET TRANSACTION ISOLATION LEVEL READ COMMITTED;`

## Locking

- **Shared (S) Lock** = mehrere können lesen, keiner schreiben
- **Exclusive (X) Lock** = einer schreibt, sonst nichts
- **Deadlock** = zwei Transaktionen warten aufeinander → InnoDB killt eine, gibt `Error 1213`
- InnoDB: Row-Level Lock. MyISAM: Table Lock (deshalb skaliert MyISAM nicht für Schreiben).

## User & Auth (Tag 4)

**Wichtigste Regel:** Ein User in MySQL/MariaDB ist **`name@host`**. `'gigi'@'localhost'` und `'gigi'@'%'` sind **zwei separate User** mit getrennten Rechten.

Host-Teil:
- `localhost` = nur von dieser Maschine (oft UNIX socket)
- `%` = von überall
- `192.168.4.%` = nur aus dem Subnet
- `127.0.0.1` = nur lokaler TCP

```sql
CREATE USER 'foo'@'%' IDENTIFIED BY 'pass';
DROP USER 'foo'@'%';
SET PASSWORD FOR 'foo'@'%' = PASSWORD('newpass');
SHOW GRANTS FOR 'foo'@'%';
SELECT user, host FROM mysql.user;
```

## GRANT / REVOKE (DCL)

```sql
GRANT SELECT, INSERT ON shop.* TO 'foo'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
REVOKE INSERT ON shop.* FROM 'foo'@'%';
FLUSH PRIVILEGES;       -- nach manuellem Edit der mysql.user Tabelle
```

Scope:
- `*.*` = alle DBs, alle Tables
- `shop.*` = alle Tables in `shop`
- `shop.kunden` = nur diese Table
- `shop.kunden(name, email)` = nur diese Spalten

Wichtige Privilegien: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `DROP`, `ALTER`, `INDEX`, `GRANT OPTION`, `ALL PRIVILEGES`.

## Auth Plugins

| Plugin | Wo |
|---|---|
| `mysql_native_password` | Alt, MySQL 5.7 default |
| `caching_sha2_password` | MySQL 8 default |
| `ed25519` | MariaDB |
| `unix_socket` | Login via OS-User, kein Passwort (root@localhost auf Ubuntu default) |
| `pam` | Über System-PAM |

## Netzwerk-Zugang

`my.cnf` / `mariadb.conf.d/50-server.cnf`:

```
bind-address = 0.0.0.0    # alle Interfaces → remote möglich
bind-address = 127.0.0.1  # nur localhost
port = 3306               # Standard
```

Nach Änderung: `sudo systemctl restart mariadb`.

Firewall (Linux): `sudo ufw allow 3306`.

TLS erzwingen: `GRANT ... REQUIRE SSL;` oder im User: `ALTER USER 'foo'@'%' REQUIRE SSL;`.

## Config-Dateien

| OS | Datei |
|---|---|
| Linux (MariaDB) | `/etc/mysql/mariadb.conf.d/50-server.cnf` |
| Linux (MySQL) | `/etc/mysql/my.cnf` |
| XAMPP / Windows | `C:\xampp\mysql\bin\my.ini` |

Wichtige Sektionen: `[mysqld]` (Server), `[client]` (CLI), `[mysql]` (mysql.exe).

## Klassiker / Test-Fallen

| Frage | Antwort |
|---|---|
| Engine für Transaktionen? | InnoDB |
| ACID? | Atomicity, Consistency, Isolation, Durability |
| Default Isolation Level? | REPEATABLE READ |
| Standard Port? | 3306 |
| `'x'@'localhost'` vs `'x'@'%'`? | zwei verschiedene User |
| Wie wird remote Zugriff erlaubt? | `bind-address=0.0.0.0` + GRANT `@'%'` + Firewall |
| Wie startet eine Transaktion? | `START TRANSACTION;` oder `BEGIN;` |
| Was macht ROLLBACK? | macht alle Änderungen seit START TRANSACTION rückgängig |
| Was ist ein Deadlock? | zwei Transaktionen warten gegenseitig auf Locks |
| Worauf wirkt sich `WITH GRANT OPTION` aus? | erlaubt User selber Rechte weiterzugeben |
| Wo steht die Konfiguration? | `my.cnf` (Linux) / `my.ini` (Windows) |
| Wie wechselt man Engine? | `ALTER TABLE x ENGINE=InnoDB;` |

## Was du auswendig können musst (60-Sekunden-Test)

1. ACID-Buchstaben + je 3 Wörter Erklärung
2. InnoDB vs MyISAM — 3 Unterschiede
3. Die 4 Isolation Levels in der Reihenfolge
4. `user@host` Konzept in einem Satz
5. `START TRANSACTION` / `COMMIT` / `ROLLBACK` Syntax
6. `CREATE USER` + `GRANT` + `REVOKE` Syntax
7. `bind-address` Bedeutung
8. Standard-Port = 3306
