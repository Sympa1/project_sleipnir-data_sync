# Data Sync
Dieses Projekt ist daraus entstanden, dass ich Dateien -in meinem Fall Obsidian Notizen- Zwischen meinen verschieden Endgeräten synchronisieren möchte. Dafür muss ich verschiedene Betriebssysteme, Windows, Linux (Manjaro) und Android bedienen.
Ich verspreche mir davon zusätzlich, einiges im Bereich DevOPS bzw. CI/CD, Mobile und Desktopapp zu lernen. Aber auch beim Datenbankdesign und bei der REST API, bin ich sicher viel hinzu zu lernen.
Mein Hauptentwicklungssystem ist Manjaro (Linux), wobei die Android App aller voraussiecht nach unter Windows entwickelt werden wird.

## Technische Details
**Geplante Technologien/Frameworks:**
- C# ASP .NET Core für das Backend
- Direkter Zugriff auf MariaDB (MySQL‑Protokoll) über ADO.NET (`MySql.Data` / `MySqlConnector`) statt eines ORMs
- C# MAUI für die Android- und nach Möglichkeit Windows App
- Python /CustomTKinter/QT für das Manjaro (Linux) Frontend

## Roadmap
**Status-Legende:**
- ✅ Abgeschlossen
- ⌛ In Arbeit
- 🕓 Geplant
- 💭 Konzeptphase

