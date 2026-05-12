# STATUS in den drei Klienten

VM `m141-db-01` (Proxmox 4142), Ubuntu 24.04, MariaDB 10.11.14. Eingeloggt als `gigi`.

## CLI – `mariadb`

```
$ mariadb -u gigi -pm141 -e "STATUS;"
```

```text
mariadb  Ver 15.1 Distrib 10.11.14-MariaDB, for debian-linux-gnu (x86_64)

Connection id:        31
Current database:
Current user:         gigi@localhost
SSL:                  Not in use
Server version:       10.11.14-MariaDB-0ubuntu0.24.04.1 Ubuntu 24.04
Protocol version:     10
Connection:           Localhost via UNIX socket
Server characterset:  utf8mb4
Db    characterset:   utf8mb4
Client characterset:  utf8mb3
Conn. characterset:   utf8mb3
UNIX socket:          /run/mysqld/mysqld.sock
Uptime:               3 min 39 sec

Threads: 1  Questions: 61  Slow queries: 0  Opens: 33  Open tables: 26  Queries per second avg: 0.278
```

Was ich daraus lese:

- Eingeloggt als `gigi@localhost` (also nicht über TCP, sondern UNIX-Socket — drum auch SSL "not in use").
- MariaDB-Version 10.11.14 mit Ubuntu-Patchlevel.
- Charset `utf8mb4` → unterstützt auch Emojis und das ganze Unicode-Zeug.
- Uptime: knapp 4 Minuten. Server lief noch nicht lang.

Datenbanken nach Frischinstall:

```sql
SHOW DATABASES;
```

```text
information_schema
mysql
performance_schema
sys
```

Nur Systemdatenbanken. Eigene kommen ab Tag 2.

```sql
SELECT VERSION(), CURRENT_USER(), @@hostname, @@port;
```

```text
10.11.14-MariaDB-0ubuntu0.24.04.1   gigi@localhost   m141-db-01   3306
```

## phpMyAdmin

Über `http://192.168.4.142/phpmyadmin/` eingeloggt als `gigi`. Im **Status**-Tab gibt's dieselben Infos (Server-Version, Uptime, Threads, Traffic) plus Sparklines.

Screenshot: → `resources/phpmyadmin-status.png` *(noch hinzufügen)*

## DB Pro (vom Windows-Host)

Verbindung:

| Feld | Wert |
|---|---|
| Typ | MariaDB |
| Host | `192.168.4.142` |
| Port | `3306` |
| User | `gigi` |
| Passwort | `m141` |

`STATUS` ist ein Klient-Builtin der `mariadb`-CLI, kein SQL. In DB Pro geht das so:

```sql
SELECT VERSION();
SHOW STATUS LIKE 'Uptime%';
SHOW VARIABLES LIKE 'character_set%';
SHOW VARIABLES LIKE 'port';
SELECT CURRENT_USER(), USER(), @@hostname, NOW();
```

Screenshot: → `resources/dbpro-status.png` *(noch hinzufügen)*

## Server stoppen / starten (Q14 Checkpoint)

Auf Linux kein XAMPP-Panel, läuft alles über systemd:

```bash
sudo systemctl stop mariadb
sudo systemctl start mariadb
sudo systemctl restart mariadb
sudo systemctl status mariadb
```

Check ob der Prozess wirklich läuft:

```bash
systemctl is-active mariadb    # active
ps -ef | grep mariadbd
ss -tlnp | grep 3306
```

Praktischer Test gemacht: `stop` → phpMyAdmin Login schlägt fehl ("Cannot connect"), DB Pro Connect schlägt fehl. `start` → beides wieder OK. Passt.

## Schneller Vergleich

| | CLI | DB Pro | phpMyAdmin |
|---|---|---|---|
| `STATUS;` direkt | ✅ | ❌ (Workaround mit SQL) | ❌ (eigener Status-Tab) |
| Scripting | ✅ (`-e "..."`) | – | – |
| Exploration | OK | ✅ (Schema-Tree, Diagramme) | OK |
| Monitoring | nur via SQL | OK | ✅ (eigene Statistik-Seiten) |
