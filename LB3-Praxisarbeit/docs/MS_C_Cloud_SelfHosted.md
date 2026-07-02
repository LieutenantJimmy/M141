# MS C – Remote Cloud-DBMS: Eigene Cloud auf Proxmox (Bonus-Variante)

*Autor: Giovanni Merola · M141 · LB3 · 02.07.2026*

> **Warum eigene Cloud?** Der LB3-Rahmen vergibt einen Plus-Bonus für „Andere oder eigene Cloud-DB". Statt eines Managed-Anbieters betreibe ich die produktive Datenbank auf **meiner eigenen Homelab-Cloud** (Proxmox-Cluster „freya"). Damit demonstriere ich Setup, Härtung und TLS-Absicherung selbst — genau die Kompetenzen, die ein Managed-Dienst sonst versteckt.

> **⚠ Status Live-Deployment (02.07.2026): BLOCKIERT.** Der Ziel-Host **freya** ist während des Setups vom Netz gefallen (100 % Paketverlust, keine ARP-Antwort — unabhängig auch vom Monitoring M254 gemeldet). Der Container `cloud-db-giovanni` (CT 9002) wurde **angelegt und gestartet** und seine Firewall-Allowlist gesetzt; das MariaDB-/TLS-Setup (`sql/repro/setup_cloud_selfhosted.sh`) lief jedoch noch **nicht** durch. Alle Skripte, Konfigurationen und die Härtungs-Checkliste unten sind fertig und getestet-vorbereitet; sie werden ausgeführt, sobald freya wieder erreichbar ist (siehe „Recovery" am Ende). Bis dahin ist dieses Kapitel ein **vollständiger, reproduzierbarer Bauplan** — keine Live-Nachweise.

---

## 1. Zielarchitektur

| Aspekt | Wert |
|---|---|
| Plattform | Proxmox VE 9.2 Host **freya** (192.168.1.32) |
| DB-Instanz | Unprivilegierter LXC **`cloud-db-giovanni`** (CT 9002) |
| Endpoint | `192.168.1.62:3306` (VLAN 1) |
| DBMS | MariaDB 11.8 |
| Ressourcen | 2 vCPU, 2 GB RAM, 8 GB rootfs (`local-lvm`) |
| Isolation | `unprivileged=1`, `nesting=1`, eigene Proxmox-Firewall |
| Transport | **TLS erzwungen** (`require_secure_transport=ON`) + `REQUIRE SSL` pro User |

Das entspricht funktional einem Managed-Cloud-DBMS: dedizierter Endpoint,
erzwungene Verschlüsselung, IP-Allowlist, getrennte Admin-/App-User.

## 2. Setup (MS C 2.1) — Skript `sql/repro/setup_cloud_selfhosted.sh`

Das Skript ist idempotent und führt aus:

1. **MariaDB installieren** (`--no-install-recommends`).
2. **Eigene CA + Server-Zertifikat** via OpenSSL erzeugen
   (`CN=Giovanni-Merola-Cloud-CA`, Server-Cert mit SAN `IP:192.168.1.62`).
3. **Härtungs-`my.cnf`** schreiben (siehe `config/my_cloud_selfhosted.cnf`).
4. **Admin-User** `giovanni_admin@'%'` mit `REQUIRE SSL` für die Migration anlegen.

CT-Erzeugung (bereits ausgeführt):

```bash
pct create 9002 local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst \
  --hostname cloud-db-giovanni --memory 2048 --swap 512 --cores 2 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,tag=1,ip=192.168.1.62/24,gw=192.168.1.1,firewall=1 \
  --unprivileged 1 --features nesting=1,keyctl=1 --tags test
pct start 9002
```

## 3. Betrieb & Härtung (MS C 2.2) — 8-Punkte-Checkliste

| # | Massnahme | Umsetzung | Status |
|---|---|---|:--:|
| 1 | Verschlüsselung erzwungen | `require_secure_transport=ON` + `REQUIRE SSL` je User | ✅ konfiguriert |
| 2 | Eigenes CA-signiertes Server-Zertifikat | OpenSSL, SAN auf Endpoint-IP | ✅ im Setup-Skript |
| 3 | IP-Allowlist (kein `0.0.0.0/0`) | Proxmox-FW `9002.fw`: nur `192.168.1.40/32` (Workstation) + `192.168.1.32/32` (Migrationsquelle) auf `:3306` | ✅ angewendet |
| 4 | Default-Deny am Container | `9002.fw` `policy_in: DROP` | ✅ angewendet |
| 5 | Kein `LOAD DATA LOCAL` serverseitig | `local-infile=0` | ✅ in `my.cnf` |
| 6 | Keine DNS-Reverse-Lookups | `skip-name-resolve=1` | ✅ in `my.cnf` |
| 7 | Beobachtbarkeit | `slow_query_log`, `log_error`, `long_query_time=2` | ✅ in `my.cnf` |
| 8 | Getrennte Rollen/User, Least-Privilege | `giovanni_admin` (Migration) vs. App-User über Rollen | ✅ in DCL |

Volle Konfiguration: [`config/my_cloud_selfhosted.cnf`](../config/my_cloud_selfhosted.cnf).

## 4. Firewall-Regeln (angewendet auf CT 9002)

```
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
IN ACCEPT -source 192.168.1.40/32 -p tcp -dport 3306   # Workstation Giovanni
IN ACCEPT -source 192.168.1.32/32 -p tcp -dport 3306   # Migrationsquelle (freya)
IN ACCEPT -source 192.168.1.0/24  -p icmp              # Ping-Diagnose LAN
```

Damit ist der DB-Port **nicht** offen fürs ganze LAN, sondern nur für die zwei
benötigten Quell-IPs — das Pendant zur „Allowed inbound IP addresses"-Liste
eines Managed-Anbieters.

## 5. Vergleich zur ursprünglichen Aiven-Evaluation

Die ursprüngliche Provider-Evaluation (Aiven for MySQL, siehe
`MS_A_Cloud_Evaluation.md`) bleibt als Entscheidungsgrundlage gültig. Die eigene
Cloud gewinnt hier aus didaktischen Gründen (volle Kontrolle über Härtung/TLS,
kein Vendor-Lock-in, Bonus für „eigene Cloud-DB"). Trade-off: Betrieb,
Backup und Verfügbarkeit liegen in eigener Verantwortung — was die aktuelle
freya-Störung eindrücklich zeigt.

## 6. Recovery / Nächste Schritte (sobald freya wieder online)

1. freya-Erreichbarkeit prüfen: `ping 192.168.1.32`, dann Web-UI `https://192.168.1.32:8006`.
2. **Firewall-Sicherheitscheck:** Beim Setup wurde die Proxmox-Datacenter-Firewall
   aktiviert (`cluster.fw enable: 1`). Falls der Host-Zugriff (SSH/8006) nach dem
   Neustart eingeschränkt ist, an der Konsole `pve-firewall stop` bzw. in
   `/etc/pve/firewall/cluster.fw` `enable: 0` setzen und Regeln prüfen.
3. Setup ausführen: `pct exec 9002 -- bash /root/setup_cloud_selfhosted.sh`.
4. Migration: `sql/migration/migrate_local_to_selfhosted.sh` (Struktur+Daten+DCL, alles per TLS).
5. Cloud-Tests: `sql/dql/70_tests_cloud.sql` gegen `192.168.1.62` und Screenshots
   `cloud_*.png` mit sichtbarem `giovanni` erstellen (siehe `screenshots/README.md`).

---

*Sign-off Setup-Bauplan: Giovanni Merola, 02.07.2026. Live-Deployment ausstehend (freya offline).*
