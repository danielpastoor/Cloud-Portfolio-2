#!/bin/bash
# ============================================================
#  swarm-setup.sh — Maakt 3 APARTE Docker Swarms
#  Elke node is manager van zijn eigen swarm
# ============================================================

NODE1_IP="10.24.39.40"   # Manager van Swarm 1
NODE2_IP="10.24.39.41"   # Manager van Swarm 2
NODE3_IP="10.24.39.42"   # Manager van Swarm 3
VM_USER="ubuntu"
VM_PASS="Welkom01"
# ─────────────────────────────────────────────────────────────

if ! command -v sshpass &>/dev/null; then
    apt-get install -y sshpass -qq
fi

SSH="sshpass -p $VM_PASS ssh -o StrictHostKeyChecking=no"

echo "============================================="
echo "  Docker Swarm Setup - 3 aparte swarms"
echo "  Elke node = manager van zijn eigen swarm"
echo "============================================="
echo ""

echo "Stap 1: Bestaande swarms resetten (indien aanwezig)..."
for IP in $NODE1_IP $NODE2_IP $NODE3_IP; do
    $SSH ${VM_USER}@${IP} "docker swarm leave --force 2>/dev/null || true"
    echo "  $IP gereset"
done
sleep 2

echo ""
echo "---------------------------------------------"
echo "Swarm 1 initialiseren op docker-node1 ($NODE1_IP)"
echo "---------------------------------------------"
$SSH ${VM_USER}@${NODE1_IP} "docker swarm init --advertise-addr $NODE1_IP"
echo "  Swarm 1 klaar — node1 is manager"

echo ""
echo "---------------------------------------------"
echo "Swarm 2 initialiseren op docker-node2 ($NODE2_IP)"
echo "---------------------------------------------"
$SSH ${VM_USER}@${NODE2_IP} "docker swarm init --advertise-addr $NODE2_IP"
echo "  Swarm 2 klaar — node2 is manager"

echo ""
echo "---------------------------------------------"
echo "Swarm 3 initialiseren op docker-node3 ($NODE3_IP)"
echo "---------------------------------------------"
$SSH ${VM_USER}@${NODE3_IP} "docker swarm init --advertise-addr $NODE3_IP"
echo "  Swarm 3 klaar — node3 is manager"

echo ""
echo "============================================="
echo " Verificatie - status van alle 3 swarms:"
echo "============================================="

echo ""
echo "--- Swarm 1 (docker-node1 / $NODE1_IP) ---"
$SSH ${VM_USER}@${NODE1_IP} "docker node ls"

echo ""
echo "--- Swarm 2 (docker-node2 / $NODE2_IP) ---"
$SSH ${VM_USER}@${NODE2_IP} "docker node ls"

echo ""
echo "--- Swarm 3 (docker-node3 / $NODE3_IP) ---"
$SSH ${VM_USER}@${NODE3_IP} "docker node ls"

echo ""
echo "============================================="
echo " Alle 3 swarms zijn klaar!"
echo ""
echo " Swarm 1 - Manager: docker-node1 ($NODE1_IP)"
echo " Swarm 2 - Manager: docker-node2 ($NODE2_IP)"
echo " Swarm 3 - Manager: docker-node3 ($NODE3_IP)"
echo ""
echo " Maak screenshots van de 3x 'docker node ls' uitvoer"
echo "============================================="
echo ""
echo " VOLGENDE STAP (extra punt):"
echo " Voer centrale-manager.sh uit om alle swarms"
echo " via een centrale manager te beheren."
echo "============================================="
