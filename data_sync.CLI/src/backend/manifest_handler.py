import json
from datetime import datetime
from .sqlite_handler import SqliteHandler
from .api_client import ApiClient
from .config_handler import ConfigHandler
from .models import Manifest

class ManifestHandler:
    def __init__(self):
        self.db_handler = SqliteHandler()
        self.config_handler = ConfigHandler()
        self.api = ApiClient(self.config_handler.get_config("api_base_url"))

    def create_manifest(self) -> str:
        """
        Erstellt das Manifest für die Datensynchronisation.
        Holt alle Daten aus der DB, erstellt ein Manifest-Objekt und serialisiert es zu JSON.
        :return: JSON-String des Manifests
        """
        files = self.db_handler.get_all_sync_files_with_events()
        
        manifest = Manifest(
            files=files,
            timestamp=datetime.now().isoformat()
        )
        
        return json.dumps(manifest.to_dict(), indent=2)

    def send_manifest(self):
        """
        Sendet das Manifest an die API.
        :param: None
        :return: API-Antwort als JSON
        """
        response = self.api.post("manifest", data=self.create_manifest())
        return response