# Datenbankdesign

Dieses Projekt verwendet auf der Serverseite **MariaDB** und auf der Clientseite **SQLite**. Die MariaDB bildet den zentralen Zustand des Servers ab, waehrend die SQLite im Python-CLI den lokalen Dateistand und den letzten bekannten Synchronisationsstand speichert.

Die Datenbankstruktur ist bewusst relativ einfach gehalten. Das passt zum Lerncharakter des Projekts und macht Entscheidungen, SQL-Abfragen und Datenfluesse leichter nachvollziehbar. Gleichzeitig ist die Struktur klar genug, um das Projekt als Portfolio-Arbeit praesentieren zu koennen.

## Ziel des Datenmodells

Das Datenmodell soll vier Kernfragen beantworten:

1. Welche Dateien kennt der Server aktuell?
2. In welchem Zustand befindet sich eine Datei auf dem Server?
3. Welche Aktionen oder Fehler sind waehrend der Synchronisation aufgetreten?
4. Was war der letzte bekannte gemeinsame Synchronisationsstand?

Daraus ergeben sich vier zentrale Tabellen:

- `SyncFiles`
- `SyncEvent`
- `FehlerProtokoll`
- `LastSyncState`

Die aktuelle Grundlage fuer das Server-Schema liegt in `data_sync.API/MariaDB/CreateTable.sql`.

## Warum kein ORM?

Im Projekt wird bewusst **kein ORM** eingesetzt. Stattdessen erfolgt der Zugriff ueber **ADO.NET** mit `MySql.Data`.

Das hat fuer dieses Projekt zwei Vorteile:

- Ich lerne SQL, Datenmodellierung und Datenbankzugriffe direkter kennen.
- Die Datenfluesse bleiben fuer ein Lern- und Portfolio-Projekt transparenter als bei einer stark abstrahierten Loesung.

Der Nachteil ist, dass ich selbst staerker auf Konsistenz, Validierung und Wartbarkeit achten muss. Genau das ist hier aber auch Teil des Lernziels.

## Schema-Uebersicht

### Tabelle `SyncFiles`

Diese Tabelle beschreibt den aktuellen fachlichen Zustand einer Datei auf dem Server.

```sql
CREATE TABLE IF NOT EXISTS SyncFiles (
    sync_file_id INT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(1024) NOT NULL UNIQUE,
    file_size BIGINT NOT NULL,
    hash_value VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    file_state ENUM('new', 'modified', 'unchanged', 'deleted', 'conflict') NOT NULL
);
```

**Bedeutung der wichtigsten Spalten:**

- `file_name`: Dateiname ohne vollstaendigen Pfad
- `file_path`: relativer, serverweit eindeutiger Pfad
- `file_size`: Dateigroesse in Bytes
- `hash_value`: SHA-256-Hash zur Inhaltspruefung
- `created_at`: Zeitpunkt der ersten Anlage des Datensatzes
- `last_modified`: Zeitpunkt der letzten Aenderung des Datensatzes
- `file_state`: fachlicher Status fuer die Synchronisationslogik

**Wichtige Designentscheidung:**  
Der `file_path` ist eindeutig. Damit kann die API Dateien eindeutig identifizieren und mit `INSERT ... ON DUPLICATE KEY UPDATE` arbeiten. Das vereinfacht Upserts, macht Verschiebungen aber zu einer bewussten Designfrage, weil ein Pfadwechsel fachlich wie eine neue Datei oder Umbenennung behandelt werden kann.

### Tabelle `SyncEvent`

Diese Tabelle protokolliert relevante Ereignisse zu einer Datei.

```sql
CREATE TABLE IF NOT EXISTS SyncEvent (
    sync_event_id INT AUTO_INCREMENT PRIMARY KEY,
    sync_file_id INT NOT NULL,
    event_type ENUM('new', 'modified', 'deleted', 'error') NOT NULL,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_details TEXT,
    FOREIGN KEY (sync_file_id) REFERENCES SyncFiles(sync_file_id) ON DELETE CASCADE
);
```

**Nutzen der Tabelle:**

- Nachvollziehbarkeit von Datei-Aenderungen
- Grundlage fuer spaetere Auswertungen oder ein Admin-Dashboard
- Trennung zwischen aktuellem Zustand (`SyncFiles`) und Historie (`SyncEvent`)

### Tabelle `FehlerProtokoll`

Diese Tabelle speichert Datenbank- oder Synchronisationsfehler, die serverseitig protokolliert werden sollen.

