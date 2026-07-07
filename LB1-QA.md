# LB1 Q&A — Frage / Antwort zum Lernen

Frage lesen → 3 Sek. selber antworten → unten checken. Geht durch alles was am LB1 dran kommt.

---

## Storage Engines

**Q:** Welche Storage Engine ist seit MySQL 5.5 die Default?
**A:** InnoDB.

**Q:** Welche der zwei klassischen Engines unterstützt Transaktionen?
**A:** InnoDB. MyISAM nicht.

**Q:** Welche Engine sperrt beim Schreiben die ganze Tabelle?
**A:** MyISAM (Table-Level Lock). InnoDB macht Row-Level.

**Q:** Welche Engine unterstützt Foreign Keys?
**A:** InnoDB. MyISAM ignoriert Foreign-Key-Klauseln.

**Q:** Welche Engine ist crash-safe?
**A:** InnoDB (via Redo Log).

**Q:** Wie wechselst du die Engine einer Tabelle auf InnoDB?
**A:** `ALTER TABLE tabellenname ENGINE = InnoDB;`

**Q:** Nenne 3 Unterschiede InnoDB vs MyISAM.
**A:** (1) Transaktionen ja/nein, (2) Row- vs Table-Lock, (3) Foreign Keys ja/nein. Auch gültig: crash-safe ja/nein.

---

## ACID

**Q:** Was bedeutet ACID?
**A:** Atomicity, Consistency, Isolation, Durability.

**Q:** Was heisst Atomicity?
**A:** Eine Transaktion läuft komplett durch oder gar nicht — alles oder nichts.

**Q:** Was heisst Consistency?
**A:** DB-Regeln (Constraints, Foreign Keys) bleiben vor und nach jeder Transaktion gültig.

**Q:** Was heisst Isolation?
**A:** Gleichzeitige Transaktionen sehen einander nicht halb-fertig.

**Q:** Was heisst Durability?
**A:** Nach `COMMIT` überleben die Änderungen einen Server-Crash.

---

## Transaktionen

**Q:** Wie startet man eine Transaktion?
**A:** `START TRANSACTION;` oder `BEGIN;`

**Q:** Wie speichert / verwirft man die Änderungen?
**A:** `COMMIT;` speichert, `ROLLBACK;` macht alles seit START TRANSACTION rückgängig.

**Q:** Was ist `autocommit`?
**A:** Standard ist `1` (an) → jede einzelne Query ist eine eigene Transaktion. Mit `SET autocommit=0;` muss man COMMIT/ROLLBACK selber machen.

**Q:** Was passiert nach einem ROLLBACK?
**A:** Alle Änderungen seit dem letzten `START TRANSACTION` werden rückgängig gemacht. Vorherige COMMITs bleiben.

---

## Isolation Levels

**Q:** Was ist der Default-Isolation-Level in MariaDB/MySQL?
**A:** REPEATABLE READ.

**Q:** Nenne die 4 Isolation Levels von locker nach streng.
**A:** READ UNCOMMITTED → READ COMMITTED → REPEATABLE READ → SERIALIZABLE.

**Q:** Was ist ein Dirty Read?
**A:** Eine Transaktion liest Daten einer anderen Transaktion, die noch nicht commited ist.

**Q:** Welche Levels verhindern Dirty Reads?
**A:** Alle ausser READ UNCOMMITTED.

**Q:** Was ist ein Non-Repeatable Read?
**A:** Derselbe SELECT in einer Transaktion liefert ein anderes Resultat (weil eine andere Transaktion eine Row geändert hat).

**Q:** Was ist ein Phantom Read?
**A:** Eine neue Zeile taucht plötzlich auf, weil eine andere Transaktion ein INSERT gemacht hat.

**Q:** Wie setzt man den Isolation Level?
**A:** `SET TRANSACTION ISOLATION LEVEL READ COMMITTED;`

---

## Locking & Deadlocks

**Q:** Was ist ein Shared (S) Lock?
**A:** Mehrere können gleichzeitig lesen, keiner darf schreiben.

**Q:** Was ist ein Exclusive (X) Lock?
**A:** Einer schreibt, niemand sonst kann lesen oder schreiben.

**Q:** Was ist ein Deadlock?
**A:** Zwei Transaktionen warten gegenseitig auf Locks, die jeweils der andere hält — keine kann weiter.

**Q:** Wie reagiert InnoDB auf einen Deadlock?
**A:** Erkennt es automatisch, killt eine der Transaktionen mit `Error 1213`. Die App muss diese Transaktion nochmal versuchen.

---

## User & Auth (Tag 4)

**Q:** Wie ist ein User in MariaDB aufgebaut?
**A:** `'name'@'host'`. Der Host-Teil legt fest, von wo aus eingeloggt werden darf.

**Q:** Sind `'gigi'@'localhost'` und `'gigi'@'%'` derselbe User?
**A:** Nein. Zwei komplett separate User mit separaten Passwörtern und separaten Rechten.

**Q:** Was bedeutet der Host `%`?
**A:** Wildcard — von jedem Host aus erlaubt.

**Q:** Was bedeutet der Host `localhost`?
**A:** Nur von dieser Maschine selber (oft via UNIX socket, nicht TCP).

**Q:** Wie erlaubst du nur Verbindungen aus dem Subnet 192.168.4.0/24?
**A:** Mit Host `'192.168.4.%'` beim CREATE USER / GRANT.

**Q:** Wie legst du einen User an?
**A:** `CREATE USER 'foo'@'%' IDENTIFIED BY 'passwort';`

