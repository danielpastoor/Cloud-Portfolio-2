#!/bin/bash
# ============================================================
#  maak-vms.sh - Maakt 3 Ubuntu 24.04 VM's aan in Proxmox
# ============================================================

STORAGE="local-lvm"        # Proxmox storage naam (check met: pvesm status)
BRIDGE="vmbr0"             # Netwerk bridge (check met: ip link)
NODE=$(hostname)           # Proxmox node naam

VM_IPS=("10.24.39.40" "10.24.39.41" "10.24.39.42")
GATEWAY="10.24.39.1"
DNS="8.8.8.8"

CORES=1
RAM=1024                   # MB
DISK=20                    # GB
VM_USER="ubuntu"
VM_PASS="Welkom01"

VM_IDS=(101 102 103)
VM_NAMES=("docker-node1" "docker-node2" "docker-node3")

IMG_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMG_FILE="/tmp/ubuntu-24.04-cloud.img"
SNIPPETS_DIR="/var/lib/vz/snippets"
USERDATA_FILE="$SNIPPETS_DIR/ssh-enable.yml"

# ─────────────────────────────────────────────────────────────

set -e

echo "============================================="
echo "  Proxmox VM Setup - 3x Ubuntu 24.04"
echo "============================================="
echo ""

mkdir -p "$SNIPPETS_DIR"

echo "Cloud-init user-data aanmaken..."
cat <<EOF > "$USERDATA_FILE"
#cloud-config
ssh_pwauth: true
package_update: false
chpasswd:
  list: |
    $VM_USER:$VM_PASS
  expire: false
users:
  - name: $VM_USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
runcmd:
  - sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/^#*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
  - systemctl restart ssh
EOF
echo "User-data klaar: $USERDATA_FILE"

if [ ! -f "$IMG_FILE" ]; then
    echo "Ubuntu 24.04 cloud image downloaden..."
    wget -q --show-progress "$IMG_URL" -O "$IMG_FILE"
    echo "Download klaar"
else
    echo "Ubuntu image al aanwezig, downloaden overgeslagen"
fi

for i in 0 1 2; do
    VMID=${VM_IDS[$i]}
    VMNAME=${VM_NAMES[$i]}
    VMIP=${VM_IPS[$i]}

    echo ""
    echo "---------------------------------------------"
    echo "Aanmaken: $VMNAME (ID: $VMID, IP: $VMIP)"
    echo "---------------------------------------------"

    if qm status $VMID &>/dev/null; then
        echo "  VM $VMID bestaat al - wordt verwijderd en opnieuw aangemaakt"
        qm stop $VMID --skiplock 2>/dev/null || true
        sleep 2
        qm destroy $VMID --purge
    fi

    VM_IMG="/tmp/vm-${VMID}.img"
    cp "$IMG_FILE" "$VM_IMG"

    echo "  VM aanmaken..."
    qm create $VMID \
        --name "$VMNAME" \
        --memory $RAM \
        --cores $CORES \
        --net0 virtio,bridge=$BRIDGE \
        --ostype l26 \
        --agent enabled=1

    echo "  Schijf importeren..."
    qm importdisk $VMID "$VM_IMG" $STORAGE --format qcow2

    qm set $VMID \
        --scsihw virtio-scsi-pci \
        --scsi0 ${STORAGE}:vm-${VMID}-disk-0,discard=on \
        --boot c \
        --bootdisk scsi0

    echo "  Schijf vergroten naar ${DISK}GB..."
    qm resize $VMID scsi0 ${DISK}G

    qm set $VMID --ide2 ${STORAGE}:cloudinit

    echo "  Cloud-init configureren..."
    qm set $VMID \
        --ciuser "$VM_USER" \
        --cipassword "$VM_PASS" \
        --sshkeys ~/.ssh/authorized_keys 2>/dev/null || \
    qm set $VMID \
        --ciuser "$VM_USER" \
        --cipassword "$VM_PASS"

    qm set $VMID \
        --ipconfig0 ip=${VMIP}/24,gw=${GATEWAY} \
        --nameserver $DNS

    qm set $VMID --vga std

    qm set $VMID --cicustom "user=local:snippets/ssh-enable.yml"

    rm -f "$VM_IMG"

    echo "  $VMNAME aangemaakt"
done

echo ""
echo "============================================="
echo " Alle 3 VM's aangemaakt! Nu opstarten..."
echo "============================================="

for i in 0 1 2; do
    VMID=${VM_IDS[$i]}
    VMNAME=${VM_NAMES[$i]}
    echo "$VMNAME (ID: $VMID) opstarten..."
    qm start $VMID
    sleep 5
done

echo ""
echo "Alle VM's zijn opgestart!"
echo ""
echo "Wacht ~60 seconden en test dan de verbinding:"
echo ""
for i in 0 1 2; do
    echo "  ssh ubuntu@${VM_IPS[$i]}"
done
echo ""
echo "Standaard wachtwoord: $VM_PASS"
echo ""