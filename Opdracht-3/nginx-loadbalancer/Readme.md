# Nginx Load Balancer

## Gevolgde tutorial
https://terminalnotes.com/implementing-high-availability-docker-nginx-load-balancer/

## Wat is load balancing?

Load balancing is het verdelen van inkomend netwerkverkeer over meerdere servers.
In plaats van dat één server alle verzoeken afhandelt, worden ze verdeeld over
meerdere servers. Dit zorgt ervoor dat geen enkele server overbelast raakt.

In dit project verdeelt Nginx het verkeer via het **round-robin** algoritme:
elk nieuw verzoek gaat naar de volgende server in de rij (App1 → App2 → App3 → App1 → ...).
De backend servers zijn niet direct bereikbaar van buitenaf want alle verkeer loopt
via de load balancer. Dit is een extra beveiligingslaag.

## Wat gebeurt er als een container stopt?

Wanneer een container uitvalt, bijvoorbeeld door een crash of onderhoud, detecteert
Nginx dit automatisch via een **passive health check**. Nginx merkt dat er geen
reactie komt van die server en stuurt nieuwe verzoeken automatisch door naar de
overige beschikbare servers.

In dit project werd App2 handmatig gestopt met `docker compose stop app2` om een
server crash te simuleren. Het resultaat: App1 en App3 bleven alle verzoeken
afhandelen zonder dat de gebruiker een foutmelding zag. Zodra App2 weer opgestart
wordt, neemt Nginx hem automatisch weer op in de rotatie.