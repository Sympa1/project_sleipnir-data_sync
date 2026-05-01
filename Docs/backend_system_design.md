# Backend System Design

Das Backend ist der zentrale Server fuer die Dateisynchronisation zwischen verschiedenen Clients. Aktuell sind vor allem das Python-CLI und perspektivisch Flutter-Clients relevant.

Dieses Dokument beschreibt bewusst nicht nur die technische Struktur, sondern auch die dahinterliegende Lernidee: Das Backend ist so aufgebaut, dass Architektur, Datenfluss und zentrale Entscheidungen gut nachvollziehbar bleiben. Das ist hilfreich zum Lernen und zugleich ein sinnvoller Aspekt fuer ein Portfolio-Projekt.

## Ziel des Backends

Das Backend soll:

- den aktuellen Serverzustand von Dateien verwalten,
- den Abgleich zwischen Client und Server koordinieren,
- Datei-Inhalte bereitstellen oder entgegennehmen,
- Loeschungen synchronisieren,
- eine Grundlage fuer spaetere Konfliktbehandlung und weitere Clients schaffen.

## Architekturueberblick

Die API ist als ASP.NET Core Web API aufgebaut. Der Einstiegspunkt ist `Program.cs`, die HTTP-Endpunkte liegen im `SyncController`, und die fachliche Unterstuetzung ist ueber Services organisiert.

### Aktuelle Hauptbausteine

- `SyncController`
  - definiert die oeffentlichen REST-Endpunkte
  - nimmt Requests entgegen und gibt HTTP-Responses zurueck
- `GetFilesToSyncService`
  - vergleicht Client-Manifest und Serverzustand
  - entscheidet ueber `toUpload`, `toDownload` und `toDelete`
- `UpdateMetadataService`
  - schreibt oder aktualisiert Datei-Metadaten in MariaDB
- `SyncStateService`
  - verwaltet den letzten bekannten Synchronisationsstand in `LastSyncState`
- `MariaDbService`
  - kapselt den Aufbau von Datenbankverbindungen
- `DbStartupCheckService`
  - prueft beim Start Verbindung und Tabellen
- `UtilsService`
  - enthaelt Hilfslogik wie die Hash-Berechnung

## Warum diese Architektur?

Die Architektur ist relativ einfach und direkt. Das ist in diesem Projekt Absicht:

- Der Datenfluss bleibt gut lesbar.
- HTTP, Datenbank und Dateisystem lassen sich bewusst nachvollziehen.
- Wichtige Grundlagen wie DTOs, Services und DI werden praktisch geuebt.

Fuer ein grosses Produktionssystem waeren einige Teile staerker getrennt. Fuer ein Lern- und Portfolio-Projekt ist die aktuelle Struktur aber ein sinnvoller Zwischenstand, weil man die Entscheidungen noch gut erkennen kann.

## REST-API-Fluss

Die Synchronisation basiert auf einem **Manifest-Ansatz**. Der Client sendet eine Liste seiner bekannten Dateien mit Metadaten an den Server. Der Server vergleicht diesen Zustand mit seiner Datenbank und antwortet mit Aktionen fuer den Client.

```text
Client                     API                        MariaDB / Dateisystem
  |                         |                                  |
  |---- POST /manifest ---->|                                  |
  |                         |---- Manifest mit DB vergleichen ->|
  |                         |<--- Abgleich-Ergebnis -----------|
  |<--- toUpload/toDownload/toDelete --------------------------|
  |                         |                                  |
  |---- POST /upload ------>|                                  |
  |                         |---- Datei speichern ------------->|
  |                         |---- SyncFiles aktualisieren ----->|
  |                         |---- LastSyncState aktualisieren ->|
  |<--- OK ----------------------------------------------------|
  |                         |                                  |
  |---- GET /download ----->|                                  |
  |                         |---- Datei lesen ----------------->|
  |                         |---- LastSyncState aktualisieren ->|
  |<--- Binary-Datei ------------------------------------------|
  |                         |                                  |
  |---- DELETE /delete ---->|                                  |
  |                         |---- Datei loeschen ------------->|
  |                         |---- SyncFiles auf deleted ------->|
  |                         |---- LastSyncState entfernen ----->|
  |<--- OK ----------------------------------------------------|
```

## Oeffentliche Endpunkte

Die API stellt aktuell vier zentrale Endpunkte bereit:

| HTTP-Methode | Route | Zweck |
|---|---|---|
| `POST` | `/api/sync/manifest` | vergleicht Client- und Serverzustand |
| `POST` | `/api/sync/upload` | laedt eine Datei auf den Server |
| `GET` | `/api/sync/download` | liefert eine Datei als Binary zurueck |
| `DELETE` | `/api/sync/delete` | synchronisiert eine Loeschung |

