# NoSQL-Modelle

Quelle: [db-engines.com – Datenbankmodelle](https://db-engines.com/de/article/Datenbankmodelle)

NoSQL = "Not only SQL". Sind keine RDBMS-Ersatz, sondern Ergänzungen für Fälle wo das relationale Modell unpassend oder zu teuer ist (z.B. massives Schreibvolumen, horizontale Skalierung, schemafreie Daten, Graph-Beziehungen, oder einfach mega schnelle Key-Lookups).

| Modell | Wie es funktioniert | Vertreter | Vorteile | Nachteile | Typische Anwendungen |
|---|---|---|---|---|---|
| **Document** | JSON/BSON-Dokumente, geschachtelt, schemafrei | **MongoDB**, CouchDB | flexibel, gut für sich ändernde Strukturen, Sharding | Joins sind mühsam, eventual consistency | CMS, Produktkataloge, IoT, mobile App Backends |
| **Key-Value** | Key → Value, der Value ist opak | **Redis**, Memcached, DynamoDB | extrem schnell (oft in-memory), simple API | keine Queries über den Value | Sessions, Caching, Rate-Limiting, Leaderboards |
| **Wide Column** | Tabellen mit dynamischen Spalten pro Row, optimiert für viele Knoten | **Cassandra**, HBase, Bigtable | skaliert horizontal über Hunderte Nodes, keine Single Point of Failure | eingeschränktes Query-Modell, Schema dreht sich um Queries | Time-Series Datenmengen, Messaging, Logs in extremem Volumen |
| **Search** | Volltextindex als Primärspeicher | **Elasticsearch**, Solr | sehr schnelle Suche mit Relevanz-Ranking, Facetten | nicht transaktional, RAM-hungrig | Suche in Shops, Log-Aggregation (ELK), Security Analytics |
| **Graph** | Knoten + Kanten, Traversierung first-class | **Neo4j**, ArangoDB | Beziehungs-Queries (mehrere Hops) sind schnell und intuitiv | nicht für klassische tabellarische Daten | Soziale Netze, Empfehlungen, Betrugserkennung |
| **Time Series** | optimiert für Zeitreihen, Downsampling, Retention | **InfluxDB**, TimescaleDB, Prometheus | hohe Schreibrate, eingebaute Zeitfenster-Aggregation | schwach bei beliebigen Ad-hoc Queries | Monitoring, IoT-Sensoren, Finanzdaten |
| **Spatial / Geo** | speichert und indexiert Geodaten (Punkte, Linien, Flächen) | **PostGIS** (PG-Erweiterung), Oracle Spatial | räumliche Indizes (R-Tree), Operatoren wie `within`, `intersects` | eigene Lernkurve (SRID, Projektionen) | Karten, Routing, Geofencing, GIS |

## Wann was

- Daten strukturiert + Beziehungen wichtig → bleib bei **RDBMS**.
- Verschachtelte/unregelmässige Daten (CMS, Produkte) → **Document**.
- Cache / Sessions → **Key-Value**.
- Extrem viel Schreiblast, klare Zugriffsmuster → **Wide Column**.
- Suchfeld in einer App, Logs auswerten → **Search**.
- Beziehungen sind die Hauptfrage → **Graph**.
- Sensoren, Metriken → **Time Series**.
- Karten / Standort → **Spatial**.

In der Praxis kombinieren grössere Systeme oft mehrere davon: RDBMS für Stammdaten + Redis für Cache + Elasticsearch für Suche + InfluxDB für Metriken. PostgreSQL kann mit Erweiterungen einige davon abdecken (JSONB, PostGIS, TimescaleDB, pgvector).
