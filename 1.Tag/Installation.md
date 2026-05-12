# Installation

Statt XAMPP auf Windows hab ich MariaDB direkt auf einer Ubuntu-VM in Proxmox aufgesetzt. Realistischer (wie auf einem echten Server) und nichts blockiert mir den Windows-Host.

## Setup

| | |
|---|---|
| Hypervisor | Proxmox VE 9 auf phoebe (192.168.4.30) |
| VMID / Name | **4142** / `m141-db-01` |
| OS | Ubuntu Server 24.04 LTS (cloud image) |
| CPU / RAM / Disk | 2 vCPU / 4 GiB / 32 GiB (ssd-pool) |
| Netz | vmbr0, statisch **192.168.4.142/24**, GW 192.168.4.1, DNS 192.168.4.1 |
| MariaDB | 10.11.14 |
| Web-Admin | phpMyAdmin auf Apache 2.4 + PHP 8.3 |

## Wie ich's gemacht hab

Erst habe ich's mit dem normalen Ubuntu-Server-Installer (Subiquity) über die noVNC-Konsole versucht — Tastatureingabe war shit, hat Zeichen verschluckt, vor allem im Network-Step. Hab dann auf cloud-init umgestellt: das Ubuntu-Cloud-Image direkt importieren und die Config über `qm` setzen.

In der Proxmox-Shell auf phoebe als root:

```bash
# VM-Hülle bauen
qm create 4142 \
  --name m141-db-01 \
  --memory 4096 --cores 2 --cpu x86-64-v2-AES \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket --vga serial0 \
  --scsihw virtio-scsi-single --ostype l26 --agent 1

# Cloud-Image als Disk importieren
qm importdisk 4142 \
  /ssd-pool/local/template/iso/ubuntu-24.04-cloud-amd64.img \
  ssd-pool

# Disk + cloud-init drive anhängen, Boot-Order setzen
qm set 4142 --scsi0 ssd-pool:vm-4142-disk-0,iothread=1,discard=on
qm resize 4142 scsi0 32G
qm set 4142 --ide2 ssd-pool:cloudinit
qm set 4142 --boot order=scsi0

# cloud-init: User, Passwort, IP, DNS, SSH-Key
qm set 4142 --ciuser sysadmin --cipassword m141
qm set 4142 --ipconfig0 ip=192.168.4.142/24,gw=192.168.4.1
qm set 4142 --nameserver 192.168.4.1 --searchdomain local
qm set 4142 --sshkey /root/.ssh/id_rsa.pub

qm start 4142
```

Nach ~30 Sekunden boot war die VM per SSH erreichbar.

## Pakete

```bash
ssh sysadmin@192.168.4.142

sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  mariadb-server mariadb-client qemu-guest-agent vim curl \
  apache2 php php-mysqli php-mbstring php-zip php-gd php-curl php-xml

# phpMyAdmin braucht debconf-preseeds sonst hängt's
echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | sudo debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin
```

MariaDB auf alle Interfaces binden, sonst kommt DB Pro vom Windows-Host nicht ran:

```bash
sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' \
     /etc/mysql/mariadb.conf.d/50-server.cnf
sudo systemctl restart mariadb
```

Check: `sudo ss -tlnp | grep 3306` → `LISTEN 0.0.0.0:3306 mariadbd`. ✓

## DB-User `gigi`

```sql
CREATE USER 'gigi'@'localhost' IDENTIFIED BY 'm141';
CREATE USER 'gigi'@'%'         IDENTIFIED BY 'm141';
GRANT ALL PRIVILEGES ON *.* TO 'gigi'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'gigi'@'%'         WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

`SELECT user,host FROM mysql.user;` zeigt jetzt `gigi@%`, `gigi@localhost` + die Standard-Systemuser.

## Root-SSH aktiviert, sysadmin wieder weg

Weil die VM eh nur temporär ist und ich nur einen User (root) drauf will:

```bash
echo root:m141 | sudo chpasswd
sudo mkdir -p /root/.ssh && sudo chmod 700 /root/.ssh
sudo cp /home/sysadmin/.ssh/authorized_keys /root/.ssh/
sudo chmod 600 /root/.ssh/authorized_keys

# cloud-init schreibt PasswordAuth/PermitRootLogin in conf.d-Files, die killen
sudo rm -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf \
           /etc/ssh/sshd_config.d/50-cloud-init.conf

# in /etc/ssh/sshd_config selber appenden
printf "\nPermitRootLogin yes\nPasswordAuthentication yes\n" \
  | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart ssh

sudo deluser --remove-home sysadmin
sudo rm -f /etc/sudoers.d/90-cloud-init-users
```

> ⚠️ Schwaches Passwort + root-SSH ist nur OK weil die VM (a) im LAN ist und (b) temporär. Im Prod nie so machen.

## Test

```bash
ssh root@192.168.4.142 'systemctl is-active mariadb apache2 ssh'
# active
# active
# active

curl -s -o /dev/null -w "%{http_code}\n" http://192.168.4.142/phpmyadmin/
# 200
```

## Wie der Windows-Host drauf zugreift

| Was | Wie |
|---|---|
| SSH | `ssh root@192.168.4.142` (PW `m141` oder Key) |
| MariaDB von DB Pro | Host `192.168.4.142`, Port `3306`, User `gigi`, PW `m141` |
| phpMyAdmin | http://192.168.4.142/phpmyadmin/ |

## Was ich gelernt hab

- Subiquity über noVNC = nope. Cloud-Image + cloud-init ist deutlich entspannter und reproduzierbar.
- Cloud-Image hat `eth0`, nicht `ens18` wie beim normalen Installer.
- Standardmässig akzeptiert das Cloud-Image **keine** Passwort-Logins via SSH — muss man explizit aktivieren (oder einfach SSH-Key reinwerfen).
- phpMyAdmin will im Install interaktive Antworten (Webserver, dbconfig) → debconf-set-selections vorab oder es bleibt hängen.
