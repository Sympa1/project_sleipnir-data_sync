from .handlers.sqlite_handler import SqliteHandler


class SyncStateManager:
    """
    Verwaltet den Last Sync State für die Dateisynchronisation.
    Diese Klasse kümmert sich um das Tracking, welche Dateien beim letzten
    erfolgreichen Sync-Vorgang synchronisiert wurden.
    """
    
    def __init__(self):
        self.db_handler = SqliteHandler()
    
    def update_sync_state(self, file_path: str, hash_value: str, file_size: int):
        """
        Aktualisiert oder fügt den Sync-Zustand einer Datei hinzu.
        Wird nach jedem erfolgreichen Download oder Upload aufgerufen.
        
        :param file_path: Relativer Pfad der Datei
        :param hash_value: SHA256-Hash beim letzten Sync
        :param file_size: Dateigröße in Bytes
        """
        query = """
        INSERT INTO LastSyncState (file_path, hash_value, file_size, last_modified)
        VALUES (?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(file_path) 
        DO UPDATE SET 
            hash_value = excluded.hash_value,
            file_size = excluded.file_size,
            last_modified = CURRENT_TIMESTAMP
        """
        self.db_handler.execute_query(query, (file_path, hash_value, file_size))
    
    def get_sync_state(self, file_path: str):
        """
        Holt den letzten Sync-Zustand einer Datei.
        
        :param file_path: Relativer Pfad der Datei
        :return: Tuple (hash_value, file_size, last_synced_at) oder None wenn nicht gefunden
        """
        query = """
        SELECT hash_value, file_size, last_modified 
        FROM LastSyncState 
        WHERE file_path = ?
        """
        result = self.db_handler.execute_query(query, (file_path,))
        return result[0] if result else None
    
    def delete_sync_state(self, file_path: str):
        """
        Löscht den Sync-Zustand einer Datei aus der LastSyncState-Tabelle.
        Wird verwendet wenn eine Datei auf beiden Seiten gelöscht wurde.
        
        :param file_path: Relativer Pfad der Datei
        """
        query = "DELETE FROM LastSyncState WHERE file_path = ?"
        self.db_handler.execute_query(query, (file_path,))
    
    def get_all_synced_files(self):
        """
        Holt alle Dateien aus dem Last Sync State.
        Nützlich zum Erkennen von Dateien, die seit dem letzten Sync gelöscht wurden.
        
        :return: Liste von Tupeln (file_path, hash_value, file_size)
        """
        query = "SELECT file_path, hash_value, file_size FROM LastSyncState"
        return self.db_handler.execute_query(query)
