# Datenbankdesign

## Datei Metadaten
#### Wichtige Attribute einer Datei

| Attribut          | Bedeutung                                                       |
| ----------------- | --------------------------------------------------------------- |
| modifacation_time | *Modifacation Time* - wann der Inhalt zuletzt<br>geändert wurde |
| creation_time     | Erstellzeitpunkt der Datei                                      |
| hash              | Fingerabdruck der Datei                                         |
| size              | Dateigröße in Bytes                                             |
| path              | Dateipfad                                                       |
## SQLite Database

#### Tabelle: file
```sql
CREATE TABLE file (
    file_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    -- Für später user_id INTEGER REFERENCES user(user_id),
    path TEXT NOT NULL, -- Pfad vom Sync-Root-Verzeichnis
    size INTEGER NOT NULL, -- Dateigroeße in Bytes
    modification_time DATETIME DEFAULT NULL, -- Timestamp wann die Datei geändert wurde
    created_at DATETIME NOT NULL, -- Timestamp wann die Datei erstellt wurde
    hash TEXT NOT NULL, -- Hash der Datei
    state ENUM('synced', 'modified', 'conflict', 'deleted'), -- Zustand der Datei
    updated_at DATETIME -- Wann wurde die Datei das letzte mal geupdatet
);
```

#### Tabelle: sync_log
```sql
CREATE TABLE sync_events(
    log_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    file_id INTEGER REFERENCES files(file_id),
    -- Für später device_id INTEGER REFERENCES device(device_id),
    action ENUM('download', 'upload', 'conflict', 'delete', 'error'), -- Was wurde beim synchronisieren gemacht
    timestamp TEXT,
    details TEXT -- Sonstige Infos
);
```
## MySQL Database

#### Tabelle: file
```sql
CREATE TABLE file (
	file_id INTEGER PRIMARY KEY AUTOINCREMENT, 
	-- Für später user_id INTEGER REFERENCES user(user_id),
	path TEXT NOT NULL UNIQUE, --Pfad vom Sync-Root-Verzeichnis
	size INTEGER NOT NULL, -- Dateigröße in Bytes
	modifacation_time DATETIME DEFAULT NULL, -- Timestamp wann die Datei geändert wurde
	created_at DATETIME NOT NULL, -- Timestamp wann die Datei erstellt wurde
	hash TEXT NOT NULL, -- Hash der Datei
	state CHAR(15) ENUM('synced', 'modified', 'conflict', 'deleted') DEFAULT 'modified', -- Zustand der Datei
	updated_at DATETIME -- Wann wurde die Datei das letzte mal geupdatet
	content_url TEXT
);
```

#### Tabelle: sync_events
```sql
CREATE TABLE sync_events(
	log_id INTEGER PRIMARY KEY AUTOINCREMENT,
	file_id INTEGER REFERENCES files(file_id),
	-- Für später device_id INTEGER REFERENCES device(device_id),
	action CHAR(15) ENUM('download', 'upload', 'conflict', 'delete', 'error'), -- Was wurde beim synchronisieren gemacht
	timestamp TEXT,
	details TEXT -- Sonstige Infos
);
```