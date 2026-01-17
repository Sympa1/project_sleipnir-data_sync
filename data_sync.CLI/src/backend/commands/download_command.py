import urllib3

from pathlib import Path
from .base_command import BaseCommand
from ..handlers.config_handler import ConfigHandler
from .. import ApiClient


class DownloadCommand(BaseCommand):

    # Deaktivieren der InsecureRequestWarning, wenn SSL-Verifikation deaktiviert ist
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    def execute(self, files_to_sync):
        print("\nDownload process started")

        # Aufruf der API um die Dateien herunterzuladen
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

        file_download_success = []
        file_download_failed = []

        for file in files_to_sync:
            # Prüfen, ob die Datei heruntergeladen werden muss
            if file.get("toDownload") is True:
                print(f"Download File: {file.get("fileName")} - File Status: {file.get("changeState")} - File Größe: {file.get("size")} Bytes")

                # Wenn ja Download starten
                try:
                    # API gibt Bytes direkt zurück (kein JSON!)
                    file_content = api_client.download_file(endpoint="download", params={"filePath": file.get("relativePath")})
                    
                    relative_path = file.get("relativePath")
                    full_path = Path(sync_path) / relative_path.lstrip("/\\")  # Entferne führende / oder \ im Pfad

                    # parents = Erstelle alle Notwendigen übergeordneten Verzeichnisse
                    # exist_ok = ignoriere es wenn das Verzeichnis bereits existiert
                    full_path.parent.mkdir(parents=True, exist_ok=True)

                    # Datei speichern
                    full_path.write_bytes(file_content)
                    
                    file_download_success.append(relative_path)


                except Exception as e:
                    error_message = f"Error downloading file {file.get("fileName")}: {str(e)}"
                    print(error_message)
                    self.handle_error(error_message)
                    file_download_failed.append(file.get("fileName"))


            else:
                continue

        print(f"Successful downloads: {len(file_download_success)}")
        print(f"Failed downloads: {len(file_download_failed)}")

        print("Download process completed")