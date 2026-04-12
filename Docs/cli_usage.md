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
