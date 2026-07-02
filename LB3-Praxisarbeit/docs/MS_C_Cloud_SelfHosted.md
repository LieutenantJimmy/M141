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

> **⚠ Verdacht auf Auslöser der Störung.** Unmittelbar vor dem Netzausfall wurde
> die Proxmox-Datacenter-Firewall aktiviert (`/etc/pve/firewall/cluster.fw`
> `enable: 1`) und `pve-firewall restart` ausgeführt. Das ist der **wahrscheinliche
> Auslöser** des Zugriffsverlusts (auch wenn das fehlende ARP eher auf eine
> Host-/NIC-Ebene deutet). freya wird ohnehin per **BMC-Power-Cycle durch
> Giovanni** neu gestartet (der BMC lehnt unsere Passwörter ab, daher kein
> Remote-Fix möglich; der Host erholt sich nicht von selbst).
>
> **Deshalb MUSS die Recovery an der Konsole mit dem Firewall-Stop beginnen,
> BEVOR irgendetwas anderes passiert** — sonst droht erneuter Aussperr-Effekt.

### 6.1 Voraussetzung: freya physisch neu starten

freya reagiert nicht auf ARP/Ping/8006 — der Host ist auf L2 verschwunden. Er
erholt sich **nicht von selbst** und muss von Giovanni per **BMC/IPMI oder
physischem Power-Cycle** neu gestartet werden. Der BMC lehnt unsere gespeicherten
Zugangsdaten ab, daher ist kein Remote-Reset durch das Automations-Tooling
möglich. Ohne diesen Neustart ist keiner der folgenden Schritte durchführbar.

### 6.2 Recovery-Reihenfolge (Firewall-Stop ZUERST)

Es gibt zwei Wege — der Orchestrator macht Schritt 0–3 automatisch:

**Variante A (empfohlen): Orchestrator-Script auf dem Host.**
Das Script [`sql/repro/recover_and_deploy_freya.sh`](../sql/repro/recover_and_deploy_freya.sh)
hat die korrekte Reihenfolge fest eingebaut — es ruft **als allererstes**
`pve-firewall stop` auf, setzt `cluster.fw enable:0`, prüft/startet CT 9002 und
führt dann das Setup im Container aus:

```bash
# auf dem freya-Host, als root, nach dem Neustart:
/root/recover_and_deploy_freya.sh            # Firewall-Stop + CT-Check + Setup
/root/recover_and_deploy_freya.sh --migrate  # zusätzlich Migrations-Hinweis
```

**Variante B: manuell, Schritt für Schritt.**

1. **ZUERST an der Host-Konsole (noVNC/iKVM):** `pve-firewall stop`
   — danach `sed -i 's/enable: 1/enable: 0/' /etc/pve/firewall/cluster.fw`,
   Regeln prüfen, bevor die Firewall *kontrolliert* wieder aktiviert wird.
   Grund: das Aktivieren dieser Firewall ist der Verdachts-Auslöser des Aussperr.
2. Erreichbarkeit prüfen: `ping 192.168.1.32`, Web-UI `https://192.168.1.32:8006`, SSH.
3. Container prüfen/starten: `pct status 9002` (ggf. `pct start 9002`).
4. Setup (idempotent): `pct push 9002 setup_cloud_selfhosted.sh /root/ && pct exec 9002 -- bash /root/setup_cloud_selfhosted.sh`.
5. CA-Cert aus dem CT holen (für die Migration): `pct pull 9002 /etc/mysql/certs/ca.pem ./cloud-ca-giovanni.pem`.
6. Migration: `export CLOUD_ADMIN_PWD=…; sql/migration/migrate_local_to_selfhosted.sh` (Struktur + Daten + DCL, alles per TLS).

### 6.3 Verifikation & Screenshots (Urheberbeweis)

Nach dem Deploy die Cloud-Nachweise `cloud_*.png` mit sichtbarem `giovanni`
erstellen (Liste in `screenshots/README.md`). Mindestnachweise:

```bash
# TLS-Login OK (positiv) -> cloud_verbindung_giovanni.png
mysql -h 192.168.1.62 -u giovanni_dba -p --ssl-verify-server-cert \
      --ssl-ca=cloud-ca-giovanni.pem backpacker_lb3_giovanni -e "SELECT CURRENT_USER();"

# Klartext wird abgewiesen (negativ, TLS-Pflicht) -> cloud_tls_required.png
mysql -h 192.168.1.62 -u giovanni_dba -p --ssl-mode=DISABLED -e "SELECT 1;"
#   erwartet: "ERROR 1045 / Access denied ... secure transport required"

# Cloud-Tests + Zeilenzahlen -> cloud_tests_data.png
mysql -h 192.168.1.62 -u giovanni_dba -p --ssl-ca=cloud-ca-giovanni.pem \
      backpacker_lb3_giovanni < sql/dql/70_tests_cloud.sql
```

### 6.4 Rollback / Aufräumen

- Setup ist idempotent — erneutes Ausführen ist gefahrlos.
- Rückbau der Test-Umgebung: `pct stop 9002 && pct destroy 9002` (entfernt die
  Cloud-DB vollständig). Firewall-Zustand des Hosts danach bewusst wieder setzen.

---

*Sign-off Setup-Bauplan: Giovanni Merola, 02.07.2026. Live-Deployment ausstehend (freya offline, wartet auf BMC-Power-Cycle).*
