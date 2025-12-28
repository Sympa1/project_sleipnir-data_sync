CREATE TABLE IF NOT EXISTS SyncFiles (
    sync_file_id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL UNIQUE,
    file_size INTEGER NOT NULL,
    hash_value TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_modified DATETIME DEFAULT CURRENT_TIMESTAMP,
    file_state TEXT NOT NULL CHECK(file_state IN ('new', 'modified', 'unchanged', 'deleted', 'conflict'))
);

CREATE TABLE IF NOT EXISTS SyncEvent (
    sync_event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sync_file_id INTEGER NOT NULL,
    event_type TEXT NOT NULL CHECK(event_type IN ('created', 'modified', 'deleted', 'error')),
    event_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    event_details TEXT,
    FOREIGN KEY (sync_file_id) REFERENCES SyncFiles(sync_file_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS FehlerProtokoll (
    fehler_protokoll_id INTEGER PRIMARY KEY AUTOINCREMENT,
    fehler_beschreibung TEXT NOT NULL,
    fehler_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);