### Versionen
- 0.0.0 - Planung
    - [Feststellen der technischen Ausgangslage, der zu nutzenden Technologien & Architektur](Docs/ausgangslage_technologien.md) ✅
    - [Feststellen der Funktionen nach der MVP Methode](Docs/grundlegende_funktionen.md) ✅
    - [Erarbeiten des Datenbank Designs](Docs/datenbank_design.md) ✅
    - [Entwurf des Backend System Design](Docs/backend_system_design.md) ✅
    - [Entwurf des Client-Mockups für die Mobile App (Analog auch für die Desktop Apps)](https://github.com/Sympa1/project_sleipnir-data_sync/blob/master/Docs/android_mokup_2.png) ✅
- 0.0.1 Datenbankentwicklung
    - MariaDB Schema erstellen ✅
    - MariaDB Accounts (Admin & Client) anlegen und Berechtigungen erteilen ✅
    - Create Table SQL‑Skripte erstellen ✅
- 0.0.2 Implementierung der REST API
    - Datenbankzugriff via `MySql.Data` / `MySqlConnector` implementieren (MariaDB nutzt die MySQL Schnittstelle) ✅
    - Grundlegende REST API Endpunkte ✅
    - Entity Models / DTOs erstellen ✅
    - Postman Collection ✅
    - Implementierung File Up- und Download ✅
- 0.0.3 Linux CLI Tool
    - Lokale SQLite Datenbank ✅
    - Vorübergehendes Speichern der DB Logindaten in einem `.env` File ✅
    - CLI Framework: argparse - Verschiedene Flags für unterschiedliche Funktionen ✅
    - Lokale Berechnung des Dateihashes (SHA-256) ✅
    - Implementierung API Client ✅
    - Implementierung Logging in die MariaDB ✅
    - Implementierung Logging in eine lokale Logdatei ✅
    - Implementierung Init-Command ✅
    - Implementierung Scan-Command ✅
    - Implementierung Manifest-Command ✅
    - Implementierung Upload-Command ✅
    - Implementierung Download-Command ✅
    - Implementierung Delete-Command ✅
    - Implementierung Sync Command (Facade Pattern für alle bisherigen Aktionen) ✅
    - Three-Way-Merge Logik (LastSyncState Tabelle) ✅
    - Plattformübergreifende Hash-Kompatibilität (lowercase) ✅
    - Intelligente Duplikat-Erkennung (gleichnamige Dateien in unterschiedlichen Ordnern) ✅
    - Pfad-Normalisierung (Windows/Linux kompatibel) ✅
    - Bidirektionale Löschungs-Synchronisation ✅
    - Testing der REST API mit dem CLI Tool ✅
- 0.0.4 Android / Windows GUI
    - Lokale SQLite Datenbank 🕓
    - GUI Framework: MAUI 🕓
    - Lokale Berechnung des Dateihashes 🕓
    - Kommunikation, inkl. Manifest, mit der REST API zum Synchronisieren 🕓
- 0.1.0 Testing
    - End to End Test 💭
- 0.9.0 Release-Vorbereitung
    - Erstellen des automatischen Deployment 🕓
    - Sicheres Speichern von Datenbanklogin und Passwort 🕓
- 1.0.0 Release und Deployment Version 1.0.0
    - Release durchführen 💭

## Geplante Funktionen der ersten Version
- Ausgewähltes Verzeichnis wird synchronisiert
- Basis REST API **ohne** Authentifizierung
- Einfache Konfliktlösung - letzte Änderung wird übernommen
- Manuelle Synchronisation - der User startet den Vorgang (Download / Upload Buttons)

## Zukünftige Features
- Ein Backupsystem
- Eine Authentifizierung 
- Biometrie Login bei der Android App
- Auto Sync
- Intelligente Konfliktlösung

## Branching \& GitLab Flow

Kurz: Wir nutzen GitLab Flow. Detaillierte Regeln zu Branch-Namen, Merge-Requests und Deploys sind in `Docs/GitLabFlow.md` dokumentiert.

- Wichtige Branches: `main` / `production`, `feature/*`, `hotfix/*`, `bugfix/*`, `release/*`
- Merge-Requests: Review erforderlich, CI-Pipeline muss erfolgreich sein
- Deploy: `production` ist der Deployment-Branch (automatisiert)
- Weitere Hinweise: Siehe `Docs/GitLabFlow.md` für Beispiele und Regeln


## Verwendung

### CLI Tool
Detaillierte Informationen zur Verwendung des CLI Tools finden Sie in [Docs/cli_usage.md](Docs/cli_usage.md).

**Schnellstart:**
```bash
# Datenbank initialisieren
cd data_sync.CLI
python src/main.py --init

# Verzeichnis scannen
python src/main.py --scan

# Vollständige Synchronisation (Scan + Download + Upload + Delete)
python src/main.py --sync
```

### API
Die REST API läuft auf `https://localhost:7169` (Development) und bietet folgende Endpunkte:
- `POST /api/sync/manifest` - Manifest-Abgleich mit Three-Way-Merge
- `POST /api/sync/upload` - Datei-Upload
- `GET /api/sync/download` - Datei-Download
- `DELETE /api/sync/delete` - Datei-Löschung

## Voraussetzungen

**Für das CLI Tool:**
- Python 3.8 oder höher
- `requests` Bibliothek: `pip install requests`
- `config.json` im Projektverzeichnis (siehe [cli_usage.md](Docs/cli_usage.md))

**Für die API:**
- .NET 8.0 SDK oder höher
- MariaDB Server (MySQL-kompatibel)
- `MySqlConnector` NuGet Package
## Verzeichnisstruktur

```
data_sync/
├── Docs/                            # Projekt-Dokumentation
│   ├── android_mokup_2.png
│   ├── ausgangslage_technologien.md
│   ├── backend_system_design.md
│   ├── cli_usage.md                 # CLI Benutzerhandbuch
│   ├── datenbank_design.md
│   ├── gitlab_flow.md
│   └── grundlegende_funktionen.md
│
├── data_sync.API/                   # ASP.NET Core REST API
│   ├── data_sync.API.csproj
│   ├── appsettings.json
│   ├── Program.cs
│   │
│   ├── Controllers/                 # API Endpoints
│   │   └── SyncController.cs
│   │
│   ├── DTOs/                        # Data Transfer Objects
│   │   ├── ConfirmDownloadDtos.cs
│   │   ├── ConfirmUploadDtos.cs
│   │   └── ManifestDtos.cs
│   │
│   ├── Models/                      # Entity Models & Enums
│   │   ├── SyncFile.cs
│   │   ├── SyncEvent.cs
│   │   ├── FileState.cs
│   │   └── SyncAction.cs
│   │
│   ├── Services/                    # Business Logic Services
│   │   ├── DbErrorLogService.cs
│   │   ├── DbStartupCheckService.cs
│   │   ├── EnvLoadeService.cs
│   │   ├── FileLogService.cs
│   │   ├── GetFilesToSyncService.cs
│   │   ├── MariaDBService.cs        # ADO.NET Service für MariaDB
│   │   ├── UpdateMetadataService.cs
│   │   └── UtilsService.cs
│   │
│   ├── MariaDB/                     # MariaDB Schema
│   │   └── CreateTable.sql
│   │
│   ├── Tests/                       # Test-Dateien
│   │   ├── Postman/                 # Postman Collections
│   │   ├── DbErrorLogServiceTests.cs
│   │   └── TestService.cs
│   │
│   └── Properties/
│       └── launchSettings.json
│
├── data_sync.CLI/                   # Python CLI Tool
│   ├── src/
│   │   ├── main.py                  # Entry Point
│   │   └── core/                    # Core-Logik
│   │       ├── commands/            # Command Pattern Implementation
│   │       │   ├── base_command.py
│   │       │   ├── init_command.py
│   │       │   ├── scan_command.py
│   │       │   ├── manifest_command.py
│   │       │   ├── upload_command.py
│   │       │   └── download_command.py
│   │       ├── handlers/            # Hilfsfunktionen
│   │       │   ├── config_handler.py
│   │       │   ├── sqlite_handler.py
│   │       │   ├── manifest_handler.py
│   │       │   ├── db_logger.py
│   │       │   └── file_logger.py
│   │       ├── api_client.py        # REST API Client
│   │       ├── file_scanner.py      # Verzeichnis-Scanner
│   │       ├── db_setup.py          # DB-Initialisierung
│   │       └── models.py            # Datenmodelle
│   ├── SQLite/
│   │   └── CreateTable.sql          # SQLite Schema
│   └── test_data/                   # Test-Verzeichnis
│
├── config.json                      # CLI Konfiguration
├── cli_db.db                        # SQLite Datenbank (generiert)
├── README.md
└── data_sync.sln                    # Visual Studio Solution
```

## Installation

### CLI Tool installieren
```bash
# 1. Repository klonen
git clone <repository-url>
cd data_sync

# 2. Python-Abhängigkeiten installieren
pip install requests

# 3. Konfiguration erstellen
cat > config.json << EOF
{
  "sync_path": "/pfad/zum/sync/verzeichnis",
  "api_base_url": "https://localhost:7169/api/sync",
  "verify_ssl": false
}
EOF

# 4. Datenbank initialisieren
cd data_sync.CLI/src
python main.py --init
```

### API Backend starten
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

Detaillierte Informationen zur CLI-Verwendung: [Docs/cli_usage.md](Docs/cli_usage.md)

## Abhängigkeiten

### CLI Tool (Python)
- `requests` - HTTP-Bibliothek für API-Kommunikation
- Python Standard Library (`os`, `hashlib`, `sqlite3`, `json`, `argparse`)

### API Backend (ASP.NET Core)
- .NET 8.0
- `MySqlConnector` - MariaDB/MySQL Datenbankzugriff
- `DotNetEnv` - .env Datei Support

## Lizenz
Dieses Projekt ist unter der GPL-3.0 lizenziert - siehe die [LICENSE](LICENSE)-Datei für Details.