Diese Endpunkte passen direkt zum Python-CLI und bilden den aktuellen Kern des Systems.

## Manifest-basierte Synchronisation

Das Manifest enthaelt unter anderem:

- `fileName`
- `relativePath`
- `size`
- `sha256`
- `createdAt`
- `lastModified`
- `changeState`

Der Server vergleicht diese Informationen mit `SyncFiles` und entscheidet:

- **toUpload**: der Client soll seine Datei hochladen
- **toDownload**: der Client soll die Serverdatei herunterladen
- **toDelete**: die Datei soll als geloescht behandelt werden

Der grosse Vorteil dieses Ansatzes ist, dass der Client nicht blind Dateien uebertraegt. Erst wird ein Abgleich gemacht, danach folgen die eigentlichen Dateioperationen.

## Zusammenarbeit von API, Datenbank und Dateisystem

Das Backend arbeitet mit zwei Persistenzebenen:

### 1. Dateisystem

Die eigentlichen Dateien werden im Upload-Verzeichnis gespeichert.

### 2. MariaDB

Die Datenbank speichert:

- Datei-Metadaten
- Dateizustaende
- Fehlerprotokolle
- den letzten gemeinsamen Synchronisationsstand

Das ist eine wichtige Trennung:

- **Dateisystem = Inhalt**
- **Datenbank = Zustand, Vergleich und Nachvollziehbarkeit**

## Service- und Verantwortungsmodell

### Controller

Der Controller bildet die HTTP-Schnittstelle nach aussen. Er sollte moeglichst Requests validieren, Services aufrufen und passende Responses liefern.

### Services

Die Services kapseln einzelne fachliche Verantwortungen:

- Vergleichslogik
- Metadatenpflege
- Sync-State-Verwaltung
- Datenbankverbindung
- Startpruefungen

Das ist bereits ein Schritt in Richtung sauberer Architektur. Gleichzeitig zeigt das Projekt auch, dass die Trennung noch weiter verbessert werden kann, zum Beispiel indem Dateisystemlogik und Fachlogik noch konsequenter aus dem Controller herausgezogen werden.

## Technische Entscheidungen

### ASP.NET Core

ASP.NET Core wurde gewaehlt, weil es:

- eine klare Struktur fuer Web APIs bietet,
- Dependency Injection standardmaessig unterstuetzt,
- sich gut fuer REST-Schnittstellen und spaetere Erweiterungen eignet.

### ADO.NET statt ORM

Der Datenbankzugriff erfolgt bewusst direkt ueber SQL und `MySql.Data`.

**Lernvorteil:**
- SQL bleibt sichtbar
- Datenbanklogik wird nicht versteckt
- der Zusammenhang zwischen Query, DTO und Datenmodell wird klarer

**Nachteil:**
- mehr manueller Code
- hoehere Verantwortung fuer Konsistenz und Wartbarkeit

### Manifest statt Vollabgleich ueber Dateiinhalte

Ein Dateiabgleich ueber Metadaten und Hashes ist effizienter als das ungepruefte Uebertragen kompletter Dateien. Ausserdem laesst sich darauf spaeter besser eine Konfliktlogik aufbauen.

## Aktueller Reifegrad

Das Backend ist funktional bereits sinnvoll nutzbar, aber bewusst noch kein voll ausgebautes Produktionssystem.

### Was aktuell gut funktioniert

- Manifest-Abgleich
- Upload und Download
- bidirektionale Loesch-Synchronisation
- serverseitige Hash-Berechnung
- Anbindung an MariaDB

### Was noch nicht auf Produktionsniveau ist

- keine Authentifizierung oder Autorisierung
- einfache Fehlerbehandlung
- keine ausgearbeitete Sicherheitsstrategie fuer Dateipfade und Storage
- begrenzte Testabdeckung
- einige Verantwortlichkeiten liegen noch zu stark im Controller

Gerade diese Punkte sind fuer ein Portfolio-Projekt nicht nur eine Schwaeche, sondern auch eine Chance: Man kann daran gut zeigen, was bereits umgesetzt wurde und welche architektonischen Verbesserungen als naechste Schritte geplant sind.

## Perspektivische Weiterentwicklung

Sinnvolle naechste Schritte fuer das Backend waeren:

1. staerkere Trennung von Controller-, Dateisystem- und Fachlogik
2. bessere Validierung und Absicherung von Datei-Pfaden
3. saubere Teststruktur in einem eigenen Testprojekt
4. Authentifizierung und Rechtekonzept
5. robustere Konfliktbehandlung
6. bessere Beobachtbarkeit durch strukturierteres Logging
