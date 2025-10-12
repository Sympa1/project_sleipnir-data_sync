# Grundlegende Funktionen - MVP Methode
## Funktionsanalyse
#### Kernproblem
Ich möchte meine Obsidian Notizen zwischen Windows, Manjaro (Linux) und Android synchronisieren.
#### Lösungsansatz
Cross-Plattform Data Sync mit zentralen Server zum Daten verteilen, mit lokalen Clients.

## MVP Definition
#### Ziel
Erreichung der grundlegenden Sync-Funktionalität zwischen Server und Client.
#### Minimaler funktionaler Umfang
- Ausgewähltes Verzeichnis wird synchronisiert
- Basis REST API **ohne** Authentifizierung
- Funktionsfähige Client Anwendungen
- Einfache Konfliktlösung - letzte Änderung wird übernommen
- Manuelle Synchronisation - der User startet den Vorgang (Download / Upload Buttons)

## Post MVP Definition
#### Nachfolgende Funktionen
- Ein Backupsystem
- Eine Authentifizierung 
- Biometrie Login bei der Android App
- Auto Sync
- Intelligente Konfliktlösung