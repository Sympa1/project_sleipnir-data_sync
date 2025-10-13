--=============================================
--|                                           |
--| Enthält alle Tabellen der MySQL Datenbank |
--|                                           |
--=============================================

CREATE TABLE file (
    file_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    -- Für später user_id INTEGER REFERENCES user(user_id),
    path TEXT NOT NULL UNIQUE, --Pfad vom Sync-Root-Verzeichnis
    size INTEGER NOT NULL, -- Dateigröße in Bytes
    modification_time DATETIME DEFAULT NULL, -- Timestamp wann die Datei geändert wurde
    created_at DATETIME DEFAULT NOT NULL, -- Timestamp wann die Datei erstellt wurde
    hash TEXT NOT NULL, -- Hash der Datei
    state CHAR(15) ENUM('synced', 'modified', 'conflict', 'deleted'), -- Zustand der Datei
    updated_at DATETIME -- Wann wurde die Datei das letzte mal geupdatet
    contetent_url TEXT
);

CREATE TABLE sync_events(
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id INTEGER REFERENCES files(file_id),
    -- Für später device_id INTEGER REFERENCES device(device_id),
    action CHAR(15) ENUM('download', 'upload', 'conflict', 'delete', 'error'), -- Was wurde beim synchronisieren gemacht
    timestamp TEXT,
    details TEXT -- Sonstige Infos
);