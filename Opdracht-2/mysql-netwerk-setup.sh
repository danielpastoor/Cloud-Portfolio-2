#!/bin/bash
# ============================================================
#  mysql-netwerk-setup.sh
#  Twee MySQL containers in aparte subnetten
# ============================================================

SUBNET1="172.20.0.0/24"
SUBNET2="172.21.0.0/24"
NETWERK1="mysql-subnet-1"
NETWERK2="mysql-subnet-2"

echo "============================================="
echo "  MySQL Netwerk Setup"
echo "============================================="
echo ""

echo ""
echo "Stap 1: Subnetten aanmaken..."
docker network create --driver bridge --subnet $SUBNET1 $NETWERK1
docker network create --driver bridge --subnet $SUBNET2 $NETWERK2
echo ""
echo "  Overzicht netwerken:"
docker network ls
echo "  Subnetten aangemaakt"

echo ""
echo "Stap 2: MySQL containers starten..."

docker run -d \
  --name mysql-1 \
  --network $NETWERK1 \
  -e MYSQL_ROOT_PASSWORD=wachtwoord1 \
  -e MYSQL_DATABASE=db1 \
  -p 3306:3306 \
  mysql:8.0.36

docker run -d \
  --name mysql-2 \
  --network $NETWERK2 \
  -e MYSQL_ROOT_PASSWORD=wachtwoord2 \
  -e MYSQL_DATABASE=db2 \
  -p 3307:3306 \
  mysql:8.0.36

echo ""
echo "  Wachten tot MySQL klaar is met opstarten (20 sec)..."
sleep 20

echo ""
echo "  Draaiende containers:"
docker ps
echo "  Containers gestart"

echo ""
echo "Stap 3: IP-adressen ophalen..."
IP_MYSQL1=$(docker inspect mysql-1 | grep '"IPAddress"' | head -1 | awk -F'"' '{print $4}')
IP_MYSQL2=$(docker inspect mysql-2 | grep '"IPAddress"' | head -1 | awk -F'"' '{print $4}')
echo "  mysql-1 IP: $IP_MYSQL1"
echo "  mysql-2 IP: $IP_MYSQL2"

# ── Stap 4: Test bereikbaarheid vanaf de host ────────────────
echo ""
echo "Stap 4: Testen of MySQL bereikbaar is vanaf de host..."
echo ""

echo "  Test mysql-1 (poort 3306):"
docker exec mysql-1 mysql -u root -pwachtwoord1 -e "SHOW DATABASES;" 2>/dev/null \
  && echo "  mysql-1: BEREIKBAAR" \
  || echo "  mysql-1: nog niet klaar, wacht nog even en probeer opnieuw"

echo ""
echo "  Test mysql-2 (poort 3307):"
docker exec mysql-2 mysql -u root -pwachtwoord2 -e "SHOW DATABASES;" 2>/dev/null \
  && echo "  mysql-2: BEREIKBAAR" \
  || echo "  mysql-2: nog niet klaar, wacht nog even en probeer opnieuw"

echo ""
echo "Stap 5: Testen of mysql-1 mysql-2 kan bereiken (voor de fix)..."
echo ""
echo "  mysql-1 probeert verbinding te maken met mysql-2 ($IP_MYSQL2):"
docker exec mysql-1 mysql \
  -h $IP_MYSQL2 -P 3306 \
  -u root -pwachtwoord2 \
  -e "SHOW DATABASES;" 2>&1 | head -5
echo ""
echo "  Bovenstaande fout is verwacht - containers zitten in verschillende subnetten"

echo ""
echo "Stap 6: Fix toepassen - mysql-1 verbinden met $NETWERK2..."
docker network connect $NETWERK2 mysql-1
echo "  mysql-1 is nu verbonden met beide netwerken"


echo ""
echo "Stap 7: Opnieuw testen na de fix..."
echo ""
echo "  mysql-1 verbindt met mysql-2 ($IP_MYSQL2):"
docker exec mysql-1 mysql \
  -h $IP_MYSQL2 -P 3306 \
  -u root -pwachtwoord2 \
  -e "SHOW DATABASES;" 2>/dev/null \
  && echo "  Verbinding gelukt! Containers kunnen elkaar bereiken." \
  || echo "  Verbinding mislukt - controleer de logs"

echo ""
echo "============================================="
echo "  Script voltooid!"
echo ""
echo "  mysql-1: subnet $SUBNET1 + $SUBNET2 (na fix)"
echo "  mysql-2: subnet $SUBNET2"
echo ""
echo "  Bereikbaar vanaf host:"
echo "    mysql -h $(hostname -I | awk '{print $1}') -P 3306 -u root -pwachtwoord1"
echo "    mysql -h $(hostname -I | awk '{print $1}') -P 3307 -u root -pwachtwoord2"
echo ""
echo "============================================="