# Data Sync CLI - Benutzerhandbuch

## Übersicht

Das Data Sync CLI Tool ist ein Python-basiertes Kommandozeilen-Werkzeug zur Synchronisation von Dateien zwischen verschiedenen Endgeräten über eine REST API. Es nutzt eine lokale SQLite-Datenbank zur Verwaltung von Dateimetadaten und ermöglicht bidirektionale Synchronisation.

## Voraussetzungen

- Python 3.8 oder höher
- `requests` Bibliothek (`pip install requests`)
- Zugriff auf eine laufende Data Sync API (ASP.NET Core Backend)
- Konfigurationsdatei `config.json` im Projektverzeichnis

## Installation

1. **Python-Abhängigkeiten installieren:**
   ```bash
   pip install requests
   ```

2. **Konfigurationsdatei erstellen:**
   Erstelle eine `config.json` im Root-Verzeichnis des Projekts:
   ```json
   {
     "sync_path": "/pfad/zum/synchronisations/verzeichnis",
     "api_base_url": "https://localhost:7169/api/sync",
     "verify_ssl": false
   }
   ```

   **Parameter:**
   - `sync_path`: Absoluter Pfad zum Verzeichnis, das synchronisiert werden soll
   - `api_base_url`: URL der Data Sync API (ohne trailing slash)
   - `verify_ssl`: SSL-Zertifikatsprüfung aktivieren (`true`) oder deaktivieren (`false`)

3. **Datenbank initialisieren:**
   ```bash
   cd data_sync.CLI/src
   python main.py --init
   ```

## Verfügbare Befehle

Das CLI Tool wird über verschiedene Flags aufgerufen. **Nur ein Flag kann gleichzeitig verwendet werden.**

### 1. `--init` / `-i` - Datenbank initialisieren

Initialisiert die lokale SQLite-Datenbank für das CLI Tool. Dieser Befehl muss **einmalig vor der ersten Nutzung** ausgeführt werden.

**Verwendung:**
```bash
python main.py --init
```

**Was passiert:**
- Erstellt die SQLite-Datenbank `cli_db.db` im Projektverzeichnis
- Legt die Tabellen `sync_files` und `sync_events` an
- Lädt das SQL-Schema aus `SQLite/CreateTable.sql`

**Beispiel-Output:**
```
Database initialized successfully
```

---

### 2. `--scan` / `-c` - Verzeichnis scannen

Scannt das in `config.json` konfigurierte Verzeichnis (`sync_path`) und speichert Informationen über alle Dateien in der lokalen Datenbank.

**Verwendung:**
```bash
python main.py --scan
```

**Was passiert:**
- Rekursives Scannen aller Dateien im `sync_path`
- Berechnung von Datei-Metadaten:
  - Relativer Pfad
  - Dateiname
  - Dateigröße
  - SHA-256 Hash-Wert
  - Erstellungsdatum
  - Änderungsdatum
- Speicherung in der lokalen SQLite-Datenbank

**Beispiel-Output:**
```
Scan process started
Reading configuration from config.json...
Configuration loaded successfully
Scanning directory: /home/user/Documents/sync
File found: document.txt
Hash: a1b2c3d4e5f6...
Size: 1024 Bytes
Scan completed. 15 files processed.
```

**Hinweis:** Dieser Befehl muss ausgeführt werden, bevor Dateien synchronisiert werden können.

---

### 3. `--manifest` / `-m` - Manifest-Abgleich

Sendet das lokale Datei-Manifest an die API und erhält eine Liste der zu synchronisierenden Dateien zurück.

**Verwendung:**
```bash
python main.py --manifest
```

**Was passiert:**
- Liest alle Dateien aus der lokalen Datenbank
- Erstellt ein Manifest mit allen Datei-Metadaten
- Sendet das Manifest an `POST /api/sync/manifest`
- Empfängt vom Server eine Liste mit Synchronisations-Anweisungen:
  - `toUpload: true` - Datei muss hochgeladen werden
  - `toDownload: true` - Datei muss heruntergeladen werden
  - `changeState` - Status der Datei (New, Modified, Deleted, etc.)

