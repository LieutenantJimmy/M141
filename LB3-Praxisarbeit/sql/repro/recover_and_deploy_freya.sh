#!/usr/bin/env bash
# ================================================================
# M141 LB3 - Recovery + Deploy Orchestrator (laeuft auf HOST "freya")
#
# Baked-in Recovery-Reihenfolge nach dem freya-Ausfall vom 02.07.2026:
#   Der VERDACHTETE Ausloeser war das Aktivieren der Proxmox-Datacenter-
#   Firewall (cluster.fw enable:1) + `pve-firewall restart`. Deshalb MUSS
#   die Wiederherstellung ZWINGEND mit `pve-firewall stop` beginnen,
#   BEVOR irgendetwas anderes passiert - sonst droht erneuter Aussperr.
#
# Reihenfolge:
#   0) pve-firewall stop            <-- ZUERST, immer
#   1) CT 9002 pruefen/starten
#   2) Setup-Script in den CT pushen + ausfuehren
#   3) (optional) Migration anstossen
#
# Nutzung auf freya:
#   ./recover_and_deploy_freya.sh            # Recovery + Setup
#   ./recover_and_deploy_freya.sh --migrate  # zusaetzlich Migration
# ================================================================
set -Eeuo pipefail

CTID=9002
SETUP_LOCAL="$(dirname "$0")/setup_cloud_selfhosted.sh"
SETUP_INCT="/root/setup_cloud_selfhosted.sh"
DO_MIGRATE=0
[ "${1:-}" = "--migrate" ] && DO_MIGRATE=1

log()  { printf '\n\033[1;36m### %s ###\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf '\n\033[1;31mFEHLER (Zeile %s): %s\033[0m\n' "${1:-?}" "${2:-abgebrochen}" >&2; exit 1; }
trap 'die "$LINENO" "unerwarteter Fehler"' ERR

# ---- Preflight: wirklich auf einem PVE-Host? -----------------------------
log "[0/4] Preflight"
[ "$(id -u)" -eq 0 ] || die "$LINENO" "muss als root auf dem freya-Host laufen"
command -v pve-firewall >/dev/null 2>&1 || die "$LINENO" "pve-firewall fehlt - nicht auf einem Proxmox-Host?"
command -v pct >/dev/null 2>&1 || die "$LINENO" "pct fehlt - nicht auf einem Proxmox-Host?"

# ---- SCHRITT 0: Firewall stoppen (ZUERST!) -------------------------------
log "[1/4] pve-firewall stop  (ZUERST - verhindert erneuten Aussperr)"
pve-firewall stop || info "pve-firewall stop meldete Fehler - trotzdem fortfahren (evtl. schon gestoppt)"
# Datacenter-Firewall dauerhaft entschaerfen, damit ein Reboot nicht erneut sperrt:
if [ -f /etc/pve/firewall/cluster.fw ]; then
  sed -i 's/^\(\s*enable:\s*\)1/\10/' /etc/pve/firewall/cluster.fw || true
  info "cluster.fw enable auf 0 gesetzt (bei Bedarf spaeter kontrolliert reaktivieren)"
fi
info "Firewall-Status: $(pve-firewall status 2>&1 | head -1)"

# ---- SCHRITT 1: CT pruefen/starten ---------------------------------------
log "[2/4] Container ${CTID} pruefen"
pct status "$CTID" >/dev/null 2>&1 || die "$LINENO" "CT ${CTID} existiert nicht"
if pct status "$CTID" | grep -q running; then
  info "CT ${CTID} laeuft bereits"
else
  info "starte CT ${CTID} ..."; pct start "$CTID"
  for ((i=0; i<20; i++)); do pct status "$CTID" | grep -q running && break; sleep 1; done
fi
pct status "$CTID" | grep -q running || die "$LINENO" "CT ${CTID} startet nicht"

# ---- SCHRITT 2: Setup in den CT bringen + ausfuehren ---------------------
log "[3/4] Setup im Container ausfuehren"
[ -f "$SETUP_LOCAL" ] || die "$LINENO" "Setup-Script nicht gefunden: $SETUP_LOCAL"
pct push "$CTID" "$SETUP_LOCAL" "$SETUP_INCT" --perms 755
pct exec "$CTID" -- bash "$SETUP_INCT" || die "$LINENO" "Setup im CT fehlgeschlagen"

# ---- SCHRITT 3: optional Migration ---------------------------------------
if [ "$DO_MIGRATE" -eq 1 ]; then
  log "[4/4] Migration anstossen (Hinweis)"
  info "Migration laeuft von der Quell-DB aus, nicht vom Host:"
  info "  export CLOUD_ADMIN_PWD='CloudAdmin!Giovanni-2026'"
  info "  sql/migration/migrate_local_to_selfhosted.sh"
else
  log "[4/4] Fertig"
  info "Setup abgeschlossen. Migration separat starten (siehe migrate_local_to_selfhosted.sh)."
fi
printf '\n\033[1;32m### Recovery + Deploy abgeschlossen ###\033[0m\n'
