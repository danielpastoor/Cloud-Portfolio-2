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

echo "Stap 1: SSH key aanmaken op node1..."
$SSH ${VM_USER}@${NODE1_IP} "
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -q
    echo '  SSH key aangemaakt'
else
    echo '  SSH key al aanwezig'
fi
"
PUBKEY=$($SSH ${VM_USER}@${NODE1_IP} "cat ~/.ssh/id_ed25519.pub")
echo "  Publieke sleutel opgehaald"

echo ""
echo "Stap 2: SSH key toevoegen aan node2 en node3..."
$SSH ${VM_USER}@${NODE2_IP} "mkdir -p ~/.ssh && echo \"$PUBKEY\" >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys"
echo "  Key toegevoegd aan node2"
$SSH ${VM_USER}@${NODE3_IP} "mkdir -p ~/.ssh && echo \"$PUBKEY\" >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys"
echo "  Key toegevoegd aan node3"

echo ""
echo "Stap 3: Docker contexts aanmaken op node1..."
$SSH ${VM_USER}@${NODE1_IP} "
docker context rm swarm1-local swarm2-ssh swarm3-ssh 2>/dev/null || true

docker context create swarm1-local \
    --docker host=unix:///var/run/docker.sock
docker context create swarm2-ssh \
    --docker host=ssh://${VM_USER}@${NODE2_IP}
docker context create swarm3-ssh \
    --docker host=ssh://${VM_USER}@${NODE3_IP}

echo 'Contexts aangemaakt:'
docker context ls
"
echo "  Docker contexts aangemaakt op node1"

echo ""
echo "============================================="
echo " Verificatie - node1 beheert alle 3 swarms:"
echo "============================================="

echo ""
echo "--- Swarm 1 (lokaal op node1) ---"
$SSH ${VM_USER}@${NODE1_IP} "docker --context swarm1-local node ls"

echo ""
echo "--- Swarm 2 (via SSH naar node2) ---"
$SSH ${VM_USER}@${NODE1_IP} "docker --context swarm2-ssh node ls"

echo ""
echo "--- Swarm 3 (via SSH naar node3) ---"
$SSH ${VM_USER}@${NODE1_IP} "docker --context swarm3-ssh node ls"

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
