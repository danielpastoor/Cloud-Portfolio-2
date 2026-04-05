# Wat is een Reverse Proxy?

Een reverse proxy is een server die tussen de gebruiker en de 
webservers in staat. De gebruiker stuurt een verzoek naar één 
adres, de proxy bepaalt naar welke server dat verzoek gaat.

De servers achter de proxy zijn niet direct zichtbaar voor de 
gebruiker. Traefik detecteert automatisch nieuwe Docker containers 
en configureert zichzelf op basis van labels op de containers.

Voordelen:
- Één centraal toegangspunt
- SSL op één plek regelen
- Load balancing
- Beveiliging: servers niet direct bereikbaar