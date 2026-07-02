#!/usr/bin/env bash
# ================================================================
# M141 LB3 - Setup "eigene Cloud-DB" (CT cloud-db-giovanni)
# MariaDB + erzwungenes TLS + Haertung - Giovanni Merola
# ================================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "### [1/4] MariaDB installieren ###"
apt-get update -qq
apt-get install -y -qq --no-install-recommends mariadb-server mariadb-client openssl >/dev/null
mariadb --version

echo "### [2/4] TLS: eigene CA + Server-Zertifikat ###"
CERTDIR=/etc/mysql/certs
mkdir -p $CERTDIR
cd $CERTDIR
if [ ! -f ca.pem ]; then
  # CA (personalisiert)
  openssl genrsa -out ca-key.pem 4096 2>/dev/null
  openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out ca.pem \
    -subj "/C=CH/L=Zuerich/O=GioTech Homelab/OU=M141 LB3/CN=Giovanni-Merola-Cloud-CA" 2>/dev/null
  # Server-Cert mit SAN (IP + Hostname)
  openssl genrsa -out server-key.pem 4096 2>/dev/null
  openssl req -new -key server-key.pem -out server.csr \
    -subj "/C=CH/L=Zuerich/O=GioTech Homelab/OU=M141 LB3/CN=cloud-db-giovanni" 2>/dev/null
  cat > san.cnf <<SAN
subjectAltName = IP:192.168.1.62, DNS:cloud-db-giovanni
SAN
  openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
    -out server-cert.pem -days 825 -extfile san.cnf 2>/dev/null
  rm -f server.csr san.cnf
fi
chown mysql:mysql $CERTDIR/*.pem
chmod 600 $CERTDIR/server-key.pem $CERTDIR/ca-key.pem
openssl x509 -in ca.pem -noout -subject -enddate
openssl x509 -in server-cert.pem -noout -subject -ext subjectAltName

echo "### [3/4] Haertungs-Konfiguration (my.cnf) ###"
cat > /etc/mysql/mariadb.conf.d/99-cloud-giovanni.cnf <<'CNF'
# ============================================================
# M141 LB3 - "Eigene Cloud" prod. Konfiguration
# Server: cloud-db-giovanni (LXC auf Proxmox "freya")
# Autor: Giovanni Merola - 02.07.2026
# ============================================================
[mysqld]
# --- Netz: LAN-Zugriff, aber NUR verschluesselt --------------
bind-address              = 0.0.0.0
require_secure_transport  = ON
ssl-ca                    = /etc/mysql/certs/ca.pem
ssl-cert                  = /etc/mysql/certs/server-cert.pem
ssl-key                   = /etc/mysql/certs/server-key.pem

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
slow_query_log_file       = /var/log/mysql/slow.log
long_query_time           = 2
log_error                 = /var/log/mysql/error.log

# --- InnoDB ---------------------------------------------------
innodb_buffer_pool_size   = 512M
innodb_flush_log_at_trx_commit = 1
CNF
mkdir -p /var/log/mysql && chown mysql:mysql /var/log/mysql
systemctl restart mariadb
systemctl is-active mariadb

echo "### [4/4] Admin-User fuer Migration (REQUIRE SSL) ###"
mysql -e "
CREATE USER IF NOT EXISTS 'giovanni_admin'@'%' IDENTIFIED BY 'CloudAdmin!Giovanni-2026' REQUIRE SSL;
GRANT ALL PRIVILEGES ON *.* TO 'giovanni_admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SELECT User, Host, ssl_type FROM mysql.user WHERE User LIKE 'giovanni%';
"
echo "### Cloud-Setup FERTIG ###"
mysql -e "SHOW VARIABLES WHERE Variable_name IN ('require_secure_transport','have_ssl','version');"