**Q:** Wie zeigt man alle User?
**A:** `SELECT user, host FROM mysql.user;`

**Q:** Wie änderst du das Passwort eines Users?
**A:** `SET PASSWORD FOR 'foo'@'%' = PASSWORD('neu');` oder `ALTER USER 'foo'@'%' IDENTIFIED BY 'neu';`

**Q:** Wie löschst du einen User?
**A:** `DROP USER 'foo'@'%';`

**Q:** Wie zeigt man die Rechte eines Users?
**A:** `SHOW GRANTS FOR 'foo'@'%';`

---

## GRANT / REVOKE (DCL)

**Q:** Welche Befehle gehören zu DCL?
**A:** GRANT und REVOKE. (Manchmal auch COMMIT/ROLLBACK = TCL.)

**Q:** Wie gibst du einem User SELECT und INSERT auf alle Tabellen der Datenbank `shop`?
**A:** `GRANT SELECT, INSERT ON shop.* TO 'foo'@'%';`

**Q:** Wie gibst du komplette Admin-Rechte?
**A:** `GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;`

**Q:** Was bedeutet `WITH GRANT OPTION`?
**A:** Der User darf seine Rechte selber an andere User weitergeben.

**Q:** Wie nimmst du Rechte wieder weg?
**A:** `REVOKE INSERT ON shop.* FROM 'foo'@'%';`

**Q:** Wofür braucht man `FLUSH PRIVILEGES;`?
**A:** Nach manuellem Edit der `mysql.user`-Tabelle (UPDATE), damit der Server die neuen Rechte einliest. Nach GRANT/REVOKE nicht nötig.

**Q:** Was bedeutet `*.*`?
**A:** Alle Datenbanken, alle Tabellen.

**Q:** Was bedeutet `shop.*`?
**A:** Alle Tabellen der Datenbank `shop`.

---

## Netzwerk & Konfiguration

**Q:** Was ist der Standardport von MariaDB / MySQL?
**A:** 3306.

**Q:** Welche Einstellung in `my.cnf` erlaubt Remote-Verbindungen?
**A:** `bind-address = 0.0.0.0` (oder die spezifische LAN-IP).

**Q:** Was bewirkt `bind-address = 127.0.0.1`?
**A:** Server hört nur auf Localhost, keine Remote-Verbindungen möglich.

**Q:** Wo liegt die Config-Datei auf Ubuntu mit MariaDB?
**A:** `/etc/mysql/mariadb.conf.d/50-server.cnf` (bzw. `/etc/mysql/my.cnf`).

**Q:** Wo liegt sie unter XAMPP / Windows?
**A:** `C:\xampp\mysql\bin\my.ini`.

**Q:** Wie übernimmt MariaDB Config-Änderungen?
**A:** `sudo systemctl restart mariadb` (Linux) bzw. Service neu starten (Windows).

**Q:** Wie öffnet man Port 3306 in der Linux-Firewall?
**A:** `sudo ufw allow 3306` (oder spezifischer mit Source-IP).

---

## Auth Plugins

**Q:** Was ist `mysql_native_password`?
**A:** Legacy-Auth-Plugin von MySQL. Hash basiert auf SHA1.

**Q:** Was ist der MySQL-8-Default?
**A:** `caching_sha2_password`.

**Q:** Was ist `unix_socket`?
**A:** Auth ohne Passwort, basiert auf dem OS-User. So loggt sich `root@localhost` auf Ubuntu standardmässig ein.

**Q:** Was ist MariaDBs moderner Auth-Plugin?
**A:** `ed25519`.

---

## Bonus: Test-Fallen

**Q:** Welche Engine bei viel gleichzeitigem Schreiben?
**A:** InnoDB (Row-Level Lock skaliert besser).

**Q:** Was ist DDL, DML, DCL, TCL?
**A:** DDL = Data Definition (CREATE, ALTER, DROP). DML = Data Manipulation (SELECT, INSERT, UPDATE, DELETE). DCL = Data Control (GRANT, REVOKE). TCL = Transaction Control (COMMIT, ROLLBACK, SAVEPOINT).

**Q:** Wenn `SHOW PROCESSLIST` viele Queries mit "Waiting for table lock" zeigt — welche Engine läuft wahrscheinlich, und was tun?
**A:** Wahrscheinlich MyISAM. Lösung: `ALTER TABLE x ENGINE = InnoDB;`.

**Q:** App auf 10.0.0.50 kann sich nicht mehr verbinden — was prüfen?
**A:** (1) `bind-address` im Server, (2) User existiert mit passendem Host (`@'%'` oder `@'10.0.0.50'` oder `@'10.0.0.%'`), (3) Firewall lässt Port 3306 durch, (4) Network/ping/`nc -zv ip 3306`.

**Q:** Default-Sortierung / Collation in MariaDB für `utf8mb4`?
**A:** `utf8mb4_general_ci` oder `utf8mb4_uca1400_ai_ci` (je nach Version). `_ci` = case-insensitive.

---

## 60-Sekunden-Recall vor dem Test

Schau auf eine leere Zeile und sag laut:

1. ACID = ___ ___ ___ ___
2. Default Engine = ___
3. Engine mit Transaktionen = ___
4. Engine mit Row-Lock = ___
5. Default Isolation Level = ___
6. Default Port = ___
7. User-Format = ___ @ ___
8. Transaktion starten = ___
9. Speichern / rückgängig = ___ / ___
10. Rechte geben / weg = ___ / ___
11. Bind-Address für remote = ___
12. Config neu laden = ___

Wenn du 10/12 ohne nachschauen kannst → safe für 4.0.
