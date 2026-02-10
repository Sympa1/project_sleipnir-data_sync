# Data Sync CLI - Benutzerhandbuch

## Übersicht

Das Data Sync CLI Tool ist ein Python-basiertes Kommandozeilen-Werkzeug zur Synchronisation von Dateien zwischen verschiedenen Endgeräten über eine REST API. Es nutzt eine lokale SQLite-Datenbank zur Verwaltung von Dateimetadaten und ermöglicht bidirektionale Synchronisation mit Three-Way-Merge-Logik.

## Voraussetzungen

- Python 3.8 oder höher
- `requests` Bibliothek (`pip install requests`)
- Zugriff auf eine laufende Data Sync API (ASP.NET Core Backend)
- Konfigurationsdatei `config.json` im CLI-Verzeichnis

## Installation

1. **Python-Abhängigkeiten installieren:**
   ```bash
   pip install requests
   ```

2. **Konfigurationsdatei erstellen:**
   Erstelle eine `config.json` im `data_sync.CLI/` Verzeichnis:
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
   cd data_sync.CLI
   python src/main.py --init
   ```
   
   Das System fragt nach dem Sync-Pfad und speichert ihn automatisch in `config.json`.

## Verfügbare Befehle

Das CLI Tool wird über verschiedene Flags aufgerufen. **Nur ein Flag kann gleichzeitig verwendet werden.**

### 1. `--init` / `-i` - Datenbank initialisieren

Initialisiert die lokale SQLite-Datenbank für das CLI Tool. Dieser Befehl muss **einmalig vor der ersten Nutzung** ausgeführt werden.

**Verwendung:**
```bash
python src/main.py --init
```

**Was passiert:**
- Erstellt die SQLite-Datenbank `cli_db.db` im `data_sync.CLI/` Verzeichnis
- Legt die Tabellen `SyncFiles`, `SyncEvents`, `LastSyncState` und `FehlerProtokoll` an
- Fragt nach dem Sync-Pfad und speichert ihn in `config.json`
- Lädt das SQL-Schema aus `sqlite/create_table.sql`

**Beispiel-Output:**
```
Initializing database...
Database initialized successfully.

Please configure your path to sync in config.json before proceeding.
Enter the path to sync: /home/user/Documents/sync
Sync path '/home/user/Documents/sync' saved to config.json.
```

---

### 2. `--scan` / `-c` - Verzeichnis scannen

Scannt das in `config.json` konfigurierte Verzeichnis (`sync_path`) und speichert Informationen über alle Dateien in der lokalen Datenbank.

**Verwendung:**
```bash
python src/main.py --scan
```

**Was passiert:**
- Rekursives Scannen aller Dateien im `sync_path`
- Berechnung von Datei-Metadaten:
  - Relativer Pfad (normalisiert mit `/` auch unter Windows)
  - Dateiname
  - Dateigröße
  - SHA-256 Hash-Wert (binary mode, lowercase)
  - Erstellungsdatum
  - Änderungsdatum
- Speicherung in der lokalen SQLite-Datenbank
- **Intelligente Duplikat-Erkennung:**
  - Dateien mit gleichem Namen und Hash in **unterschiedlichen** Ordnern werden als neue Dateien erkannt
  - Dateien mit gleichem Namen und Hash im **gleichen** Ordner werden als Verschiebung erkannt

**Beispiel-Output:**
```
Scanning directory and updating database with file information...
Inserted new file: test_file2.txt
Inserted new file: unterverzeichnis1/test_file1.txt
Inserted new file: unterverzeichnis1/geichnamiger_test.txt
New file (duplicate of unterverzeichnis1/geichnamiger_test.txt): unterverzeichnis2/geichnamiger_test.txt
Inserted new file: unterverzeichnis2/geichnamiger_test.txt
No files to mark as deleted.

