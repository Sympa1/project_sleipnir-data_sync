# Backend System Design
Das Backend dient als zentraler Server für die Synchronisation von Dateien zwischen verschiedenen Endgeräten (Windows, Linux und Android).
Der Server koordiniert den Abgleich von Dateien und löst Konflikte zwischen verschieden Clients (Aktuell mit Methode - letzte Änderung gewinnt).

## REST API Architektur
Als Kernidee habe ich einen Manifest (Listen) basierten abgleich.
Der Client sendet eine Liste aller lokal vorhanden Dateien (inkl. Hash und etwaigen Timestamps) an den Server. Der Server vergleicht die Liste mit seinen vorhanden Datei-Daten und gibt als Antwort die Dateien, die sich unterscheiden, zurück.

Durch dieses Vorgehen erhoffe ich mir einen sehr effizienten Abgleich der Dateien, lager aber zudem die Konfliktbehandlung auf dem Server aus, wodurch ich diese nicht in jeden Client integrieren muss.

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

#### Fehler Behandlung
Es werden die typischen HTTP Status Codes in Kombination mit strukturierten und aussagekräftigen Error Response verwendet. Das ermöglicht eine korrekte Reaktion auf etwaige Fehler.

