#!/bin/bash
# ============================================================
#  docker-networking.sh — Demonstreert Docker networking
#  commando's één voor één met uitleg
#  Voer dit uit op één van de Docker nodes
# ============================================================

pauze() {
    echo ""
    echo "Druk op ENTER voor de volgende stap..."
    read
    clear
}

stap() {
    echo "============================================="
    echo "  $1"
    echo "============================================="
    echo ""
}

uitleg() {
    echo "$1"
    echo ""
}

clear
echo "============================================="
echo "  Docker Networking - Demo Script"
echo "============================================="
echo ""
echo " Dit script voert alle basis Docker networking"
echo " commando's één voor één uit met uitleg."
echo ""
echo "Druk op ENTER om te beginnen..."
read
clear

stap "STAP 1 — Toon alle bestaande netwerken"
uitleg "Elk Docker systeem heeft standaard 3 netwerken: bridge, host en none."

docker network ls

pauze

stap "STAP 2 — Inspecteer het standaard bridge netwerk"
uitleg "Het bridge netwerk is het standaard netwerk waar containers in starten als je geen netwerk opgeeft."

docker network inspect bridge

pauze

stap "STAP 3 — Maak een custom bridge netwerk aan"
uitleg "Een custom netwerk laat containers elkaar bereiken via naam in plaats van alleen via IP."

docker network create --driver bridge demo-netwerk
echo ""
echo "Netwerk 'demo-netwerk' aangemaakt. Overzicht:"
echo ""
docker network ls

pauze

stap "STAP 4 — Inspecteer het nieuwe custom netwerk"
uitleg "Het custom netwerk heeft nog geen containers — de 'Containers' sectie is leeg."

docker network inspect demo-netwerk

pauze

stap "STAP 5 — Start container 1 in het custom netwerk"
uitleg "We starten een Nginx container en koppelen die aan ons custom netwerk."

docker run -d \
    --name webserver-1 \
    --network demo-netwerk \
    nginx:alpine

echo ""
echo "Container webserver-1 gestart. Draaiende containers:"
echo ""
docker ps

pauze

stap "STAP 6 — Start container 2 in hetzelfde netwerk"
uitleg "Beide containers zitten nu in hetzelfde netwerk en kunnen elkaar bereiken via naam."

docker run -d \
    --name webserver-2 \
    --network demo-netwerk \
    nginx:alpine

echo ""
echo "Container webserver-2 gestart. Draaiende containers:"
echo ""
docker ps

pauze

stap "STAP 7 — Inspecteer netwerk (containers zichtbaar)"
uitleg "Nu zijn beide containers zichtbaar in het netwerk met hun IP-adressen."

docker network inspect demo-netwerk

pauze

stap "STAP 8 — Ping van container 1 naar container 2 via naam"
uitleg "In een custom netwerk werkt DNS automatisch — containers vinden elkaar via hun naam."

docker exec webserver-1 ping -c 4 webserver-2

pauze

stap "STAP 9 — Ping van container 2 naar container 1 via naam"
uitleg "Dit werkt ook andersom — beide containers kunnen elkaar bereiken."

docker exec webserver-2 ping -c 4 webserver-1

pauze

stap "STAP 10 — Maak een tweede netwerk aan (geïsoleerd)"
uitleg "Containers in verschillende netwerken kunnen elkaar standaard NIET bereiken. Dit is isolatie."

docker network create --driver bridge geïsoleerd-netwerk
echo ""
docker network ls

pauze

stap "STAP 11 — Start container 3 in het geïsoleerde netwerk"
uitleg "Container 3 zit in een ander netwerk en kan webserver-1 en webserver-2 NIET bereiken."

docker run -d \
    --name webserver-3 \
    --network geïsoleerd-netwerk \
    nginx:alpine

echo ""
docker ps

pauze

stap "STAP 12 — Bewijs: container 3 kan container 1 NIET bereiken"
uitleg "Ping mislukt omdat de netwerken gescheiden zijn. Dit is bewust — goede beveiliging!"

echo "Ping van webserver-3 naar webserver-1 (verwacht: mislukt):"
echo ""
docker exec webserver-3 ping -c 3 webserver-1 2>&1 || echo ""
echo "Ping mislukt -- containers zitten in verschillende netwerken (dit is correct gedrag!)"

pauze

stap "STAP 13 — Verbind container 3 met het demo-netwerk"
uitleg "Met 'network connect' kun je een container aan een extra netwerk koppelen. Nu kan container 3 wél communiceren."

docker network connect demo-netwerk webserver-3
echo ""
echo "Container 3 is nu verbonden met demo-netwerk én geïsoleerd-netwerk."
echo ""
docker network inspect demo-netwerk | grep -A 5 "webserver-3"

pauze

stap "STAP 14 — Bewijs: container 3 kan container 1 NU wél bereiken"
uitleg "Na het verbinden met demo-netwerk werkt de communicatie wel."

docker exec webserver-3 ping -c 4 webserver-1

pauze

stap "STAP 15 — Ontkoppel container 1 van het demo-netwerk"
uitleg "Met 'network disconnect' verwijder je een container uit een netwerk."

docker network disconnect demo-netwerk webserver-1
echo ""
echo "Container 1 ontkoppeld van demo-netwerk."
echo ""
docker network inspect demo-netwerk

pauze

stap "STAP 16 — Alles opruimen"
uitleg "Goede gewoonte: ruim containers en netwerken op als je klaar bent."

echo "Containers stoppen..."
docker stop webserver-1 webserver-2 webserver-3

echo "Containers verwijderen..."
docker rm webserver-1 webserver-2 webserver-3

echo "Netwerken verwijderen..."
docker network rm demo-netwerk geïsoleerd-netwerk

echo ""
echo "Eindstatus — netwerken:"
docker network ls

echo ""
echo "Eindstatus — containers:"
docker ps -a

pauze

echo "============================================="
echo "  Script voltooid!"
echo "============================================="
echo ""
echo " Samenvatting van de commando's die zijn uitgevoerd:"
echo ""
echo "  docker network ls                        — netwerken tonen"
echo "  docker network inspect <naam>            — details bekijken"
echo "  docker network create --driver bridge    — netwerk aanmaken"
echo "  docker run --network <naam>              — container in netwerk starten"
echo "  docker exec <c> ping <c2>                — communicatie testen"
echo "  docker network connect <netwerk> <cont>  — container toevoegen"
echo "  docker network disconnect <n> <c>        — container ontkoppelen"
echo "  docker network rm <naam>                 — netwerk verwijderen"
echo ""