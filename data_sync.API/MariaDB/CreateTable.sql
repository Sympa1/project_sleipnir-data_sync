DROP TABLE IF EXISTS SyncEvent;
DROP TABLE IF EXISTS FehlerProtokoll;
DROP TABLE IF EXISTS SyncFiles;

CREATE TABLE IF NOT EXISTS SyncFiles (
    sync_file_id INT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(1024) NOT NULL,
    file_size BIGINT NOT NULL,
    hash_value VARCHAR(64) NOT NULL, -- sha256 hash
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

INSERT INTO SyncFiles (file_name, file_path, file_size, hash_value, file_state) VALUES
('example.txt', '/path/to/example.txt', 1024, 'dd2d2d2d22d2d2d2d2', 'new'),
('sample.jpg', '/path/to/sample.jpg', 2048, 'e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3', 'modified');