================================================================================
Scan completed successfully.
```

**Hinweis:** Dieser Befehl muss ausgeführt werden, bevor Dateien synchronisiert werden können.

---

### 3. `--manifest` / `-m` - Manifest-Abgleich

Sendet das lokale Datei-Manifest an die API und erhält eine Liste der zu synchronisierenden Dateien zurück.

**Verwendung:**
```bash
python src/main.py --manifest
```

**Was passiert:**
- Liest alle Dateien aus der lokalen Datenbank (außer Konflikte)
- Erstellt ein Manifest mit allen Datei-Metadaten
- Sendet das Manifest an `POST /api/sync/manifest`
- Server führt **Three-Way-Merge** durch:
  - Vergleicht Client-Zustand, Server-Zustand und LastSyncState
  - Erkennt wer seit dem letzten Sync geändert hat
- Empfängt vom Server eine Liste mit Synchronisations-Anweisungen:
  - `toUpload: true` - Datei muss hochgeladen werden
  - `toDownload: true` - Datei muss heruntergeladen werden
  - `toDelete: true` - Datei muss gelöscht werden
  - `changeState` - Status der Datei (New, Modified, Unchanged, Deleted, Conflict)

**Beispiel-Output:**
```
Starting manifest processing...
Database connection established successfully.
Using API base URL: https://localhost:7169/api/sync

Client manifest:
File Pfad: test_file2.txt - File Status: new - File Größe: 26 Bytes
File Pfad: unterverzeichnis1/test_file1.txt - File Status: new - File Größe: 26 Bytes

================================================================================
Server response - Files to sync:
File Pfad: test_file2.txt - File Status: Unchanged - File Größe: 26 Bytes
File Pfad: unterverzeichnis1/test_file1.txt - File Status: New - File Größe: 26 Bytes

================================================================================
Manifest processing completed successfully.
```

---

### 4. `--upload` / `-u` - Dateien hochladen

Führt den kompletten Upload-Prozess aus: Manifest-Abgleich + Upload aller zu synchronisierenden Dateien.

**Verwendung:**
```bash
python src/main.py --upload
```

**Was passiert:**
1. Führt `--manifest` aus
2. Lädt alle Dateien hoch, die `toUpload: true` **ODER** `changeState: "New"` haben
3. **Überspringt gelöschte Dateien** automatisch
4. Sendet Dateien an `POST /api/sync/upload`
5. Query-Parameter: `basePath` (Verzeichnispfad ohne Dateinamen)
6. Form-Data: `file` (Dateiinhalt als Binary)
7. Aktualisiert `LastSyncState` nach erfolgreichem Upload

**Beispiel-Output:**
```
Upload process started
Warning: SSL verification is disabled.
Using API base URL: https://localhost:7169/api/sync
Upload File: geichnamiger_test.txt - File Status: New - File Größe: 80 Bytes
Upload File: test_file1.txt - File Status: Modified - File Größe: 26 Bytes

