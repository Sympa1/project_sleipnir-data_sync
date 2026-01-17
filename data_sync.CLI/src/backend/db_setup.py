from .handlers.sqlite_handler import SqliteHandler


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

        db_handler = SqliteHandler()

        DbSetup._setup_sync_files(db_handler)
        DbSetup._setup_sync_events(db_handler)
        DbSetup._setup_fehler_protokoll(db_handler)

    @staticmethod
    def _setup_sync_files(db_handler):
        """
        Erstellt die SyncFiles-Tabelle in der Datenbank, falls sie nicht bereits existiert.
        :param db_handler:
        :return: None
        """

        create_table_query = """
        CREATE TABLE IF NOT EXISTS SyncFiles (
            sync_file_id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_name TEXT NOT NULL,
            file_path TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            hash_value TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            last_modified DATETIME DEFAULT CURRENT_TIMESTAMP,
            file_state TEXT NOT NULL CHECK(file_state IN ('new', 'modified', 'unchanged', 'deleted', 'conflict'))
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
            sync_event_id INTEGER PRIMARY KEY AUTOINCREMENT,
            sync_file_id INTEGER NOT NULL,
            event_type TEXT NOT NULL CHECK(event_type IN ('created', 'modified', 'deleted', 'error')),
            event_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
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
            fehler_protokoll_id INTEGER PRIMARY KEY AUTOINCREMENT,
            fehler_beschreibung TEXT NOT NULL,
            fehler_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        """

        db_handler.execute_query(create_table_query)
