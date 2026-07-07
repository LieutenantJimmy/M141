# LB1 Mock-Test

Selber durchspielen, nicht spicken. Antworten + Erklärung ganz unten.
Zeit: ~30 min, ähnliche Länge wie das echte LB1.

---

## Teil A — Multiple Choice

Mehrere Antworten können richtig sein.

**1. Welche Storage Engine unterstützt Transaktionen?**

- [ ] MyISAM
- [ ] InnoDB
- [ ] Aria
- [ ] Memory

**2. Was bedeutet das "I" in ACID?**

- [ ] Integrity
- [ ] Isolation
- [ ] Indexing
- [ ] Independent

**3. Wie heisst der Standardport von MariaDB / MySQL?**

- [ ] 80
- [ ] 3306
- [ ] 5432
- [ ] 1433

**4. Welche Isolation Levels verhindern Dirty Reads?**

- [ ] READ UNCOMMITTED
- [ ] READ COMMITTED
- [ ] REPEATABLE READ
- [ ] SERIALIZABLE

**5. Welche Aussagen über `'gigi'@'localhost'` und `'gigi'@'%'` sind richtig?**

- [ ] Es sind zwei separate User mit getrennten Rechten
- [ ] Sie teilen sich automatisch dieselben Privilegien
- [ ] Der zweite erlaubt Verbindungen von jedem Host
- [ ] Wenn man eines löscht, ist das andere automatisch auch weg

**6. Was passiert nach einem `ROLLBACK;`?**

- [ ] Alle Änderungen seit dem letzten `COMMIT` werden gespeichert
- [ ] Alle Änderungen seit `START TRANSACTION` werden rückgängig gemacht
- [ ] Der Server wird neu gestartet
- [ ] Die Session wird beendet

**7. Welche Locks setzt InnoDB beim Schreiben?**

- [ ] Table-Level
- [ ] Row-Level
- [ ] Database-Level
- [ ] Keine

**8. Welche Eintragungen in `my.cnf` (Sektion `[mysqld]`) erlauben Remote-Verbindungen?**

- [ ] `bind-address = 127.0.0.1`
- [ ] `bind-address = 0.0.0.0`
- [ ] `skip-networking`
- [ ] `port = 3306`

**9. Was ist der Default-Isolation-Level in MariaDB/MySQL?**

- [ ] READ UNCOMMITTED
- [ ] READ COMMITTED
- [ ] REPEATABLE READ
- [ ] SERIALIZABLE

**10. Welche Befehle gehören zu DCL?**

- [ ] SELECT
- [ ] GRANT
- [ ] CREATE TABLE
- [ ] REVOKE
- [ ] COMMIT

---

## Teil B — Kurze Antworten

**11.** Erkläre **ACID** in einem Satz pro Buchstaben.

---

**12.** Was ist ein **Deadlock**? Wie reagiert InnoDB darauf?

---

**13.** Nenne **drei Unterschiede** zwischen InnoDB und MyISAM.

---

**14.** Warum sind `'admin'@'192.168.1.10'` und `'admin'@'%'` aus Sicherheitssicht **nicht** das Gleiche, auch wenn beide das Passwort `pw123` haben?

---

**15.** Welche Datei änderst du auf einer Ubuntu-MariaDB, um den Bind-Address zu setzen, und welcher Befehl danach übernimmt die Änderung?

---

## Teil C — Praktisch (SQL schreiben)

**16.** Schreibe die SQL-Statements, um:
- einen User `shop_app` zu erstellen, der **nur von 10.0.0.5** kommt, mit Passwort `geheim`
- ihm `SELECT` und `INSERT` auf alle Tabellen der Datenbank `webshop` zu geben
- das gleiche User-Konto wieder zu löschen

---

**17.** Schreibe eine Transaktion, die 50 CHF von Konto `id=1` auf Konto `id=2` überweist und die ganze Aktion rückgängig macht, falls Konto 1 dadurch ins Minus geht. *(Pseudo-Logik mit Check ist OK)*

---

**18.** Wie wechselst du die Storage Engine einer existierenden Tabelle `kunden` von MyISAM auf InnoDB?

---

## Teil D — Konzept-Scenarios

**19.** Du hast einen langsamen Server. `SHOW PROCESSLIST` zeigt, dass viele Queries auf "Waiting for table lock" hängen. Welche Storage Engine wird wahrscheinlich verwendet und was würdest du ändern?

---

**20.** Eine Web-Applikation auf einem anderen Server (`10.0.0.50`) kann sich plötzlich nicht mehr verbinden, obwohl der MariaDB-Service läuft. Nenne **drei** Dinge, die du der Reihe nach prüfst.

---

---

# Lösungen

<details>
<summary>Aufklappen erst nach dem Selbsttest</summary>

### Teil A