```sql
CREATE TABLE IF NOT EXISTS FehlerProtokoll (
    fehler_protokoll_id INT AUTO_INCREMENT PRIMARY KEY,
    fehler_beschreibung TEXT NOT NULL,
    fehler_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Warum eine eigene Tabelle?**  
Fachliche Dateiinformationen und technische Fehlermeldungen haben unterschiedliche Verantwortlichkeiten. Durch die Trennung bleibt das Datenmodell sauberer und Fehler koennen separat ausgewertet werden.

### Tabelle `LastSyncState`

Diese Tabelle speichert den letzten bekannten gemeinsamen Synchronisationsstand einer Datei.

```sql
CREATE TABLE IF NOT EXISTS LastSyncState (
    file_path VARCHAR(768) PRIMARY KEY,
    hash_value VARCHAR(64) NOT NULL,
    file_size BIGINT NOT NULL,
    last_synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Warum ist diese Tabelle wichtig?**  
Sie ist die Grundlage fuer die Three-Way-Merge-Logik. Ohne einen letzten gemeinsamen Stand laesst sich nur schwer unterscheiden, ob:

- nur der Client geaendert hat,
- nur der Server geaendert hat,
- beide Seiten geaendert haben,
- oder ob eine Datei geloescht wurde.

**Merksatz:**  
`SyncFiles` beschreibt den **aktuellen Serverzustand**, `LastSyncState` beschreibt den **letzten gemeinsamen Referenzzustand**.

## Zusammenspiel der Tabellen

### 1. Upload

Wenn der Client eine Datei hochlaedt:

- wird die Datei im Dateisystem gespeichert,
- `SyncFiles` wird angelegt oder aktualisiert,
- `LastSyncState` wird auf den neuen gemeinsamen Stand gesetzt.

### 2. Download

Wenn der Client eine Datei vom Server herunterlaedt:

- liefert die API den Dateiinhalt aus,
- `LastSyncState` wird aktualisiert,
- der Client kann danach den lokalen Zustand angleichen.

### 3. Delete

Wenn eine Datei geloescht wird:

- wird die Datei auf dem Server entfernt,
- `SyncFiles.file_state` auf `deleted` gesetzt,
- der Eintrag in `LastSyncState` entfernt.

### 4. Manifest-Abgleich

Beim Manifest-Vergleich wird der Clientzustand mit dem Serverzustand verglichen. Dabei helfen vor allem:

- `file_path`
- `hash_value`
- `last_modified`
- `file_state`

Die API entscheidet daraus, ob eine Datei:

- hochgeladen werden soll,
- heruntergeladen werden soll,
- als geloescht behandelt wird,
- oder in einen Konflikt faellt.

## Server- und Client-Datenbank im Vergleich

### MariaDB auf dem Server

Die Serverdatenbank verwaltet:

- den globalen Datei-Zustand,
- fachliche Statuswerte,
- Fehlerprotokolle,
- den letzten gemeinsamen Sync-Stand.

### SQLite im Python-CLI

Die lokale SQLite verwaltet:

- den lokal gescannten Dateibestand,
- lokale Dateizustaende,
- den lokalen letzten Sync-Stand,
- die Grundlage fuer den naechsten Manifest-Request.

Damit entsteht ein bewusst einfaches, aber gut erklaerbares Zwei-Datenbank-Modell:

- **Serverdatenbank = zentrale Wahrheit des Servers**
- **Clientdatenbank = lokales Arbeitsmodell des Clients**

## Staerken des aktuellen Designs

- einfach genug, um die Synchronisationslogik nachvollziehen zu koennen
- gute Basis fuer Lernzwecke rund um SQL, ADO.NET und Synchronisationsmodelle
- klarer Bezug zwischen Dateisystem, API und Datenbank
- sinnvoll fuer ein Portfolio, weil Entscheidungen offen sichtbar sind

## Aktuelle Grenzen

- keine Benutzer- oder Rechteverwaltung
- keine Versionierung historischer Dateistaende
- Konflikte werden erkannt, aber noch nicht intelligent aufgeloest
- einige Migrationsschritte erfolgen noch manuell ueber SQL-Skripte

## Weiterentwicklung

Spaetere sinnvolle Erweiterungen waeren:

- Benutzer- und Authentifizierungsmodell
- echte Migrationen statt einzelner SQL-Skripte
- staerkere Trennung von technischer und fachlicher Ereignisprotokollierung
- Versionierung oder Revisionshistorie von Dateien
- bessere Auswertungen auf Basis von `SyncEvent`
