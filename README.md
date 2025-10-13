# Project Sleipnir - Data Sync
Dieses Projekt ist daraus entstanden, dass ich Dateien -in meinem Fall Obsidian Notizen- Zwischen meinen verschieden Endgeräten synchronisieren möchte. Dafür muss ich verschiedene Betriebssysteme, Windows, Linux (Manjaro) und Android bedienen.
Ich verspreche mir davon zusätzlich, einiges im Bereich DevOPS bzw. CI/CD, Mobile und Desktopapp zu lernen. Aber auch beim Datenbankdesign und bei der REST API, bin ich sicher viel hinzu zu lernen.
Mein Hauptentwicklungssystem ist Manjaro (Linux), wobei die Android App aller voraussiecht nach unter Windows entwickelt werden wird.
## Namensgebung
**Sleipnir**, Odins acht beiniges Pferd aus der nordischen Mythologie, verkörpert die Projektziele: Seine Fähigkeit **zwischen den neun Welten zu reisen** spiegelt die Cross-Platform-Synchronisation verschiedener Geräte wider, seine **Treue zu Odin** steht für zuverlässige Datensicherheit und seine **legendäre Geschwindigkeit** für effiziente Synchronisation.
## Technische Details
**Geplante Technologien/Frameworks:**
- C# ASP .NET Core für das Backend
- C# MAUI für die Android- und nach Möglichkeit Windows App
- Python /CustomTKinter/QT für das Manjaro (Linux) Frontend
## Roadmap (in Arbeit)
- 0.0.0 - Planung
    - [Feststellen der technischen Ausgangslage, der zu nutzenden Technologien & Architektur](Docs/ausgangslage_technologien.md)
    - [Feststellen der Funktionen nach der MVP Methode](Docs/grundlegende_funktionen.md)
    - [Erarbeiten des Datenbank Designs](Docs/datenbank_design.md)
    - [Entwurf des Backend System Design](Docs/backend_system_design.md)
    - [Entwurf des Client-Mockups](Docs/client_mockup.md)
    - [Planung von Automatisierten Tests & Deployment](Docs/cicd.md)
- 0.0.1 Datenbankentwicklung
    - MySQL Schema erstellen
- 0.0.2 Implementierung der REST API
    - Grundlegende REST API Endpunkte
    - Erstellen der SQL Statements
    - Postman Collection
    - Implementierung File Up- und Download
    - Implementierung Python CLI zum Testen
- 0.0.3 Linux GUI
    - Lokale SQLite Datenbank
    - GUI Framework: CustomTkinter oder QT
    - Lokale Berechnung des Dateihashes
    - Kommunikation, inkl. Manifest, mit der REST API zum Synchronisieren
- 0.0.4 Android / Windows GUI
    - Lokale SQLite Datenbank
    - GUI Framework: MAUI
    - Lokale Berechnung des Dateihashes
    - Kommunikation, inkl. Manifest, mit der REST API zum Synchronisieren
- 0.0.5 Erstellen des automatischen Deployment
- ~~0.1.0 Testing~~
- ~~1.0.0 Deployment Version 1.0.0~~
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
## ~~Lessons Learned~~
~~Work in Progress.~~
## ~~Voraussetzungen~~
~~Work in Progress.~~
## Verzeichnisstruktur
```
project_sleipnir/
├── Database/
│   ├── MySQL/
│   │   └── Schema.sql
│   └── SQLite/
│       └── Schema.sql
│
├── Docker/
│   └── Placeholder
│
├── Docs/
│   ├── android_mokup_2.png
│   ├── ausgangslage_technologien.md
│   ├── backend_system_design.md
│   ├── datenbank_design.md
│   └── grundlegende_funktionen.md
│
├── Sleipnir.API/
│   └── Sleipnir.API.csproj
|
├── Sleipnir.CLI/
│   └── main.py
|
├── Sleipnir.GUI/
│   └── main.py    
|
├── Sleipnir.MAUI/
│   └── Sleipnir.MAUI.csproj
│
├── Tests/
│   └── Postman/
│       └── Sleipnir.postman_collection.json
│
├── README.md
└── Sleipnir.sln
```
## ~~Installation~~
~~Work in Progress.~~
## ~~Verwendung~~
~~Work in Progress.~~
## Bekannte Probleme
Keine bekannten Probleme.
## ~~Abhängigkeiten~~
~~Work in Progress.~~
## Lizenz
Dieses Projekt ist unter der GPL-3.0 lizenziert - siehe die [LICENSE](LICENSE)-Datei für Details.