**Beispiel-Output:**
```
Manifest process started
Using API base URL: https://localhost:7169/api/sync
Sending manifest with 15 files...
Response received: 3 files need synchronization
  - document.txt: toUpload (Modified)
  - image.png: toDownload (New)
  - notes.md: toUpload (New)
```

---

### 4. `--upload` / `-u` - Dateien hochladen

Führt den kompletten Upload-Prozess aus: Manifest-Abgleich + Upload aller zu synchronisierenden Dateien.

**Verwendung:**
```bash
python main.py --upload
```

**Was passiert:**
1. Führt `--manifest` aus
2. Lädt alle Dateien hoch, die `toUpload: true` haben
3. Sendet Dateien an `POST /api/sync/upload`
4. Query-Parameter: `basePath` (Verzeichnispfad ohne Dateinamen)
5. Form-Data: `files` (Dateiinhalt als Binary)

**Beispiel-Output:**
```
Manifest process started
Using API base URL: https://localhost:7169/api/sync
Sending manifest...

Upload process started
Using API base URL: https://localhost:7169/api/sync
Upload File: document.txt - File Status: Modified - File Größe: 1024 Bytes
Upload File: notes.md - File Status: New - File Größe: 2048 Bytes
Upload completed successfully. 2 files uploaded.
```

**Wichtig:** Nur Dateien mit `toUpload: true` werden hochgeladen.

---

### 5. `--download` / `-d` - Dateien herunterladen

Führt den kompletten Download-Prozess aus: Manifest-Abgleich + Download aller zu synchronisierenden Dateien.

**Verwendung:**
```bash
python main.py --download
```

**Was passiert:**
1. Führt `--manifest` aus
2. Lädt alle Dateien herunter, die `toDownload: true` haben
3. Ruft `GET /api/sync/download?filePath=...` auf
4. Speichert Dateien im `sync_path` unter ihrem relativen Pfad
5. Erstellt fehlende Verzeichnisse automatisch

**Beispiel-Output:**
```
Manifest process started
Using API base URL: https://localhost:7169/api/sync
Sending manifest...

Download process started
Using API base URL: https://localhost:7169/api/sync
Download File: image.png - Server Path: uploads/images/image.png
File saved to: /home/user/Documents/sync/images/image.png
Download completed successfully. 1 file downloaded.
```

**Wichtig:** Nur Dateien mit `toDownload: true` werden heruntergeladen.

---

### 6. `--sync` / `-s` - Vollständige Synchronisation

Führt den kompletten Synchronisationsprozess aus: Scan → Manifest → Download.

**Verwendung:**
```bash
python main.py --sync
```

**Was passiert:**
1. `--scan` - Scannt das lokale Verzeichnis
2. `--manifest` - Gleicht mit dem Server ab
3. `--download` - Lädt neue/geänderte Dateien herunter

**Beispiel-Output:**
```
Scan process started
Scanning directory: /home/user/Documents/sync
Scan completed. 15 files processed.

Manifest process started
Sending manifest...

Download process started
Download File: new_file.txt
Download completed successfully. 1 file downloaded.
```

**Hinweis:** Dieser Befehl ist ideal für regelmäßige Synchronisation vom Server zum Client. Aktuell werden **nur Downloads** durchgeführt, keine Uploads.

---

## Workflow-Beispiele

### Erstes Setup

```bash
# 1. Datenbank initialisieren
python main.py --init

# 2. Lokales Verzeichnis scannen
python main.py --scan

# 3. Mit Server abgleichen
python main.py --manifest
```

### Dateien zum Server hochladen

```bash
# 1. Lokale Änderungen scannen
python main.py --scan

# 2. Hochladen
python main.py --upload
```

### Dateien vom Server herunterladen

```bash
# 1. Manifest abrufen und herunterladen
python main.py --download
```

### Regelmäßige bidirektionale Synchronisation

