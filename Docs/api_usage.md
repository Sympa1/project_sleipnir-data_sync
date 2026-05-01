# API Anleitung

## Überblick

Die REST API läuft lokal im Development-Modus standardmäßig unter `https://localhost:7169`.

Sie stellt folgende Endpunkte bereit:

- `POST /api/sync/manifest` - Manifest-Abgleich mit Three-Way-Merge
- `POST /api/sync/upload` - Datei-Upload
- `GET /api/sync/download` - Datei-Download
- `DELETE /api/sync/delete` - Datei-Löschung

## Voraussetzungen

**Für die API:**

- .NET 10.0 SDK oder höher
- MariaDB Server (MySQL-kompatibel)
- `MySql.Data` NuGet Package

## API Backend starten

```bash
# 1. MariaDB vorbereiten
# Schema aus data_sync.API/MariaDB/CreateTable.sql importieren

# 2. .env Datei erstellen (in data_sync.API/)
cat > .env << EOF
DB_HOST=localhost
DB_PORT=3306
DB_NAME=data_sync
DB_USER=data_sync_client
DB_PASSWORD=your_password
EOF

# 3. API starten
cd data_sync.API
dotnet run
```

## API im Docker-Container starten

```bash
# 1. In das API-Verzeichnis wechseln
cd data_sync.API

# 2. Beispiel-Konfiguration kopieren und anpassen
cp .env.container.example .env.container

# Wichtige Werte:
# - DB_HOST = Service-Name des MariaDB-Containers im gemeinsamen Docker-Netzwerk
# - DB_NETWORK_NAME = Name des externen Docker-Netzwerks, das beide Compose-Stacks teilen

# 3. API-Container bauen und starten
docker compose --env-file .env.container up --build -d
```

Hinweise:

- `DB_HOST` ist im Container **nicht** `localhost`, sondern normalerweise der Service-Name der Datenbank, z. B. `mariadb`.
- Die API-Compose-Datei erwartet ein bereits existierendes externes Docker-Netzwerk (`DB_NETWORK_NAME`).
- Hochgeladene Dateien bleiben über das gemountete Verzeichnis `data_sync.API/uploads/` persistent erhalten.
- Lokal bleiben HTTP und HTTPS parallel nutzbar. Im Container ist standardmäßig HTTP aktiv, damit kein Zertifikat vorausgesetzt wird.

## Docker-Anleitung für die API mit MariaDB

Die API kann in einem eigenen Docker-Container laufen, während MariaDB in einem separaten Compose-Stack betrieben wird.
Wichtig ist dabei, dass **beide Container im selben Docker-Netzwerk erreichbar sind**.

### 1. MariaDB mit Docker Compose starten

Beispiel für eine MariaDB-Compose-Datei:

```yaml
services:
  mariadb:
    image: mariadb:latest
    container_name: mariadb
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <root-password>
      MARIADB_DATABASE: data_sync
      MARIADB_USER: <app-user>
      MARIADB_PASSWORD: <app-password>
    volumes:
      - mariadb_data:/var/lib/mysql
    ports:
      - "3307:3306"

  phpmyadmin:
    image: phpmyadmin:latest
    container_name: phpmyadmin
    restart: unless-stopped
    environment:
      PMA_HOST: mariadb
      PMA_PORT: 3306
      PMA_USER: <admin-user>
      PMA_PASSWORD: <admin-password>
    ports:
      - "8080:80"
    depends_on:
      - mariadb

volumes:
  mariadb_data:
```

Start:

```bash
docker compose up -d
```

Wichtige Unterscheidung:

- Vom **Host-System** aus ist die Datenbank hier über `localhost:3307` erreichbar.
- Von einem **anderen Container im selben Docker-Netzwerk** aus ist sie über `mariadb:3306` erreichbar.

### 2. Netzwerk der MariaDB prüfen

Wenn die Datenbank bereits läuft, kann das Netzwerk des MariaDB-Containers geprüft werden:

```bash
docker inspect mariadb --format '{{json .NetworkSettings.Networks}}'
```

Beispielausgabe:

```text
{"mariadb_default":{...}}
```

In diesem Fall ist `mariadb_default` der richtige Wert für `DB_NETWORK_NAME`.

### 3. API-Konfiguration für Docker anlegen

Die API verwendet für Docker die Datei `.env.container`.

```bash
cd data_sync.API
cp .env.container.example .env.container
```

Beispielinhalt:

```env
DB_NETWORK_NAME=mariadb_default
DB_HOST=mariadb
DB_PORT=3306
DB_NAME=data_sync
DB_USER=<app-user>
DB_PASSWORD=<app-password>
API_PORT=5000
```

Bedeutung der Werte:

- `DB_NETWORK_NAME`: Name des Docker-Netzwerks, in dem der MariaDB-Container läuft
- `DB_HOST`: Service- oder Containername der Datenbank im Docker-Netzwerk
- `DB_PORT`: interner Port des MariaDB-Containers, normalerweise `3306`
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`: müssen zu den MariaDB-Umgebungsvariablen passen
- `API_PORT`: Port, unter dem die API auf dem Host veröffentlicht wird

### 4. API-Container starten

Die Compose-Datei der API benötigt die `.env.container` als Eingabe für die Variablenersetzung:

```bash
cd data_sync.API
docker compose --env-file .env.container up --build -d
```

Die API ist danach standardmäßig über HTTP erreichbar:

```text
http://localhost:5000
```

Die Endpunkte des `SyncController` liegen unter:

```text
http://localhost:5000/api/sync
```

### 5. Wo landen hochgeladene Dateien?

Die Uploads werden durch das Volume-Mapping persistent auf dem Host gespeichert:

```yaml
volumes:
  - ./uploads:/app/uploads
```

Das bedeutet:

- im Container: `/app/uploads`
- auf dem Host: `data_sync.API/uploads`

### 6. Wichtige Hinweise zu HTTPS

- Lokal außerhalb von Docker bleiben HTTP und HTTPS parallel nutzbar.
- Im Docker-Container ist standardmäßig **HTTP aktiv**.
- HTTPS kann später ergänzt werden, wenn im Container ein Zertifikat bereitgestellt wird.

### 7. Häufige Fehler

**Fehler:** `The "DB_NETWORK_NAME" variable is not set`

Ursache:

- Die API wurde mit `docker compose up` gestartet, aber **ohne** `--env-file .env.container`.

Lösung:

```bash
docker compose --env-file .env.container up --build -d
```

**Fehler:** `network declared as external, but could not be found`

Ursache:

- Der angegebene Netzwerkname stimmt nicht mit dem tatsächlichen Docker-Netzwerk des MariaDB-Containers überein.

Lösung:

- Netzwerk mit `docker inspect mariadb --format '{{json .NetworkSettings.Networks}}'` prüfen
- `DB_NETWORK_NAME` in `.env.container` entsprechend anpassen

**Fehler:** Die API erreicht die Datenbank nicht

Typische Ursachen:

- `DB_HOST=localhost` wurde verwendet
- `DB_PORT=3307` wurde statt `3306` eingetragen
- Benutzername, Passwort oder Datenbankname passen nicht zur MariaDB-Konfiguration

Regel:

- **Host zu MariaDB:** `localhost:3307`
- **API-Container zu MariaDB:** `mariadb:3306`
