#!/usr/bin/env bash
# ================================================================
# M141 LB3 - DEMO-PREFLIGHT / Health-Check  -  Giovanni Merola
#
# Ein Befehl, ~2 Minuten vor der Praesentation auf phoebe (Host)
# ausfuehren:   /root/preflight_demo.sh
#
# Prueft die eigene Cloud-DB (CT 9003, 192.168.1.62:3306) und
# heilt automatisch, was gefahrlos heilbar ist:
#   - CT gestoppt        -> pct start
#   - MariaDB inaktiv    -> systemctl start (im CT)
#   - CA-Datei fehlt     -> frisch aus dem CT ziehen
# Alles andere wird nur GEPRUEFT (nichts Destruktives, nur
# net-zero Schreibtests: INSERT+DELETE, CREATE+DROP tmp).
#
# STRIKT: fasst ausschliesslich CT 9003 an, keine anderen Gaeste.
# Am Ende: grosses GO / NO-GO.
# ================================================================
set -uo pipefail   # bewusst KEIN -e: wir sammeln Fehler statt abzubrechen

CTID=9003
HOST=192.168.1.62
PORT=3306
DB=backpacker_lb3_giovanni
CA=/root/cloud-ca-giovanni.pem
ADMIN_U=giovanni_admin;    ADMIN_P='CloudAdmin!Giovanni-2026'
BEN_U=giovanni_benutzer;   BEN_P='Cloud!Benutzer-Giovanni-2026'
MAN_U=giovanni_manager;    MAN_P='Cloud!Manager-Giovanni-2026'
DBA_U=giovanni_dba;        DBA_P='Cloud!Dba-Giovanni-2026'

PASS=0; FAIL=0; HEALED=0
ok()   { PASS=$((PASS+1));  printf '  \033[1;32m[PASS]\033[0m %s\n' "$*"; }
bad()  { FAIL=$((FAIL+1));  printf '  \033[1;31m[FAIL]\033[0m %s\n' "$*"; }
heal() { HEALED=$((HEALED+1)); printf '  \033[1;33m[HEAL]\033[0m %s\n' "$*"; }
hdr()  { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

TLS=(--ssl-verify-server-cert --ssl-ca="$CA")
q() { # q <user> <pass> [extra-args...] -e sql   (immer TLS, ohne Passwort-Warnung)
  local u=$1 p=$2; shift 2
  mysql -h "$HOST" -P "$PORT" -u "$u" "-p$p" "${TLS[@]}" "$@" 2>&1 | grep -vi "using a password"
}

# ---------------------------------------------------------------
hdr "0) Umgebung (phoebe-Host)"
command -v pct   >/dev/null 2>&1 && ok "pct vorhanden"   || bad "pct fehlt - laeuft das hier auf phoebe?"
command -v mysql >/dev/null 2>&1 && ok "mysql-Client vorhanden" || bad "mariadb-client fehlt (apt-get install mariadb-client)"

# ---------------------------------------------------------------
hdr "1) Container CT $CTID"
st=$(pct status "$CTID" 2>/dev/null | awk '{print $2}')
if [ "$st" = "running" ]; then
  ok "CT $CTID laeuft"
elif [ -z "$st" ]; then
  bad "CT $CTID existiert nicht (pct status leer) - Rollback/Neuaufbau noetig"
else
  heal "CT $CTID ist '$st' -> starte ..."
  pct start "$CTID" >/dev/null 2>&1
  for ((i=0;i<20;i++)); do [ "$(pct status "$CTID" | awk '{print $2}')" = running ] && break; sleep 1; done
  [ "$(pct status "$CTID" | awk '{print $2}')" = running ] && ok "CT $CTID gestartet" || bad "CT $CTID startet nicht"
fi

# ---------------------------------------------------------------
hdr "2) MariaDB-Dienst im CT"
if pct exec "$CTID" -- systemctl is-active --quiet mariadb 2>/dev/null; then
  ok "mariadb aktiv"
else
  heal "mariadb inaktiv -> starte ..."
  pct exec "$CTID" -- systemctl start mariadb >/dev/null 2>&1
  ready=0
  for ((i=0;i<20;i++)); do pct exec "$CTID" -- mysqladmin ping >/dev/null 2>&1 && { ready=1; break; }; sleep 1; done
  [ "$ready" = 1 ] && ok "mariadb gestartet + ping OK" || bad "mariadb startet nicht (error.log im CT pruefen)"
fi

# ---------------------------------------------------------------
hdr "3) CA-Zertifikat + TLS-Gueltigkeit"
if [ ! -f "$CA" ]; then
  heal "CA fehlt auf dem Host -> ziehe frisch aus CT ..."
  pct pull "$CTID" /etc/mysql/certs/ca.pem "$CA" >/dev/null 2>&1 \
    && ok "CA neu gezogen: $CA" || bad "CA konnte nicht gezogen werden"
fi
if [ -f "$CA" ]; then
  openssl x509 -in "$CA" -noout -checkend 86400 >/dev/null 2>&1 \
    && ok "CA gueltig (>24h): $(openssl x509 -in "$CA" -noout -subject | sed 's/subject=//')" \
    || bad "CA laeuft in <24h ab oder ist ungueltig"
fi
# Server-Zertifikat im CT (Ablauf + SAN)
if pct exec "$CTID" -- openssl x509 -in /etc/mysql/certs/server-cert.pem -noout -checkend 86400 >/dev/null 2>&1; then
  ok "Server-Zertifikat gueltig (>24h), SAN: $(pct exec "$CTID" -- openssl x509 -in /etc/mysql/certs/server-cert.pem -noout -ext subjectAltName 2>/dev/null | tail -1 | tr -d ' ')"
else
  bad "Server-Zertifikat abgelaufen/ungueltig"
fi

# ---------------------------------------------------------------
hdr "4) Endpoint + TLS-Session"
if timeout 3 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
  ok "TCP $HOST:$PORT erreichbar"
else
  bad "TCP $HOST:$PORT NICHT erreichbar (Firewall-Allowlist? Quell-IP?)"
fi
vtls=$(q "$ADMIN_U" "$ADMIN_P" -N -e "SHOW STATUS LIKE 'Ssl_version';" | awk '{print $2}')
case "$vtls" in
  TLSv1.3|TLSv1.2) ok "TLS-Session aktiv ($vtls, CA verifiziert)" ;;
  *)               bad "keine TLS-Session als $ADMIN_U (bekommen: '${vtls:-nichts}')" ;;