```bash
# Upload von lokalen Änderungen
python main.py --scan
python main.py --upload

# Download von Server-Änderungen
python main.py --download
```

---

## Fehlerbehandlung

Bei Fehlern werden detaillierte Fehlermeldungen ausgegeben:

```
Error uploading file: document.txt - Error: Connection refused
```

**Häufige Fehler:**

1. **ModuleNotFoundError: No module named 'requests'**
   - Lösung: `pip install requests`

2. **Connection refused**
   - API ist nicht erreichbar
   - `api_base_url` in `config.json` prüfen
   - API-Server starten

3. **SSL Certificate Verification Failed**
   - Lösung: `verify_ssl: false` in `config.json` setzen (nur für Entwicklung!)

4. **File not found**
   - `sync_path` in `config.json` prüfen
   - Sicherstellen, dass das Verzeichnis existiert

---

## Technische Details

### Datenbankstruktur

**Tabelle: sync_files**
- `id` - Primärschlüssel
- `file_path` - Relativer Pfad der Datei
- `file_name` - Dateiname
- `file_size` - Größe in Bytes
- `hash_value` - SHA-256 Hash
- `created_at` - Erstellungsdatum
- `last_modified` - Änderungsdatum
- `file_state` - Status (Active, Modified, Deleted)

**Tabelle: sync_events**
- `id` - Primärschlüssel
- `file_id` - Fremdschlüssel zu sync_files
- `event_time` - Zeitstempel
- `sync_action` - Aktion (Upload, Download, Delete)
- `status` - Erfolg/Fehler
- `error_message` - Fehlermeldung (optional)

### API-Endpunkte

| Befehl | HTTP-Methode | Endpunkt | Parameter |
|--------|--------------|----------|-----------|
| manifest | POST | `/api/sync/manifest` | Body: JSON-Array mit Datei-Metadaten |
| upload | POST | `/api/sync/upload` | Query: `basePath`, Form: `files` |
| download | GET | `/api/sync/download` | Query: `filePath` |

---

## Sicherheitshinweise

⚠️ **Für Produktion:**
- `verify_ssl: true` setzen
- Gültige SSL-Zertifikate verwenden
- API-Authentifizierung implementieren (geplant für spätere Versionen)

⚠️ **Für Entwicklung:**
- `verify_ssl: false` nur in vertrauenswürdigen Netzwerken
- Warnung wird beim Start ausgegeben

---

## Projektstruktur

```
data_sync.CLI/
├── src/
│   ├── main.py                    # Entry Point
│   └── core/                      # Core-Logik
│       ├── commands/              # Command Pattern Implementation
│       │   ├── base_command.py    # Basis-Klasse für Commands
│       │   ├── init_command.py    # --init
│       │   ├── scan_command.py    # --scan
│       │   ├── manifest_command.py # --manifest
│       │   ├── upload_command.py  # --upload
│       │   └── download_command.py # --download
│       ├── handlers/              # Hilfsfunktionen
│       │   ├── config_handler.py  # Config-Verwaltung
│       │   ├── sqlite_handler.py  # DB-Zugriff
│       │   ├── manifest_handler.py # Manifest-Logik
│       │   ├── db_logger.py       # DB-Logging
│       │   └── file_logger.py     # File-Logging
│       ├── api_client.py          # REST API Client
│       ├── file_scanner.py        # Verzeichnis-Scanner
│       ├── db_setup.py            # DB-Initialisierung
│       └── models.py              # Datenmodelle
├── SQLite/
│   └── CreateTable.sql            # DB-Schema
└── test_data/                     # Testdaten
```

---

## Support & Weiterentwicklung

**Geplante Features (Version 0.0.4+):**
- GUI für Desktop (MAUI/CustomTkinter)
- Automatische Synchronisation
- Konfliktauflösung
- Authentifizierung

**Bekannte Einschränkungen:**
- `--sync` führt aktuell nur Downloads durch
- Keine automatische Synchronisation
- Keine Authentifizierung

---

**Version:** 0.0.3  
**Letzte Aktualisierung:** Januar 2026
