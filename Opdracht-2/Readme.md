# Docker Subnetten

## Wat is een subnet in Docker?
Een Docker subnet is een geïsoleerd netwerk met een eigen IP-range. Containers in hetzelfde subnet kunnen elkaar bereiken, containers in verschillende subnetten standaard niet.

## Hoe maak je meerdere subnetten aan?

Maak een netwerk aan met een eigen IP-range:
```bash
docker network create --driver bridge --subnet 172.20.0.0/24 mijn-netwerk
```

Koppel een container aan dat netwerk:
```bash
docker run -d --name mijn-container --network mijn-netwerk mysql:8.0
```

Wil je dat twee containers in verschillende subnetten elkaar toch kunnen bereiken? Verbind de container met het tweede netwerk:
```bash
docker network connect tweede-netwerk mijn-container
```

## Waarom is dit nuttig?

**Isolatie** - Containers zien alleen de containers in hetzelfde subnet. Een database is niet zomaar bereikbaar voor elke willekeurige container.

**Beveiliging** - Als een container gehackt wordt, heeft de aanvaller geen toegang tot containers in andere subnetten.

**Overzicht** - Je kunt een logische scheiding maken per laag, bijvoorbeeld:
- `frontend-netwerk` -> webservers
- `backend-netwerk` -> applicatieservers  
- `database-netwerk` -> databases

**Controle** - Je bepaalt zelf welke containers met elkaar mogen communiceren door ze wel of niet aan hetzelfde subnet te koppelen.