DROP TABLE IF EXISTS SyncEvent;
DROP TABLE IF EXISTS SyncFiles;
DROP TABLE IF EXISTS FehlerProtokoll;

CREATE TABLE IF NOT EXISTS SyncFiles (
    sync_file_id INT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(1024) NOT NULL,
    file_size BIGINT NOT NULL,
    hash_value VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    file_state ENUM('new', 'modified', 'unchanged', 'deleted', 'conflict') NOT NULL
);

CREATE TABLE IF NOT EXISTS SyncEvent (
    sync_event_id INT AUTO_INCREMENT PRIMARY KEY,
    sync_file_id INT NOT NULL,
    event_type ENUM('created', 'modified', 'deleted', 'error') NOT NULL,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_details TEXT,
    FOREIGN KEY (sync_file_id) REFERENCES SyncFiles(sync_file_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS FehlerProtokoll (
    fehler_protokoll_id INT AUTO_INCREMENT PRIMARY KEY,
    fehler_beschreibung TEXT NOT NULL,
    fehler_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);