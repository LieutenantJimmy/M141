# MS C – Remote Cloud-DBMS: Eigene Cloud auf Proxmox (Bonus-Variante)

*Autor: Giovanni Merola · M141 · LB3 · Deployment 06.07.2026*

> **Warum eigene Cloud?** Der LB3-Rahmen vergibt einen Plus-Bonus für „Andere oder eigene Cloud-DB". Statt eines Managed-Anbieters betreibe ich die produktive Datenbank auf **meiner eigenen Homelab-Cloud** (Proxmox VE). Damit demonstriere ich Setup, Härtung und TLS-Absicherung selbst — genau die Kompetenzen, die ein Managed-Dienst sonst versteckt.

> **✅ Status Live-Deployment (06.07.2026): PRODUKTIV.** Die eigene Cloud-DB läuft: LXC `cloud-db-giovanni` am Endpoint **`192.168.1.62:3306`** (TLS erzwungen, TLSv1.3). Struktur + Daten wurden per TLS migriert (2036/11/82/8/1006/1746 — identisch zur lokalen DB), die drei Rollen-User sind mit `REQUIRE SSL` angelegt, und Klartext-Verbindungen werden mit `ERROR 3159` abgewiesen. Alle Nachweise liegen als `screenshots/cloud_*.png` (+ rohe `.txt`) im Repo.
>
> **Deployment-Host-Hinweis:** Ursprünglich war der Host **freya** vorgesehen; freya fiel jedoch am 02.07. aus (Hardware/Netz, wartet auf Power-Cycle). Da die Architektur host-agnostisch ist (unprivilegierter LXC + Standard-Proxmox), wurde die Cloud-DB auf dem **produktiven Homelab-Host `phoebe`** (192.168.1.30) instanziiert — identisches Setup-Skript, identische Härtung. Der `freya`-Recovery-Pfad in §6 bleibt als Referenz bestehen.

---

## 1. Zielarchitektur

| Aspekt | Wert |
|---|---|
| Plattform | Proxmox VE 9.x Homelab-Host **phoebe** (192.168.1.30) — freya-Fallback in §6 |
| DB-Instanz | Unprivilegierter LXC **`cloud-db-giovanni`** (CT 9003) |
| Endpoint | `192.168.1.62:3306` (VLAN 1) |
| DBMS | MariaDB 11.8.6 |
| Ressourcen | 2 vCPU, 2 GB RAM, 8 GB rootfs (`ssd-pool`) |
| Isolation | `unprivileged=1`, `nesting=1`, eigene Proxmox-Firewall (Datacenter-FW aktiv) |
| Transport | **TLS erzwungen** (`require_secure_transport=ON`, TLSv1.3) + `REQUIRE SSL` pro User |

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

## 4. Firewall-Regeln (angewendet auf CT 9003, `screenshots/cloud_rds_security_group.png`)

```
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
IN ACCEPT -source 192.168.1.40/32 -p tcp -dport 3306   # Workstation Giovanni
IN ACCEPT -source 192.168.1.30/32 -p tcp -dport 3306   # phoebe Host (Migration + Demo-Client)
IN ACCEPT -source 192.168.1.2/32  -p tcp -dport 3306   # vpn-01 (Demo via VPN von TBZ)
IN ACCEPT -source 10.10.0.0/24    -p tcp -dport 3306   # VPN-Client-Pool
IN ACCEPT -source 192.168.1.0/24  -p icmp              # Ping-Diagnose LAN
```

Damit ist der DB-Port **nicht** offen fürs ganze LAN (`0.0.0.0/0`), sondern nur
für die benötigten Quell-IPs — das Pendant zur „Allowed inbound IP addresses"-Liste
eines Managed-Anbieters.

## 5. Live-Verifikation (06.07.2026) — Nachweise

Alle Schritte gegen den Live-Endpoint `192.168.1.62:3306` ausgeführt und als
Screenshot **und** rohe `.txt` im Repo abgelegt:

| Nachweis | Ergebnis | Datei |
|---|---|---|
| Cloud-DBMS-Übersicht (CT läuft, MariaDB 11.8.6) | ✅ | `screenshots/cloud_rds_dashboard.*` |
| Verbindungs-Info + gehärtete `my.cnf` | ✅ | `screenshots/cloud_rds_konfiguration.*` |
| Firewall-Allowlist (kein `0.0.0.0/0`) | ✅ | `screenshots/cloud_rds_security_group.*` |
| Automatisierte Migration per TLS (Struktur+Daten+DCL) | ✅ Restore OK, Cipher `TLS_AES_256_GCM_SHA384` | `screenshots/cloud_migration_run.*` |
| TLS-Login OK (positiv) | ✅ `giovanni_dba@%`, TLSv1.3 | `screenshots/cloud_verbindung_giovanni.*` |
| Klartext abgewiesen (negativ) | ✅ `ERROR 3159 … insecure transport prohibited` | `screenshots/cloud_tls_required.*` |
| Cloud-Tests `70_tests_cloud.sql` (Counts, FK=5, utf8mb4, Rollen) | ✅ 2036/11/82/8/1006/1746 | `screenshots/cloud_tests_data.*` |
| Demo: 3 User per TLS, Rollen erzwungen (1142/1143) | ✅ | `screenshots/cloud_demo_3_users.*` |

## 6. Vergleich zur ursprünglichen Aiven-Evaluation

Die ursprüngliche Provider-Evaluation (Aiven for MySQL, siehe
`MS_A_Cloud_Evaluation.md`) bleibt als Entscheidungsgrundlage gültig. Die eigene
Cloud gewinnt hier aus didaktischen Gründen (volle Kontrolle über Härtung/TLS,
kein Vendor-Lock-in, Bonus für „eigene Cloud-DB"). Trade-off: Betrieb, Backup und
Verfügbarkeit liegen in eigener Verantwortung — was der freya-Ausfall zeigt (die
Cloud wurde deshalb auf `phoebe` deployt).

## 7. Recovery-Pfad für freya (Referenz — Cloud läuft aktuell auf phoebe)

> Die produktive Cloud-DB läuft bereits auf **phoebe** (§ oben). Dieser Abschnitt
> bleibt als dokumentierter Wiederherstellungs-/Umzugspfad für **freya**, sobald
> dieser Host wieder online ist (Power-Cycle durch Giovanni nötig).

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

*Sign-off: Giovanni Merola. Setup-Bauplan 02.07.2026; **eigene Cloud LIVE deployt 06.07.2026** auf `phoebe` (Endpoint 192.168.1.62:3306, TLS erzwungen). freya-Recovery-Pfad (§7) bleibt als Referenz dokumentiert.*
