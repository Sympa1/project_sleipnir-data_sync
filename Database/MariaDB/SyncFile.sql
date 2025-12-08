CREATE TABLE IF NOT EXISTS SyncFile (
    sync_file_id INT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(512) NOT NULL,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('pending', 'in_progress', 'completed', 'failed') DEFAULT 'pending',
    UNIQUE(file_path)
);

CREATE TABLE IF NOT EXISTS SyncEvent (
    sync_event_id INT AUTO_INCREMENT PRIMARY KEY,
    sync_file_id INT NOT NULL,
    event_type ENUM('created', 'modified', 'deleted', 'error') NOT NULL,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_details TEXT,
    FOREIGN KEY (sync_file_id) REFERENCES SyncFile(id) ON DELETE CASCADE
);