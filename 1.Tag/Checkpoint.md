# Checkpoint Tag 1

Original: [1T_CheckPoint.md](https://gitlab.com/ch-tbz-it/Stud/m141/m141/-/blob/main/1.Tag/1T_CheckPoint.md)

---

**1. Welches ist die heute am häufigsten verwendete Datenbank-Art?**

- [x] Relationale Datenbank

**2. Welche Komponenten sind in einem DB-Server enthalten?**

- [x] 1 oder mehrere Datenbanken
- [x] Datenbank-Management-System (DBMS)

(Anwendungen sind Clients, nicht im Server. Formulare/Reports gehören in die Applikationsschicht.)

**3. Welche Fabrikate sind relationale Datenbanken?**

- [x] Oracle, MySQL, MariaDB, MS Access, PostgreSQL

(CouchDB ist Document, MongoDB auch.)

**4. Aufgaben eines DB-Clients?**

- [x] User-Interface für den Datenzugriff
- [x] Leitet Befehle des Benutzers an den Server weiter

(Daten speichern + User verwalten macht der Server.)

**5. Client-Komponenten von MySQL?**

- [x] mysql, phpMyAdmin

(mysqld = Server, my.ini = Config.)

**6. Server-Komponente von MySQL?**

- [x] mysqld

---

**7. Client/Server-Modell beschreiben.**

Server stellt zentral einen Dienst bereit (hier: DB-Engine auf Port 3306). Clients verbinden sich über ein definiertes Protokoll und nutzen den Dienst. Viele Clients gleichzeitig auf einen Server, Server und Client können auf verschiedener Hardware laufen und unabhängig skaliert / updated werden.

**8. Vorteile gegenüber Desktop-DB?**

- Mehrere User können gleichzeitig auf dieselben Daten zugreifen (Locking, Transaktionen)
- Daten sind zentral, ein einziger Stand
- Sicherheit und Rechte zentral am Server
- Backup, Logging, Monitoring zentral
- Server kann irgendwo stehen, Clients überall (Web, Mobile, Desktop)
- Skalierbar (mehr Hardware / Replikation / Cluster)

**9. Wie werden Daten in einer relationalen DB gespeichert?**

In Tabellen. Zeilen = Datensätze (Tupel), Spalten = Attribute mit Datentyp. Beziehungen zwischen Tabellen über Primär-/Fremdschlüssel. Physisch auf der Platte als Dateien — Format hängt von der Storage Engine ab (InnoDB schreibt in `ibd`-Files plus Transaktions-Log, MyISAM trennt Daten und Indizes in `MYD`/`MYI`).

**10. Vorteile von referentieller Datenintegrität?**

- Keine "verwaisten" Fremdschlüssel — alles verweist auf existierende Datensätze
- Geschäftsregeln in der DB, nicht in jeder App einzeln
- ON DELETE / ON UPDATE CASCADE / SET NULL → kontrollierte Folge-Aktionen
- Fehler werden früh erkannt (beim INSERT/UPDATE), nicht erst beim Reporting

**11. Die 4 NoSQL-Gruppen?**

1. Dokumentenorientiert (MongoDB, CouchDB)
2. Key-Value (Redis, DynamoDB)
3. Wide Column / Big-Table (Cassandra, HBase)
4. Graph (Neo4j)

(Search, Time Series und Spatial laufen heute auch als eigene Familien, aber das Skript bleibt bei diesen vier.)

**12. Was bedeutet DBaaS? Beispiel.**

Database as a Service. Cloud-Anbieter stellt eine fertig konfigurierte, gemanagte DB bereit. Man verbindet sich mit Endpoint + Credentials, Installation/Patches/Backup/HA macht der Anbieter.

Beispiel: **Amazon RDS for MariaDB**. In der AWS-Konsole eine Instance erstellen, Instance-Typ + Storage wählen, AWS provisioniert. Man kriegt einen Endpoint wie `my-db.xxx.eu-central-1.rds.amazonaws.com:3306` und verbindet sich wie mit einem lokalen Server. Vergleichbares gibt's bei Azure (Database for MariaDB) und GCP (Cloud SQL).

**13. Vorteile RDBMS gegenüber anderen DB-Modellen?**

- Klar definiertes Schema → Datenqualität wird durch die DB selber durchgesetzt
- SQL als mächtige, standardisierte Abfragesprache (Joins, Aggregationen, Subqueries)
- ACID-Transaktionen → wichtig für Geld, Bestände, Buchungen
- Foreign Keys / referentielle Integrität
- Reife Tooling-Landschaft (GUIs, ORMs, Migrations, Backup)
- Jeder Dev kennt Grund-SQL → kein Einarbeitungs-Stress im Team

---

**14. Server stoppen und starten**

Auf der Linux-VM mit systemd statt XAMPP-Panel:

```bash
sudo systemctl stop mariadb
sudo systemctl start mariadb
sudo systemctl restart mariadb
sudo systemctl status mariadb
```

Kontrolle dass der Daemon läuft: `ps -ef | grep mariadbd`, `ss -tlnp | grep 3306`, oder `systemctl is-active mariadb`.

Test gemacht: `stop` → DB Pro Connect schlägt fehl, phpMyAdmin meldet "Cannot connect". `start` → beides wieder OK.

**15. Server prüfen in den drei Klienten**

- CLI: `mariadb -u gigi -pm141 -e "STATUS;"` → Output in [Status-Output.md](./Status-Output.md)
- phpMyAdmin: `http://192.168.4.142/phpmyadmin/` → Status-Tab
- DB Pro: SQL-Query mit `SELECT VERSION();` etc.

Alle drei zeigen dieselbe Version (10.11.14), Uptime und User. ✓
