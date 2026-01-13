from datetime import datetime


class SyncFileModel:
    """
    Repräsentiert eine Datei, die sich im Synchronisierungspfad befindet.
    """
    def __init__(self, file_name: str, file_path: str, file_size: int, hash_value: str,
                 created_at: datetime, file_state: str = None       , last_modified: datetime  = None, sync_event: list = None, id: int = None):
        self.id = id
        self.file_name = file_name
        self.file_path = file_path
        self.file_size = file_size
        self.hash_value = hash_value
        self.created_at = created_at
        self.last_modified = last_modified
        self.file_state = file_state

        # Die Variable sync_event wird als leere Liste initialisiert, wenn kein Wert übergeben wird.
        # Die Liste soll SyncEventModel-Objekte enthalten, die mit dieser Datei verknüpft sind.
        if sync_event is None:
            self.sync_event = []
        else:
            self.sync_event = sync_event

    def to_dict(self):
        """
        Konvertiert das SyncFileModel-Objekt in ein Wörterbuch. Das Datum wird im ISO Format zurückgegeben.
        Ausgenommen sind hier die SyncEventModel-Objekte in der sync_event Liste.
        :return: Wörterbuch mit den Attributen des Objekts.
        """
        # Konvertiere String zu datetime falls nötig
        from datetime import datetime
        
        created_dt = self.created_at if isinstance(self.created_at, datetime) else datetime.fromisoformat(self.created_at) if self.created_at else None
        modified_dt = self.last_modified if isinstance(self.last_modified, datetime) else datetime.fromisoformat(self.last_modified) if self.last_modified else None
        
        return {
            "fileName": self.file_name,
            "relativePath": self.file_path,
            "size": self.file_size,
            "sha256": self.hash_value,
            "createdAt": created_dt.isoformat() if created_dt else None,
            "lastModifiedUtc": modified_dt.isoformat() if modified_dt else None,
            "changeState": self.file_state
        }


class SyncEventModel:
    """
    Repräsentiert ein Ereignis, das während des Synchronisierungsprozesses aufgetreten ist.
    """
    def __init__(self, id: int, event_type: str, event_timestamp: datetime, event_details: str):
        self.id = id
        self.event_type = event_type
        self.event_timestamp = event_timestamp
        self.event_details = event_details
