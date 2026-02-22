# Feststellen der technischen Ausgangslage & der zu nutzenden Technologien
Als ich eine grobe Idee dessen hatte, was ich realisieren will, habe ich geschaut, was denn meine technische Ausgangslage ist. Also welche Geräte will ich bedienen und wie kann ich das an Hardware nutzen, was mir zur Verfügung steht, um das Ziel zu erreichen.
Zum anderen habe ich auch meine Fähigkeiten betrachtet.

## Technische Ausgangslage
- Windows Desktop PC
- Manjaro (Linux) Laptop
- Aktuell ein Google Pixel (Android 16)
- Webserver (Ubuntu)
- Raspberry Pi 

## Meine Fähigkeiten
- C# - Erfahrungen in den Frameworks .NET, Blazor und ASP .NET Core. 
- Python - Erfahrungen in div. Frameworks, z.B. CustomTKinter

## Geplante Architektur
Basierend auf meiner technischen Ausgangslage und meinen Fähigkeiten, habe ich mir die Architektur überlegt.
#### Backend
Da ich beruflich viele Berührungspunkte mit C# habe, habe ich mir für das Backend das Framework "*ASP .NET Core*" näher angeschaut.
Es soll zuverlässig und schnell sein.
Einen ersten Test mit einer einfachen "*Library*" REST API konnte ich gut umsetzen.
Außerdem ist "*ASP .NET Core*" von Microsoft sehr gut dokumentiert.

Also werde ich als Backend eine *REST API* mit "*ASP .NET Core*" entwickeln, die ich dann nach Möglichkeit als *Docker Container* auf einem Ubuntu Webserver/Raspberry Pi laufen lasse.

**Datenbankzugriff:**
Die ursprüngliche Idee war, EF Core (ORM) zu verwenden. Nach Tests und Abwägung von Komplexität und Kompatibilität habe ich mich jedoch für direkten ADO.NET‑Zugriff auf MariaDB (MySQL‑Protokoll) entschieden. Gründe:
- Volle Kontrolle über SQL und MariaDB‑spezifische Features
- Weniger Paket‑/Versionskonflikte (kein Provider‑Binding an EF Core nötig)
- Einfachere, explizite SQL‑Skripte
- Probleme mit der Migration bzgl. der Datenbankserver in Dockercontainer

Als Bibliothek wird `MySql.Data` (oder optional `MySqlConnector`) verwendet.

**Wichtig:** Verbindungsdaten werden über eine `.env` Datei im Projektstamm geladen (EnvLoadeService). Erwartete Variablen (Beispiele):
- DB_HOST 
- DB_PORT 
- DB_NAME 
- DB_USER
- DB_PASSWORD

#### Frontend
Ursprünglich war geplant, die Android- und Windows-App mit C# MAUI zu entwickeln. Leider ließ sich MAUI für Android nicht zuverlässig zum Laufen bringen. Da ich nicht ewig daran herumbasteln wollte, habe ich mich für Flutter entschieden. Flutter ist ein spannendes Framework, mit dem ich aus einer Codebasis heraus die Android-, Linux- und Windows-App kompilieren kann. Das hält die Entwicklung simpel und effizient.

Optional ist für die Zukunft eine Windows Forms Admin-App mit einem Dashboard denkbar, das zunächst Statistiken anzeigt und später um User Management erweitert werden kann.

Zum Testen der API wurde zunächst eine Python CLI entwickelt.