1. **InnoDB**. (Aria von MariaDB ist transaktional ab Version 11, aber im Kurs ist InnoDB die erwartete Antwort. Memory und MyISAM können keine Transaktionen.)
2. **Isolation**.
3. **3306**. (5432 = PostgreSQL, 1433 = MSSQL, 80 = HTTP.)
4. **READ COMMITTED, REPEATABLE READ, SERIALIZABLE**. (Nur READ UNCOMMITTED erlaubt Dirty Reads.)
5. **Erste + dritte richtig**: zwei separate User, der zweite erlaubt jeden Host. Sie teilen *nicht* automatisch Rechte und sind unabhängig löschbar.
6. **Zweite**: Änderungen seit `START TRANSACTION` werden rückgängig gemacht.
7. **Row-Level**. (Table-Level wäre MyISAM.)
8. **`bind-address = 0.0.0.0`**. `127.0.0.1` würde nur Localhost erlauben, `skip-networking` deaktiviert TCP komplett, `port=3306` ist nur die Portnummer.
9. **REPEATABLE READ**.
10. **GRANT, REVOKE**. (SELECT = DML, CREATE TABLE = DDL, COMMIT = TCL.)

### Teil B

**11. ACID:**
- **Atomicity:** Eine Transaktion läuft komplett durch oder gar nicht.
- **Consistency:** Die Datenbank-Regeln (Constraints, Foreign Keys) bleiben vor und nach jeder Transaktion gültig.
- **Isolation:** Gleichzeitige Transaktionen beeinflussen einander nicht (sehen keine halb-fertigen Daten).
- **Durability:** Nach einem `COMMIT` überleben die Änderungen einen Server-Crash (Redo-Log).

**12. Deadlock:** Zwei (oder mehr) Transaktionen warten gegenseitig auf Locks, die jeweils der andere hält → keine kann weitermachen. InnoDB erkennt das automatisch und macht eine der Transaktionen mit `Error 1213` zurück. Die App muss diese Transaktion neu starten.

**13. Drei Unterschiede InnoDB vs MyISAM:**
- Transaktionen: InnoDB ja, MyISAM nein.
- Locking: InnoDB row-level, MyISAM table-level.
- Foreign Keys: InnoDB ja, MyISAM nein.
- (auch gültig: crash-safe, Volltextsuche damals nur MyISAM, etc.)

**14.** Der Host-Teil schränkt ein, von welcher IP-Adresse aus der Login gültig ist. `'admin'@'192.168.1.10'` darf sich nur von genau dieser IP einloggen — ein Angreifer, der das Passwort kennt aber von woanders kommt, scheitert. `'admin'@'%'` darf sich von überall einloggen, was die Angriffsfläche massiv vergrössert.

**15.** Datei `/etc/mysql/mariadb.conf.d/50-server.cnf` (oder `/etc/mysql/my.cnf`). Übernahme mit `sudo systemctl restart mariadb`.

### Teil C

**16.**
```sql
CREATE USER 'shop_app'@'10.0.0.5' IDENTIFIED BY 'geheim';
GRANT SELECT, INSERT ON webshop.* TO 'shop_app'@'10.0.0.5';
FLUSH PRIVILEGES;
-- später:
DROP USER 'shop_app'@'10.0.0.5';
```

**17.**
```sql
START TRANSACTION;
UPDATE konto SET saldo = saldo - 50 WHERE id = 1;
-- Check: wenn saldo negativ → ROLLBACK
SELECT saldo FROM konto WHERE id = 1;
-- falls < 0:
ROLLBACK;
-- sonst:
UPDATE konto SET saldo = saldo + 50 WHERE id = 2;
COMMIT;
```
(In einer echten App würde man das in einem Stored Procedure mit `IF` oder in der App-Sprache prüfen. Für die Klausur reicht das Konzept: `START TRANSACTION` → ändern → `COMMIT` oder `ROLLBACK`.)

**18.**
```sql
ALTER TABLE kunden ENGINE = InnoDB;
```

### Teil D

**19.** Sehr wahrscheinlich **MyISAM** — nur dort gibt's table-level Locks, die alle anderen Queries blockieren. Lösung: Tabelle auf **InnoDB** umstellen → row-level Locking, viel besser bei viel Schreibverkehr:
```sql
ALTER TABLE foo ENGINE = InnoDB;
```

**20.** Drei sinnvolle Checks:
1. **Netzwerk-Erreichbarkeit:** Ping von 10.0.0.50 zur DB-IP + `telnet <db-ip> 3306` oder `nc -zv <db-ip> 3306`. Antwortet der Port?
2. **`bind-address`:** Auf dem DB-Server `grep bind-address /etc/mysql/mariadb.conf.d/50-server.cnf`. Steht da `127.0.0.1`, hört der Server nur lokal.
3. **User-Privilegien:** `SELECT user, host FROM mysql.user WHERE user = '<app-user>';`. Erlaubt der Host-Teil (`%` oder `10.0.0.50` oder `10.0.0.%`) Verbindungen von 10.0.0.50?
4. *(Bonus)* Firewall (`ufw status`), Service-Status (`systemctl status mariadb`).

</details>

---

## Bewertung (selber)

- 18-20 richtig → 5.5-6 ✅ überragend
- 14-17 richtig → 4.5-5 ✅ solide
- 10-13 richtig → 4 ✅ knapp bestanden
- < 10 richtig → durchgefallen, nochmals Cheatsheet lesen
