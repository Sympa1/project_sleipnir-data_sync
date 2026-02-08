import os
from .base_command import BaseCommand
from ..handlers.config_handler import ConfigHandler
from .. import ApiClient
from ..sync_state_manager import SyncStateManager


class UploadCommand(BaseCommand):
    """
    Command zum Hochladen von Dateien auf den Remote-Server.
    """
    def execute(self, files_to_sync):
        """
        Startet den Upload-Prozess für die angegebenen Dateien.
        :param files_to_sync:
        :return:
        """
        print("\nUpload process started")

        # Aufruf der API um die Dateien hochzuladen
        config_handler = ConfigHandler()
        sync_path = config_handler.get_config("sync_path")
        api_base_url = config_handler.get_config("api_base_url")
        verify_ssl = config_handler.get_config("verify_ssl")
        if verify_ssl is None:
            verify_ssl = True  # Default: SSL-Verifikation aktiviert

        if verify_ssl is False:
            print("Warning: SSL verification is disabled.")

        api_client = ApiClient(api_base_url, verify_ssl)
        print(f"Using API base URL: {api_base_url}")

        file_upload_success = []
        file_upload_failed = []

        for file in files_to_sync:
            # Prüfen, ob die Datei hochgeladen werden muss
            if file.get("toUpload") is True:
                print(f"Upload File: {file.get('fileName')} - File Status: {file.get('changeState')} - File Größe: {file.get('size')} Bytes")

                # Wenn ja Upload starten
                try:
                    relative_path = file.get("relativePath")
                    full_path = f"{sync_path}/{relative_path.lstrip('/\\')}"  # Entferne führende / oder \ im Pfad

                    # Dateiinhalt lesen
                    with open(full_path, "rb") as f:
                        file_content = f.read()

                    # Extrahiere nur den Verzeichnis-Teil (ohne Dateinamen)
                    relative_dir = os.path.dirname(relative_path)

                    # API-Aufruf zum Hochladen der Datei
                    response = api_client.upload_files(
                        endpoint="upload",
                        files={"file": (file.get("fileName"), file_content)},
                        params={"basePath": relative_dir})

                    if response.get("status") == "success":
                        # LastSyncState aktualisieren nach erfolgreichem Upload
                        sync_state_manager = SyncStateManager()
                        sync_state_manager.update_sync_state(
                            file_path=file.get("relativePath"),
                            hash_value=file.get("sha256"),
                            file_size=file.get("size")
                        )
                        
                        file_upload_success.append(file)
                    else:
                        error_upload = f"Failed to upload file: {file.get('fileName')} - Reason: {response.get('message')}"
                        print(error_upload)
                        self.handle_error(error_upload)
                        file_upload_failed.append(file)

                except Exception as e:
                    error_message = f"Error uploading file: {file.get('fileName')} - Error: {str(e)}"
                    print(error_message)
                    file_upload_failed.append(file)