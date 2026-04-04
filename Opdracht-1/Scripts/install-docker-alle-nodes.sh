#!/bin/bash
# ============================================================
#  install-docker-alle-nodes.sh
#  Installeert Docker op alle 3 VM's via SSH
# ============================================================

VM_IPS=("10.24.39.40" "10.24.39.41" "10.24.39.42")
VM_NAMES=("docker-node1" "docker-node2" "docker-node3")
VM_USER="ubuntu"
VM_PASS="Welkom01"

DOCKER_INSTALL='
set -e
echo "-- Systeem updaten --"
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

echo "-- Docker installeren --"
curl -fsSL https://get.docker.com | sudo sh

echo "-- Gebruiker toevoegen aan docker groep --"
sudo usermod -aG docker $USER

echo "-- Docker Compose controleren --"
docker compose version

echo "-- Test: hello-world --"
sudo docker run hello-world

echo "Docker installatie klaar op $(hostname)"
docker --version
'

echo "============================================="
echo "  Docker installeren op 3 nodes"
echo "============================================="
echo ""
echo "Let op: Zorg dat sshpass geinstalleerd is:"
echo "   apt-get install -y sshpass"
echo ""

if ! command -v sshpass &>/dev/null; then
    apt-get install -y sshpass -qq
fi

for i in 0 1 2; do
    IP=${VM_IPS[$i]}
    NAME=${VM_NAMES[$i]}

    echo "---------------------------------------------"
    echo "Docker installeren op $NAME ($IP)"
    echo "---------------------------------------------"

    sshpass -p "$VM_PASS" ssh \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        ${VM_USER}@${IP} "$DOCKER_INSTALL"

    if [ $? -eq 0 ]; then
        echo "  $NAME klaar"
    else
        echo "  Fout bij $NAME - controleer of de VM bereikbaar is"
    fi
    echo ""
done

echo "============================================="
echo " Docker is geinstalleerd op alle 3 nodes!"
echo ""
echo " Verificatie - voer dit uit om te controleren:"
for i in 0 1 2; do
    echo "  ssh ubuntu@${VM_IPS[$i]} 'docker --version'"
done
echo "============================================="