Data Sync CLI execution completed.
```

**Wichtig:** Neue Dateien (`changeState: "New"`) werden automatisch hochgeladen, auch wenn `toUpload: false` ist.

---

### 5. `--download` / `-d` - Dateien herunterladen

Führt den kompletten Download-Prozess aus: Manifest-Abgleich + Download aller zu synchronisierenden Dateien.

**Verwendung:**
```bash
python src/main.py --download
```

**Was passiert:**
1. Führt `--manifest` aus
2. Lädt alle Dateien herunter, die `toDownload: true` haben
3. Ruft `GET /api/sync/download?filePath=...` auf
4. Speichert Dateien im `sync_path` unter ihrem relativen Pfad
5. Erstellt fehlende Verzeichnisse automatisch
6. Aktualisiert lokale Datenbank und `LastSyncState`

**Beispiel-Output:**
```
Download process started
Warning: SSL verification is disabled.
Using API base URL: https://localhost:7169/api/sync
Successful downloads: 0
Failed downloads: 0
Download process completed
```

**Wichtig:** Nur Dateien mit `toDownload: true` werden heruntergeladen.

---

### 6. `--delete` / `-x` - Löschungen synchronisieren

Führt die Synchronisation von Löschungen durch (bidirektional).

**Verwendung:**
```bash
python src/main.py --delete
```

**Was passiert:**
1. **Server → Client:** Löscht lokale Dateien, die auf dem Server gelöscht wurden (`toDelete: true`)
2. **Client → Server:** Sendet DELETE-Requests für lokal gelöschte Dateien (`file_state = 'deleted'`)
3. Aktualisiert `LastSyncState` (löscht Einträge für beidseitig gelöschte Dateien)

**Beispiel-Output:**
```
Delete synchronization started
Server requests deletion: hello-world.txt
Deleted locally: unterverzeichnis2/hello-world.txt
Local deletions processed: 1
Server deletions processed: 0
Delete synchronization completed
```

---

### 7. `--sync` / `-s` - Vollständige Synchronisation

Führt den kompletten Synchronisationsprozess aus: Scan → Manifest → Download → Upload → Delete.

**Verwendung:**
```bash
python src/main.py --sync
```

**Was passiert:**
1. `--scan` - Scannt das lokale Verzeichnis und aktualisiert die Datenbank
2. `--manifest` - Gleicht mit dem Server ab (Three-Way-Merge)
3. `--download` - Lädt neue/geänderte Dateien vom Server herunter
4. `--upload` - Lädt neue/geänderte Dateien zum Server hoch
5. `--delete` - Synchronisiert Löschungen bidirektional

**Beispiel-Output:**
```
Scanning directory and updating database with file information...
Scan completed successfully.

Starting manifest processing...
Manifest processing completed successfully.

Download process started
Successful downloads: 1
Download process completed

Upload process started
Upload completed

Delete synchronization started
Delete synchronization completed

Data Sync CLI execution completed.
```

**Hinweis:** Dieser Befehl ist ideal für regelmäßige bidirektionale Synchronisation.

---

## Workflow-Beispiele

### Erstes Setup (Neuer Client)

```bash
# 1. Datenbank initialisieren
cd data_sync.CLI
python src/main.py --init
# Sync-Pfad eingeben: /home/user/Documents/sync

# 2. Dateien vom Server holen (leeres Manifest)
python src/main.py --sync
```

**Was passiert:** Der Client sendet ein leeres Manifest. Der Server antwortet mit allen verfügbaren Dateien zum Download.

### Dateien zum Server hochladen

```bash
# 1. Lokale Änderungen scannen
python src/main.py --scan

# 2. Hochladen
python src/main.py --upload
```

### Dateien vom Server herunterladen

```bash
# Manifest abrufen und herunterladen
python src/main.py --download
```

### Regelmäßige bidirektionale Synchronisation

```bash
# Alles in einem Befehl
python src/main.py --sync
```

### Datei löschen und synchronisieren

```bash
# 1. Datei lokal löschen (z.B. mit rm)
rm /home/user/Documents/sync/test.txt

# 2. Scan + Sync
python src/main.py --scan
python src/main.py --sync

# Datei wird auf dem Server gelöscht
```

---

## Three-Way-Merge Logik

Das System verwendet **Three-Way-Merge** zur intelligenten Konfliktauflösung:

### Wie funktioniert es?

```
LastSyncState (Referenzpunkt beim letzten Sync)
       ↓