esac
rst=$(q "$ADMIN_U" "$ADMIN_P" -N -e "SELECT @@require_secure_transport;")
[ "$rst" = "1" ] && ok "require_secure_transport = ON" || bad "require_secure_transport NICHT aktiv (=$rst)"
# Negativ: Klartext muss abgewiesen werden
noTLS=$(mysql -h "$HOST" -P "$PORT" -u "$DBA_U" "-p$DBA_P" --skip-ssl -e "SELECT 1;" 2>&1)
echo "$noTLS" | grep -q "3159\|insecure transport" \
  && ok "Klartext-Login korrekt abgewiesen (ERROR 3159)" \
  || bad "Klartext-Login wurde NICHT abgewiesen!"

# ---------------------------------------------------------------
hdr "5) Die 3 Demo-User authentifizieren (TLS)"
for spec in "$BEN_U|$BEN_P|role_benutzer" "$MAN_U|$MAN_P|role_management" "$DBA_U|$DBA_P|-"; do
  u=${spec%%|*}; rest=${spec#*|}; p=${rest%%|*}; want_role=${rest#*|}
  got=$(q "$u" "$p" -N "$DB" -e "SELECT CONCAT(CURRENT_USER(),' ',IFNULL(CURRENT_ROLE(),'NONE'));")
  if echo "$got" | grep -q "^${u}@"; then
    if [ "$want_role" = "-" ] || echo "$got" | grep -q "$want_role"; then
      ok "$u login OK ($got)"
    else
      bad "$u login OK, aber Rolle falsch: $got (erwartet $want_role)"
    fi
  else
    bad "$u Login fehlgeschlagen: $got"
  fi
done

# ---------------------------------------------------------------
hdr "6) Repraesentative DCL/DDL/DML-Checks (alle net-zero)"
# 6a DQL: Zeilenzahlen exakt
counts=$(q "$ADMIN_U" "$ADMIN_P" -N "$DB" -e \
  "SELECT CONCAT((SELECT COUNT(*) FROM tbl_personen),'/',(SELECT COUNT(*) FROM tbl_benutzer),'/',(SELECT COUNT(*) FROM tbl_land),'/',(SELECT COUNT(*) FROM tbl_leistung),'/',(SELECT COUNT(*) FROM tbl_buchung),'/',(SELECT COUNT(*) FROM tbl_positionen));")
[ "$counts" = "2036/11/82/8/1006/1746" ] \
  && ok "Zeilenzahlen exakt: $counts" \
  || bad "Zeilenzahlen abweichend: $counts (erwartet 2036/11/82/8/1006/1746) -> ggf. Rollback auf Snapshot 'golden-db-ready'"
# 6b FK-Anzahl
fk=$(q "$ADMIN_U" "$ADMIN_P" -N "$DB" -e "SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='$DB';")
[ "$fk" = "5" ] && ok "5 FK-Constraints aktiv" || bad "FK-Anzahl=$fk (erwartet 5)"
# 6c DML positiv als Benutzer: INSERT+UPDATE+DELETE tbl_buchung (net-zero)
dml=$(q "$BEN_U" "$BEN_P" "$DB" -e "INSERT INTO tbl_buchung (Personen_FS,Ankunft,Abreise,Land_FS) VALUES (1,NOW(),NOW()+INTERVAL 1 DAY,1); SET @b:=LAST_INSERT_ID(); UPDATE tbl_buchung SET Abreise=NOW()+INTERVAL 2 DAY WHERE Buchungs_ID=@b; DELETE FROM tbl_buchung WHERE Buchungs_ID=@b; SELECT 'dml-ok';")
echo "$dml" | grep -q "dml-ok" && ok "DML benutzer: INSERT+UPDATE+DELETE tbl_buchung OK (net-zero)" || bad "DML-Test benutzer fehlgeschlagen: $dml"
# 6d DCL negativ als Benutzer: DELETE personen -> 1142, SELECT Password -> 1143
n1=$(q "$BEN_U" "$BEN_P" "$DB" -e "DELETE FROM tbl_personen WHERE Personen_ID=1;")
echo "$n1" | grep -q "1142" && ok "DCL: DELETE tbl_personen als benutzer korrekt verweigert (1142)" || bad "DCL-Verstoss: DELETE wurde nicht verweigert: $n1"
n2=$(q "$BEN_U" "$BEN_P" "$DB" -e "SELECT Password FROM tbl_benutzer LIMIT 1;")
echo "$n2" | grep -q "1143" && ok "DCL: SELECT Password korrekt verweigert (1143)" || bad "DCL-Verstoss: Password lesbar: $n2"
# 6e DCL negativ als Manager: INSERT buchung -> 1142
n3=$(q "$MAN_U" "$MAN_P" "$DB" -e "INSERT INTO tbl_buchung (Personen_FS,Ankunft,Abreise,Land_FS) VALUES (1,NOW(),NOW(),1);")
echo "$n3" | grep -q "1142" && ok "DCL: INSERT tbl_buchung als manager korrekt verweigert (1142)" || bad "DCL-Verstoss: manager darf INSERT buchung: $n3"
# 6f DDL als DBA: CREATE + DROP Tmp-Tabelle (net-zero)
ddl=$(q "$DBA_U" "$DBA_P" "$DB" -e "CREATE TABLE IF NOT EXISTS preflight_tmp_giovanni (id INT PRIMARY KEY); DROP TABLE preflight_tmp_giovanni; SELECT 'ddl-ok';")
echo "$ddl" | grep -q "ddl-ok" && ok "DDL dba: CREATE+DROP Tabelle OK (net-zero)" || bad "DDL-Test dba fehlgeschlagen: $ddl"
# 6g Migrations-Testdatensatz vorhanden
gt=$(q "$ADMIN_U" "$ADMIN_P" -N "$DB" -e "SELECT COUNT(*) FROM tbl_personen WHERE Name='Giovanni-Test';")
[ "${gt:-0}" -ge 1 ] && ok "Migrations-Testdatensatz 'Giovanni-Test' vorhanden ($gt)" || bad "'Giovanni-Test' fehlt!"

# ---------------------------------------------------------------
printf '\n'
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;42;30m  ██  GO  ██  Demo-Umgebung bereit: %d Checks PASS, %d auto-geheilt, 0 FAIL  \033[0m\n' "$PASS" "$HEALED"
  exit 0
else
  printf '\033[1;41;97m  ██ NO-GO ██  %d FAIL / %d PASS (%d geheilt) - Details oben.  \033[0m\n' "$FAIL" "$PASS" "$HEALED"
  printf 'Schnellste Rettung bei Daten-Problemen: pct rollback %s golden-db-ready && pct start %s\n' "$CTID" "$CTID"
  exit 1
fi
