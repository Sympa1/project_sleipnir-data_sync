from .sqlite_handler import SqliteHandler as sh

class DbSetup:
    """
    Klasse zum Einrichten der Datenbanktabellen für die Dateisynchronisation.
    1. SyncFiles: Speichert Informationen über die zu synchronisierenden Dateien.
    2. SyncEvent: Protokolliert Ereignisse im Zusammenhang mit der Dateisynchronisation.
    3. FehlerProtokoll: Speichert Fehlerprotokolle.
    """

    @staticmethod
    def setup_db():
        """
        Initialisiert die DbSetup-Klasse und richtet die Datenbanktabellen ein.
        1. Ruft die Methode zum Einrichten der SyncFiles-Tabelle auf.
        2. Ruft die Methode zum Einrichten der SyncEvent-Tabelle auf.
        3. Ruft die Methode zum Einrichten der FehlerProtokoll-Tabelle auf
        """

        db_handler = sh.SqliteHandler()

        DbSetup.setup_sync_files(db_handler)
        DbSetup.setup_sync_events(db_handler)
        DbSetup.setup_fehler_protokoll(db_handler)

    @staticmethod
    def _setup_sync_files(db_handler):
        """
        Erstellt die SyncFiles-Tabelle in der Datenbank, falls sie nicht bereits existiert.
        :param db_handler:
        :return: None
        """

        create_table_query = """
        CREATE TABLE IF NOT EXISTS SyncFiles (
            sync_file_id INT AUTO_INCREMENT PRIMARY KEY,
            file_name VARCHAR(255) NOT NULL,
            file_path VARCHAR(1024) NOT NULL UNIQUE ,
            file_size BIGINT NOT NULL,
            hash_value VARCHAR(64) NOT NULL, -- sha256 hash
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            file_state ENUM('new', 'modified', 'unchanged', 'deleted', 'conflict') NOT NULL
        );
        """

        db_handler.execute_query(create_table_query)

    @staticmethod
    def _setup_sync_events(db_handler):
        """
        Erstellt die SyncEvent-Tabelle in der Datenbank, falls sie nicht bereits existiert.
        :param db_handler:
        :return: None
        """

        create_table_query = """
        CREATE TABLE IF NOT EXISTS SyncEvent (
            sync_event_id INT AUTO_INCREMENT PRIMARY KEY,
            sync_file_id INT NOT NULL,
            event_type ENUM('created', 'modified', 'deleted', 'error') NOT NULL,
            event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            event_details TEXT,
            FOREIGN KEY (sync_file_id) REFERENCES SyncFiles(sync_file_id) ON DELETE CASCADE
        );
        """

        db_handler.execute_query(create_table_query)

    @staticmethod
    def _setup_fehler_protokoll(db_handler):
        """
        Erstellt die FehlerProtokoll-Tabelle in der Datenbank, falls sie nicht bereits existiert.
        :param db_handler:
        :return: None
        """

        create_table_query = """
        CREATE TABLE IF NOT EXISTS FehlerProtokoll (
            fehler_protokoll_id INT AUTO_INCREMENT PRIMARY KEY,
            fehler_beschreibung TEXT NOT NULL,
            fehler_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """

        db_handler.execute_query(create_table_query)

DbSetup.setup_db()