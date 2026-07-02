#!/usr/bin/env bash
# ================================================================
# M141 LB3 - Setup "eigene Cloud-DB" (CT cloud-db-giovanni)
# MariaDB + erzwungenes TLS + Haertung - Giovanni Merola
#
# Laeuft INNERHALB des Containers cloud-db-giovanni (CT 9002) als root.
# Vollstaendig idempotent: mehrfaches Ausfuehren fuehrt zum selben
# Endzustand und bricht bei jedem Fehler kontrolliert ab.
#
# WICHTIG (Recovery-Reihenfolge nach freya-Ausfall): Auf dem HOST muss
# ZUERST `pve-firewall stop` laufen (siehe recover_and_deploy_freya.sh
# bzw. docs/MS_C_Cloud_SelfHosted.md), BEVOR dieses Setup gestartet wird.
#
# Konfigurierbar via Umgebungsvariablen (mit Defaults):
#   CLOUD_ADMIN_PWD  - Passwort fuer giovanni_admin (Migrations-User)
#   ENDPOINT_IP      - IP, fuer die das Server-Zertifikat gilt (SAN)
# ================================================================
set -Eeuo pipefail

# ---- Konfiguration -------------------------------------------------------
CERTDIR="/etc/mysql/certs"
CONF="/etc/mysql/mariadb.conf.d/99-cloud-giovanni.cnf"
LOGDIR="/var/log/mysql"
ENDPOINT_IP="${ENDPOINT_IP:-192.168.1.62}"
CLOUD_ADMIN_PWD="${CLOUD_ADMIN_PWD:-CloudAdmin!Giovanni-2026}"
CA_CN="Giovanni-Merola-Cloud-CA"
SRV_CN="cloud-db-giovanni"