Client ← → Server
```

**Vergleich:**
1. Hat Client seit letztem Sync geändert? (`client_hash != last_sync_hash`)
2. Hat Server seit letztem Sync geändert? (`server_hash != last_sync_hash`)

**Entscheidungen:**
| Client geändert | Server geändert | Aktion |
|----------------|----------------|--------|
| ❌ Nein | ❌ Nein | **Unchanged** - Nichts tun |
| ✅ Ja | ❌ Nein | **Upload** - Client ist aktueller |
| ❌ Nein | ✅ Ja | **Download** - Server ist aktueller |
| ✅ Ja | ✅ Ja | **Conflict** - Beide haben geändert |

**Vorteile:**
- ✅ Keine unnötigen Uploads/Downloads
- ✅ Timestamp-Probleme werden umgangen (Hash ist zuverlässiger)
- ✅ Echte Konflikte werden erkannt

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

5. **404 Not Found beim Download**
   - Datei existiert nicht auf dem Server
   - Manifest neu abrufen: `python src/main.py --manifest`

6. **Duplicate entry for key 'file_path'**
   - UNIQUE Constraint verhindert Duplikate (ist gut!)
   - Scan erneut ausführen: `python src/main.py --scan`

---

## Technische Details

### Datenbankstruktur

**Tabelle: SyncFiles**
- `sync_file_id` - Primärschlüssel (AUTO_INCREMENT)
- `file_name` - Dateiname
- `file_path` - Relativer Pfad der Datei (**UNIQUE**)
- `file_size` - Größe in Bytes
- `hash_value` - SHA-256 Hash (lowercase)
- `created_at` - Erstellungsdatum
- `last_modified` - Änderungsdatum
- `file_state` - Status (new, modified, unchanged, deleted, conflict)

**Tabelle: LastSyncState**
- `file_path` - Relativer Pfad (**PRIMARY KEY**)
- `hash_value` - SHA-256 Hash beim letzten Sync
- `file_size` - Größe beim letzten Sync
- `last_modified` - Zeitpunkt des letzten Syncs

**Tabelle: SyncEvents**
- `sync_event_id` - Primärschlüssel
- `sync_file_id` - Fremdschlüssel zu SyncFiles
- `event_type` - Aktion (created, modified, deleted, error)
- `event_timestamp` - Zeitstempel
- `event_details` - Details

**Tabelle: FehlerProtokoll**
- `fehler_protokoll_id` - Primärschlüssel
- `fehler_beschreibung` - Fehlermeldung
- `fehler_timestamp` - Zeitstempel

### API-Endpunkte

| Befehl | HTTP-Methode | Endpunkt | Parameter |
|--------|--------------|----------|-----------|
| manifest | POST | `/api/sync/manifest` | Body: JSON-Array mit Datei-Metadaten |
| upload | POST | `/api/sync/upload` | Query: `basePath`, Form: `file` |
| download | GET | `/api/sync/download` | Query: `filePath` |
| delete | DELETE | `/api/sync/delete` | Query: `filePath` |

### Hash-Berechnung

**Wichtig:** Beide Seiten (Client und Server) berechnen Hashes identisch:

```python
# Client (Python)
hasher = hashlib.sha256()
with open(file_path, 'rb') as file:  # Binary mode
    while chunk := file.read(8192):
        hasher.update(chunk)
