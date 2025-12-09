# Backend System Design
Das Backend dient als zentraler Server für die Synchronisation von Dateien zwischen verschiedenen Endgeräten (Windows, Linux und Android).
Der Server koordiniert den Abgleich von Dateien und löst Konflikte zwischen verschieden Clients (Aktuell mit Methode - letzte Änderung gewinnt).

## REST API Architektur
Im Kern wird vom CLient ein Manifest an den Server gesendet, welcher daraufhin die Unterschiede ermittelt und dem Client mitteilt, welche Dateien hoch- oder heruntergeladen werden müssen.
Mit einem Manifest meine ich eine Liste aller Dateien mit Metadaten (Hash, Name, etc.).

Durch dieses Vorgehen erhoffe ich mir einen sehr effizienten Abgleich der Dateien, lager aber zudem die Konfliktbehandlung auf dem Server aus, wodurch ich diese nicht in jeden Client integrieren muss.
Das möchte ich auch als vorbereitende Maßnahme für z.B. eine intelligente Konfliktlösung in der Zukunft so implemtieren.

```
Client                Server               Database
  |                     |                     |
  |----> POST /manifest |                     |
  |                     |----> Query files    |
  |                     |<---- File metadata  |
  |<---- Upload actions |                     |
  |                     |                     |
  |----> POST /upload   |                     |
  |                     |----> Insert/Update  |
  |<---- Success        |<---- Confirmation   |
```

#### Kern-Endpoints
- POST - ../api/sync/manifest
- POST - ../api/sync/upload
- GET - ../api/sync/download

#### Datenzugriff & Services
- Es wird ein spezifischer ADO.NET‑Service (`MariaDbService` in `data_sync.API/Services/`) geben, der Verbindungen öffnet, SQL‑Statements ausführt und Fehler protokolliert.
- Beim Start des API‑Servers wird ein `DbStartupCheckService` den Verbindungsaufbau testen und optional notwendige `CREATE TABLE IF NOT EXISTS` SQL‑Skripte ausführen.
- SQL‑Skripte im Ordner `Database/MariaDB/`.

#### Fehler Behandlung
Es werden die typischen HTTP Status Codes in Kombination mit strukturierten und aussagekräftigen Error Response verwendet. Das ermöglicht eine korrekte Reaktion auf etwaige Fehler.