# ---- Helper --------------------------------------------------------------
log()  { printf '\n\033[1;36m### %s ###\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf '\n\033[1;31mFEHLER (Zeile %s): %s\033[0m\n' "${1:-?}" "${2:-abgebrochen}" >&2; exit 1; }
trap 'die "$LINENO" "unerwarteter Fehler im Setup"' ERR

# ---- Preflight -----------------------------------------------------------
log "[0/6] Preflight-Checks"
[ "$(id -u)" -eq 0 ] || die "$LINENO" "muss als root laufen"
command -v apt-get >/dev/null 2>&1 || die "$LINENO" "apt-get fehlt (kein Debian/Ubuntu?)"
info "root OK, apt-get vorhanden, Ziel-Endpoint=${ENDPOINT_IP}"

# ---- MariaDB installieren (mit Lock-Wait + Retry) ------------------------
log "[1/6] MariaDB installieren (idempotent)"
export DEBIAN_FRONTEND=noninteractive
if command -v mariadbd >/dev/null 2>&1 || command -v mysqld >/dev/null 2>&1; then
  info "MariaDB bereits installiert - Installationsschritt uebersprungen"
else
  apt_try() {
    local n=0
    until "$@"; do
      n=$((n+1)); [ "$n" -ge 3 ] && return 1
      info "apt-Versuch $n fehlgeschlagen, warte 10s und wiederhole ..."; sleep 10
    done
  }
  apt_try apt-get update -qq -o Dpkg::Use-Pty=0 \
    || die "$LINENO" "apt-get update nach 3 Versuchen fehlgeschlagen"
  apt_try apt-get install -y -qq --no-install-recommends -o Dpkg::Use-Pty=0 \
    mariadb-server mariadb-client openssl \
    || die "$LINENO" "MariaDB-Installation nach 3 Versuchen fehlgeschlagen"
fi
mariadb --version || die "$LINENO" "MariaDB-Client nicht aufrufbar"

# ---- TLS: eigene CA + Server-Zertifikat (je Artefakt idempotent) ---------
log "[2/6] TLS-Zertifikate (eigene CA)"
mkdir -p "$CERTDIR"
umask 077
if [ ! -f "$CERTDIR/ca.pem" ] || [ ! -f "$CERTDIR/ca-key.pem" ]; then
  info "erzeuge CA ..."
  openssl genrsa -out "$CERTDIR/ca-key.pem" 4096 2>/dev/null
  openssl req -new -x509 -nodes -days 3650 -key "$CERTDIR/ca-key.pem" \
    -out "$CERTDIR/ca.pem" \
    -subj "/C=CH/L=Zuerich/O=GioTech Homelab/OU=M141 LB3/CN=${CA_CN}" 2>/dev/null
else
  info "CA existiert bereits - behalten"
fi
if [ ! -f "$CERTDIR/server-cert.pem" ] || [ ! -f "$CERTDIR/server-key.pem" ]; then
  info "erzeuge Server-Zertifikat (SAN IP:${ENDPOINT_IP}) ..."
  openssl genrsa -out "$CERTDIR/server-key.pem" 4096 2>/dev/null
  openssl req -new -key "$CERTDIR/server-key.pem" -out "$CERTDIR/server.csr" \
    -subj "/C=CH/L=Zuerich/O=GioTech Homelab/OU=M141 LB3/CN=${SRV_CN}" 2>/dev/null
  printf 'subjectAltName = IP:%s, DNS:%s\n' "$ENDPOINT_IP" "$SRV_CN" > "$CERTDIR/san.cnf"
  openssl x509 -req -in "$CERTDIR/server.csr" -CA "$CERTDIR/ca.pem" \
    -CAkey "$CERTDIR/ca-key.pem" -CAcreateserial -out "$CERTDIR/server-cert.pem" \
    -days 825 -extfile "$CERTDIR/san.cnf" 2>/dev/null
  rm -f "$CERTDIR/server.csr" "$CERTDIR/san.cnf"
else
  info "Server-Zertifikat existiert bereits - behalten"
fi
chown mysql:mysql "$CERTDIR"/*.pem
chmod 600 "$CERTDIR/server-key.pem" "$CERTDIR/ca-key.pem"
chmod 644 "$CERTDIR/ca.pem" "$CERTDIR/server-cert.pem"
info "CA:     $(openssl x509 -in "$CERTDIR/ca.pem" -noout -subject -enddate | tr '\n' ' ')"
info "Server: $(openssl x509 -in "$CERTDIR/server-cert.pem" -noout -ext subjectAltName 2>/dev/null | tail -1 | tr -d ' ')"

# ---- Haertungs-Konfiguration ---------------------------------------------
log "[3/6] Haertungs-Konfiguration (my.cnf, ueberschreibend)"
mkdir -p "$LOGDIR" && chown mysql:mysql "$LOGDIR"
cat > "$CONF" <<CNF
# ============================================================
# M141 LB3 - "Eigene Cloud" prod. Konfiguration
# Server: ${SRV_CN} (LXC auf Proxmox "freya"), Endpoint ${ENDPOINT_IP}:3306
# Autor: Giovanni Merola  (generiert durch setup_cloud_selfhosted.sh)
# ============================================================
[mysqld]
# --- Netz: LAN-Zugriff, aber NUR verschluesselt --------------
bind-address              = 0.0.0.0
require_secure_transport  = ON
ssl-ca                    = ${CERTDIR}/ca.pem
ssl-cert                  = ${CERTDIR}/server-cert.pem
ssl-key                   = ${CERTDIR}/server-key.pem

# --- Zeichensatz (wie lokal, verhindert Migrations-Drift) ----
character-set-server      = utf8mb4
collation-server          = utf8mb4_unicode_ci

# --- Haertung / Betrieb --------------------------------------
skip-name-resolve         = 1
max_connections           = 50
wait_timeout              = 600
interactive_timeout       = 600
local-infile              = 0

# --- Beobachtbarkeit -----------------------------------------
slow_query_log            = 1
slow_query_log_file       = ${LOGDIR}/slow.log
long_query_time           = 2
log_error                 = ${LOGDIR}/error.log

# --- InnoDB ---------------------------------------------------
innodb_buffer_pool_size        = 512M
innodb_flush_log_at_trx_commit = 1
CNF
info "geschrieben: $CONF"

# ---- MariaDB starten + Bereitschaft abwarten -----------------------------
log "[4/6] MariaDB starten und Bereitschaft pruefen"
systemctl enable mariadb >/dev/null 2>&1 || true
systemctl restart mariadb || die "$LINENO" "MariaDB-Restart fehlgeschlagen - siehe ${LOGDIR}/error.log"
ready=0
for ((i=0; i<30; i++)); do
  if mysqladmin ping >/dev/null 2>&1; then ready=1; break; fi
  sleep 1
done
[ "$ready" -eq 1 ] || die "$LINENO" "MariaDB nicht bereit nach 30s (TLS-Zertifikat pruefen: ${LOGDIR}/error.log)"
info "MariaDB aktiv und erreichbar"

# ---- Admin-User fuer Migration (idempotent, REQUIRE SSL) -----------------
log "[5/6] Migrations-Admin-User (idempotent, REQUIRE SSL)"
mysql <<SQL || die "$LINENO" "Anlegen/Aktualisieren von giovanni_admin fehlgeschlagen"
CREATE USER IF NOT EXISTS 'giovanni_admin'@'%' IDENTIFIED BY '${CLOUD_ADMIN_PWD}';
ALTER USER 'giovanni_admin'@'%' IDENTIFIED BY '${CLOUD_ADMIN_PWD}' REQUIRE SSL;
GRANT ALL PRIVILEGES ON *.* TO 'giovanni_admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
mysql -N -e "SELECT CONCAT('  ', User,'@',Host,'  ssl_type=', ssl_type) FROM mysql.user WHERE User LIKE 'giovanni%';"

# ---- Verifikation: TLS wirklich erzwungen? -------------------------------
log "[6/6] Verifikation der TLS-Pflicht"
rst="$(mysql -N -e "SELECT @@require_secure_transport;")"
[ "$rst" = "1" ] || die "$LINENO" "require_secure_transport ist NICHT aktiv (=$rst)"
info "require_secure_transport = ON  (verifiziert)"
mysql -e "SHOW VARIABLES WHERE Variable_name IN ('have_ssl','version','character_set_server','collation_server');"

printf '\n\033[1;32m### Cloud-Setup FERTIG - Endpoint %s:3306 (TLS erzwungen) ###\033[0m\n' "$ENDPOINT_IP"
info "Naechster Schritt: sql/migration/migrate_local_to_selfhosted.sh"
