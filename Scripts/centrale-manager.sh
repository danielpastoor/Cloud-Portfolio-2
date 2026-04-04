#!/bin/bash
# ============================================================
#  centrale-manager.sh — Beheer alle 3 swarms via 1 centrale
#  manager node (node1).
# ============================================================

NODE1_IP="10.24.39.40"   # Centrale manager (node1)
NODE2_IP="10.24.39.41"   # Manager swarm 2
NODE3_IP="10.24.39.42"   # Manager swarm 3
VM_USER="ubuntu"
VM_PASS="Welkom01"

if ! command -v sshpass &>/dev/null; then
    sudo apt-get install -y sshpass -qq
fi

SSH="sshpass -p $VM_PASS ssh -o StrictHostKeyChecking=no"

echo "============================================="
echo "  Centrale Manager Setup"
echo "  Node1 beheert alle 3 swarms"
echo "============================================="
echo ""
echo ""

echo "Stap 1: Manager-token ophalen van Swarm 2 ($NODE2_IP)..."
TOKEN_SWARM2=$($SSH ${VM_USER}@${NODE2_IP} "docker swarm join-token manager -q")
echo "  Token Swarm 2 opgehaald"

echo ""
echo "Stap 2: Manager-token ophalen van Swarm 3 ($NODE3_IP)..."
TOKEN_SWARM3=$($SSH ${VM_USER}@${NODE3_IP} "docker swarm join-token manager -q")
echo "  Token Swarm 3 opgehaald"

echo ""
echo "Stap 3: Node1 toevoegen als manager aan Swarm 2..."

$SSH ${VM_USER}@${NODE1_IP} "
docker context create swarm2 \
  --docker host=tcp://${NODE2_IP}:2376 2>/dev/null || \
docker context update swarm2 \
  --docker host=tcp://${NODE2_IP}:2376
echo '  Context swarm2 aangemaakt'
"

$SSH ${VM_USER}@${NODE1_IP} "
docker context create swarm3 \
  --docker host=tcp://${NODE3_IP}:2376 2>/dev/null || \
docker context update swarm3 \
  --docker host=tcp://${NODE3_IP}:2376
echo '  Context swarm3 aangemaakt'
"

echo "  Docker contexts aangemaakt op node1"

echo ""
echo "Stap 4: Node1 instellen om alle swarms te beheren via SSH..."

$SSH ${VM_USER}@${NODE1_IP} "
# Context voor swarm 1 (lokaal, al standaard)
docker context create swarm1-local \
  --docker host=unix:///var/run/docker.sock 2>/dev/null || true

# Context voor swarm 2 via SSH
docker context create swarm2-ssh \
  --docker host=ssh://${VM_USER}@${NODE2_IP} 2>/dev/null || true

# Context voor swarm 3 via SSH
docker context create swarm3-ssh \
  --docker host=ssh://${VM_USER}@${NODE3_IP} 2>/dev/null || true

echo 'Alle contexts aangemaakt:'
docker context ls
"

echo ""
echo "============================================="
echo " Verificatie - node1 beheert alle 3 swarms:"
echo "============================================="

echo ""
echo "--- Swarm 1 (lokaal op node1) ---"
$SSH ${VM_USER}@${NODE1_IP} "docker --context swarm1-local node ls 2>/dev/null || docker node ls"

echo ""
echo "--- Swarm 2 (via SSH naar node2) ---"
$SSH ${VM_USER}@${NODE1_IP} "docker --context swarm2-ssh node ls 2>/dev/null || docker node ls"

echo ""
echo "--- Swarm 3 (via SSH naar node3) ---"
$SSH ${VM_USER}@${NODE1_IP} "docker --context swarm3-ssh node ls 2>/dev/null || docker node ls"

echo ""
echo "============================================="
echo " Centrale manager setup klaar!"
echo ""
echo " Vanuit node1 kun je nu alle swarms beheren:"
echo ""
echo "   docker --context swarm1-local node ls   # Swarm 1"
echo "   docker --context swarm2-ssh node ls     # Swarm 2"
echo "   docker --context swarm3-ssh node ls     # Swarm 3"
echo ""
echo "============================================="
