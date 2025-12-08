# Datenbankdesign

Das Projekt verwendet MariaDB (MySQL‑Protokoll). Statt eines ORMs werden SQL‑Skripte und ein einfacher ADO.NET‑Service (`MySql.Data` / `MySqlConnector`) genutzt.

## Kernentitäten (Schema‑Übersicht)

### Tabelle: Syncfiles
```sql
CREATE TABLE IF NOT EXISTS SyncFiles (
    sync_file_id INT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(512) NOT NULL,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('pending', 'in_progress', 'completed', 'failed') DEFAULT 'pending',
    UNIQUE(file_path)
    );
```

Hinweis: `State` wird als String gespeichert (z. B. "Modified", "Synced"). Das erleichtert Debugging und Migrationen.

### Tabelle: sync_events
```sql
CREATE TABLE IF NOT EXISTS SyncEvent (
    sync_event_id INT AUTO_INCREMENT PRIMARY KEY,
    sync_file_id INT NOT NULL,
    event_type ENUM('created', 'modified', 'deleted', 'error') NOT NULL,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_details TEXT,
    FOREIGN KEY (sync_file_id) REFERENCES SyncFile(id) ON DELETE CASCADE
    );
```

## Initialisierung / Migration
Da kein ORM verwendet wird, erfolgen Schema‑Änderungen über SQL‑Skripte. Neue/Aktualisierte Skripte werden im Verzeichnis `Database/MariaDB/` abgelegt.

## Anmerkung zur Entscheidung
Direkte ADO.NET‑Zugriffe mit `MySql.Data` geben volle Kontrolle über SQL, erleichtern den Umgang mit spezifischen MariaDB‑Features.