hash_value = hasher.hexdigest()  # lowercase
```

```csharp
// Server (C#)
using (var sha256 = SHA256.Create())
{
    using (var stream = File.OpenRead(filePath))  // Binary mode
    {
        var hash = sha256.ComputeHash(stream);
        return Convert.ToHexString(hash).ToLowerInvariant();  // lowercase
    }
}
```

**Warum Binary Mode?**
- Keine Line-Ending-Konvertierung (Windows `\r\n` vs. Linux `\n`)
- Byte-genaue Berechnung
- Plattformübergreifend identisch

### Pfad-Normalisierung

**Problem:** Windows verwendet `\` (Backslash), Linux verwendet `/` (Forward Slash)

**Lösung:** Alle Pfade werden in der Datenbank mit `/` gespeichert:

```python
# Normalisierung beim Scan
file_path = str(element.relative_to(self.base_path)).replace("\\", "/")
```

**Resultat:** Plattformübergreifende Kompatibilität ✅

---

## Sicherheitshinweise

⚠️ **Für Produktion:**
- `verify_ssl: true` setzen
- Gültige SSL-Zertifikate verwenden
- API-Authentifizierung implementieren (geplant für spätere Versionen)
- Niemals Passwörter in `config.json` speichern

⚠️ **Für Entwicklung:**
- `verify_ssl: false` nur in vertrauenswürdigen Netzwerken
- Warnung wird beim Start ausgegeben

---

## Bekannte Einschränkungen & Geplante Features

**Aktuelle Einschränkungen:**
- Keine Authentifizierung
- Keine automatische Synchronisation (manuell ausführen)
- Konflikte werden erkannt, aber nicht automatisch aufgelöst
- Keine GUI

**Geplante Features (Version 0.0.4+):**
- GUI für Desktop (MAUI/CustomTkinter)
- Automatische Synchronisation (Background Service)
- Intelligente Konfliktauflösung mit User-Dialog
- Authentifizierung & Verschlüsselung
- Backup-System
- Versionierung

---

## Projektstruktur

```
data_sync.CLI/
├── config.json                    # Konfiguration (wird erstellt)
├── cli_db.db                      # SQLite Datenbank (wird erstellt)
├── src/
│   ├── main.py                    # Entry Point
│   └── core/                      # Core-Logik
│       ├── commands/              # Command Pattern Implementation
│       │   ├── base_command.py    # Basis-Klasse für Commands
│       │   ├── init_command.py    # --init
│       │   ├── scan_command.py    # --scan
│       │   ├── manifest_command.py # --manifest
│       │   ├── upload_command.py  # --upload
│       │   ├── download_command.py # --download
│       │   └── delete_command.py  # --delete
│       ├── handlers/              # Hilfsfunktionen
│       │   ├── config_handler.py  # Config-Verwaltung
│       │   ├── sqlite_handler.py  # DB-Zugriff
│       │   ├── manifest_handler.py # Manifest-Logik
│       │   ├── db_logger.py       # DB-Logging
│       │   └── file_logger.py     # File-Logging
│       ├── api_client.py          # REST API Client
│       ├── file_scanner.py        # Verzeichnis-Scanner
│       ├── sync_state_manager.py  # LastSyncState Manager
│       ├── db_setup.py            # DB-Initialisierung
│       └── models.py              # Datenmodelle
├── sqlite/
│   └── create_table.sql           # DB-Schema
└── test_data/                     # Testdaten
```

---

## Changelog

### Version 0.0.3 (Februar 2026)

**Neue Features:**
- ✅ Three-Way-Merge Logik implementiert
- ✅ `LastSyncState` Tabelle für Konfliktauflösung
- ✅ `--delete` Command für bidirektionale Löschung
- ✅ `--sync` Command führt jetzt vollständige Synchronisation durch
- ✅ Intelligente Duplikat-Erkennung bei gleichnamigen Dateien
- ✅ Plattformübergreifende Pfad-Normalisierung
- ✅ Hash-Berechnung in lowercase (Python & C# kompatibel)

**Bugfixes:**
- ✅ UNIQUE Constraint auf `file_path` in SyncFiles
- ✅ Keine unnötigen Uploads mehr (Hash-Vergleich funktioniert)
- ✅ Upload von `changeState: "New"` Dateien funktioniert
- ✅ Gelöschte Dateien werden nicht hochgeladen
- ✅ Gleichnamige Dateien in unterschiedlichen Ordnern werden synchronisiert

---

## Support & Weiterentwicklung

**Bei Problemen:**
1. Logs prüfen (werden in der Konsole ausgegeben)
2. `config.json` und Pfade überprüfen
3. API-Server-Status prüfen (`dotnet run` in `data_sync.API/`)
4. GitHub Issues erstellen

**Contribution:**
- Pull Requests sind willkommen
- Siehe `Docs/GitLabFlow.md` für Branching-Regeln

---

**Version:** 0.0.3  
**Letzte Aktualisierung:** Februar 2026

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
