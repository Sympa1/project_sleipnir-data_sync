# Server-Einrichtung (Raspberry Pi / Linux)

## Überblick

Diese Anleitung beschreibt die Einrichtung der Data Sync API auf einem Raspberry Pi oder einem anderen Linux-Server. Die API läuft in Docker-Containern und ist über Caddy als Reverse Proxy mit HTTPS erreichbar.

---

## Voraussetzungen

- Raspberry Pi (oder anderer Linux-Server) mit Debian/Ubuntu-basiertem System
- Docker & Docker Compose installiert
- Git installiert
- Feste LAN-IP-Adresse des Servers (empfohlen: im Router als statische IP vergeben)

### Docker installieren (falls noch nicht vorhanden)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Neu einloggen, damit die Gruppe aktiv wird
```

---

## Schritt 1 – Repository klonen

```bash
git clone <repository-url>
cd data_sync
```

---

## Schritt 2 – MariaDB starten

Die API benötigt eine laufende MariaDB-Instanz. Beispiel-Compose-Datei liegt in `Docs/api_usage.md`.

```bash
# Netzwerkname der MariaDB nach dem Start prüfen
docker inspect mariadb --format '{{json .NetworkSettings.Networks}}'
```

Den angezeigten Netzwerknamen (z. B. `mariadb_default`) für den nächsten Schritt notieren.

---

## Schritt 3 – API konfigurieren

```bash
cd data_sync.API
cp .env.container.example .env.container
```

Die Datei `.env.container` anpassen:

```env
DB_NETWORK_NAME=mariadb_default     # Netzwerkname aus Schritt 2
DB_HOST=mariadb                     # Container-Name der MariaDB
DB_PORT=3306
DB_NAME=data_sync
DB_USER=<app-user>
DB_PASSWORD=<app-password>
CADDY_PUBLIC_IP=<server-ip>         # LAN-IP des Servers (z. B. 192.168.0.x)
CADDY_HTTP_PORT=5000                # HTTP-Port auf dem Host
CADDY_HTTPS_PORT=5001               # HTTPS-Port auf dem Host
```

> `CADDY_PUBLIC_IP` muss die tatsächliche LAN-IP des Servers sein.
> Diese IP wird für das selbst-signierte TLS-Zertifikat von Caddy verwendet.

---

## Schritt 4 – API & Caddy starten

```bash
cd data_sync.API
docker compose --env-file .env.container up --build -d
```

Status prüfen:

```bash
docker ps
```

Alle drei Container sollten laufen:
- `data-sync-api`
- `data-sync-caddy`
- `mariadb`

---

## Schritt 5 – Erreichbarkeit testen

```bash
# HTTP testen (sollte 404 zurückgeben, da kein Root-Endpunkt existiert)
curl http://<server-ip>:5000

# API-Endpunkt testen (sollte 405 zurückgeben – Methode falsch, aber Endpunkt existiert)
curl http://<server-ip>:5000/api/sync/manifest
```

---

## Schritt 6 – Caddy-Zertifikat exportieren

Das Zertifikat wird benötigt, damit Geräte im Netzwerk (Flutter App, Browser) dem HTTPS-Zertifikat vertrauen. Das **Python CLI Tool** benötigt es **nicht**.

```bash
docker exec data-sync-caddy cat /data/caddy/pki/authorities/local/root.crt > caddy-root.crt
```

Die Datei `caddy-root.crt` auf die Geräte übertragen, die HTTPS nutzen sollen.

> Installationsanleitung für Android: siehe [flutter_setup.md](flutter_setup.md)

---

## Neustart & Updates

### Container neu starten

```bash
cd data_sync.API
docker compose --env-file .env.container restart
```

### API aktualisieren (nach `git pull`)

```bash
cd data_sync.API
docker compose --env-file .env.container up --build -d
```

### Caddy-Zertifikat erneuern

Caddy erneuert Server-Zertifikate automatisch. Das Root-CA-Zertifikat bleibt dauerhaft erhalten, solange das Docker-Volume `caddy_data` existiert.

> ⚠️ `docker compose down -v` löscht das Volume und damit die CA – danach muss das Zertifikat erneut exportiert und auf den Geräten installiert werden. Für normale Neustarts stattdessen `docker compose down` (ohne `-v`) verwenden.

---

## Fehlerbehebung

**Container startet nicht:**
```bash
docker logs data-sync-api
docker logs data-sync-caddy
```

**API erreicht MariaDB nicht:**
- `DB_HOST` muss der Container-Name sein (nicht `localhost`)
- `DB_PORT` muss `3306` sein (nicht der Host-Port)
- Netzwerkname prüfen: `docker inspect mariadb --format '{{json .NetworkSettings.Networks}}'`

**HTTPS funktioniert nicht vom Smartphone:**
- `CADDY_PUBLIC_IP` mit tatsächlicher Server-IP abgleichen
- Zertifikat exportieren und auf dem Gerät installieren (Schritt 6)
- Router-Einstellungen prüfen: WLAN-Client-Isolation deaktivieren
