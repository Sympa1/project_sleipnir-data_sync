from dns.resolver import query

from .base_command import BaseCommand
from ..handlers.config_handler import ConfigHandler
from ..handlers.sqlite_handler import SqliteHandler
from ..api_client import ApiClient
from ..models import SyncFileModel


class ManifestCommand(BaseCommand):
    def execute(self):
        """
        Führt den Manifest-Befehl aus.
        :return:
        """
        if not self.validate_config():
            config_error = "Configuration validation failed. Aborting manifest processing."
            print(config_error)
            self.handle_error(config_error)
            return

        try:
            print("\nStarting manifest processing...")

            # Datenbankverbindung herstellen
            db_handler = SqliteHandler()

            if not db_handler:
                raise ConnectionError("Failed to connect to the database.")

            print("Database connection established successfully.")

            # API URL aus der Konfiguration laden
            config_handler = ConfigHandler()
            api_base_url = config_handler.get_config("api_base_url")

            if not api_base_url:
                raise ValueError("API base URL is not configured.")

            print(f"Using API base URL: {api_base_url}")

            # API Client initialisieren
            api_client = ApiClient(api_base_url)

            if not api_client:
                raise ValueError("Failed to initialize API client.")

            print("Connected to API client successfully.")

            # Manifest erstellen und senden
            manifest = self.create_manifest(db_handler)
            manifest_response = self.send_manifest(api_client, manifest)

            print("\n" + "=" * 80)
            print("Manifest processing completed successfully.")

        except Exception as e:
            error_message = f"Error during manifest processing: {e}"
            print(error_message)
            self.handle_error(error_message)

    def create_manifest(self, db_handler):
        manifest = []

        query = ("SELECT file_name, "
                    " file_path, "
                    "file_size, "
                    "hash_value, "
                    "created_at, "
                    "last_modified, "
                    "file_state "
                 "FROM SyncFiles"
                 "WHERE file_state != 'conflict'")

        query_result = db_handler.execute_query(query)

        for row in query_result:
            manifest.append({
                "FileName": row[0],
                "FilePath": row[1],
                "FileSize": row[2],
                "HashValue": row[3],
                "CreatedAt": row[4],
                "LastModified": row[5],
                "FileState": row[6]
            })

        return manifest

    def send_manifest(self, api_client, manifest):
        response = []

        return response