# Vergleich MariaDB / MySQL / PostgreSQL

Quelle: [db-engines.com](https://db-engines.com/de/system/MariaDB%3BMySQL%3BPostgreSQL)

Alle drei sind relationale Open-Source-DBs. MariaDB und MySQL sind quasi Geschwister (MariaDB ist 2009 als Fork von MySQL 5.5 entstanden). PostgreSQL kommt aus einer anderen Ecke (UC Berkeley, älter, technisch am "saubersten" was SQL-Standard angeht).

## Tabelle

| | **MariaDB** | **MySQL (Oracle)** | **PostgreSQL** |
|---|---|---|---|
| Hersteller | MariaDB Foundation | Oracle | PG Global Dev. Group |
| Erstes Release | 2009 | 1995 | 1989 (POSTGRES) |
| Lizenz | GPL v2 | GPL v2 + kommerziell | PostgreSQL Lizenz (BSD-ähnlich) |
| Modell | Relational | Relational | Objektrelational |
| Default Storage Engine | InnoDB | InnoDB | – (nur eine) |
| Pluggable Engines | ja (Aria, ColumnStore, Spider...) | ja, aber begrenzt | nein |
| Transaktionen / ACID | ja | ja | ja |
| JSON-Support | ja | ja | ja (JSONB ist die Referenz) |
| Replikation | Master-Slave, **Galera** (sync) | Master-Slave, Group Replication | Streaming + Logical |
| Standard-Port | 3306 | 3306 | **5432** |
| Tools | mysql-CLI, phpMyAdmin, DB Pro | dasselbe + MySQL Workbench | psql, pgAdmin |

## Vorteile / Nachteile

**MariaDB**
- ✅ 100% Open Source, klare GPL-Linie ohne Oracle-Politik
- ✅ Galera Cluster fertig dabei (synchrone Multi-Master Replikation)
- ✅ Drop-in Replacement für MySQL (bis ca. 5.7)
- ❌ Kompatibilität mit MySQL driftet ab Version 10.x weiter weg
- ❌ Manche Hoster supporten MariaDB nicht direkt

**MySQL (Oracle)**
- ✅ Riesiges Ökosystem, ist im Web-Stack omnipräsent (WordPress & Co.)
- ✅ Sehr gut dokumentiert, viele Tutorials
- ✅ MySQL Workbench als offizielles GUI
- ❌ Oracle als Eigentümer macht der Community Sorgen
- ❌ Standardtreue historisch schwächer als PostgreSQL

**PostgreSQL**
- ✅ Am standardtreuesten, "macht SQL richtig"
- ✅ Riesige Feature-Liste: CTEs, Window Functions, JSONB, Materialized Views
- ✅ Erweiterbar: PostGIS (Geo), TimescaleDB (Zeitreihen), pgvector (KI)
- ✅ Sehr permissive Lizenz
- ❌ Höhere Einstiegshürde (VACUUM, Roles, MVCC-Tuning)
- ❌ Replikations-Setup ist mehr Knöpfe als MariaDB-Galera

## Wo wird was eingesetzt

- **MariaDB:** LAMP, Webhosting, CMS-Backends, Galera-Cluster für HA
- **MySQL:** Webapps aller Grössen, AWS RDS/Aurora, grosse Internetplattformen
- **PostgreSQL:** komplexere Business-Logik, Geo (PostGIS), moderne SaaS / Startups, Backends für KI-Stuff

## Für M141

Wir nehmen MariaDB. Reicht für alles was in den 9 Tagen drankommt (Storage Engines, Transaktionen, GRANT/REVOKE, Logging, Cloud-Migration).
