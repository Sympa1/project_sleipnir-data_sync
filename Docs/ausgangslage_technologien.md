# Feststellen der technischen Ausgangslage & der zu nutzenden Technologien
Als ich eine Grobe Idee dessen hatte, was ich realisieren will, habe ich geschaut was denn meine technische Ausgangslage ist. Also welche Geräte will ich bedienen und wie kann ich das an Hardware nutzen, was mir zur Verfügung steht, um das Ziel zu erreichen.
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
Einen ersten Test mit einer einfachen "*Libary*" REST API konnte ich gut umsetzen. 
Außerdem ist "*ASP .NET Core*" von Microsoft sehr gut dokumentiert.

Also werden ich als Backend eine *REST API* mit "*ASP .NET Core*" entwickeln, die ich dann nach Möglichkeit als *Docker Container* auf einen Ubuntu Webserver/Raspberry Pi laufen lasse.

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
Da ich in Zukunft beruflich Berührungspunkte mit dem C# haben werde, liegt die Entscheidung nahe, die Android App mit diesem Framework zu entwickeln.
Nach Möglichkeit, möchte ich die MAUI App auch für den Windows Client nutzen.
Für den Linux Laptop, ist das ganze etwas schwerer. Es gibt zwar Avalonia als GUI Framework, aber ich habe bereits Erfahrungen mit TKinter & CustomTKinter. Aber auch QT wäre spannend. Zuerst, zum testen, werde ich jedoch auf eine CLI entwickeln.