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


class SyncEventModel:
    """
    Repräsentiert ein Ereignis, das während des Synchronisierungsprozesses aufgetreten ist.
    """
    def __init__(self, id: int, event_type: str, event_timestamp: datetime, event_details: str):
        self.id = id
        self.event_type = event_type
        self.event_timestamp = event_timestamp
        self.event_details = event_details

