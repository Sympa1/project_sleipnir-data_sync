from .base_command import BaseCommand
from ..handlers.config_handler import ConfigHandler
from ..db_setup import DbSetup


class InitCommand(BaseCommand):
    """
    Kommand-Klasse zum Initialisieren der Datenbank und Konfigurieren des Synchronisierungspfads.
    """
    def execute(self):
        """
        Führt den Initialisierungsprozess aus.
        :return:
        """
        try:
            print("Initializing database...")
            DbSetup.setup_db()
            print("Database initialized successfully.")

            print("\n\nPlease provide the following configuration values:")

            path = input("Enter the path to sync: ")
            api_base_url = input("Enter the API base URL (e.g. https://192.168.0.1:5001/api/sync): ")
            ssl_cert_path = input("Enter the path to the SSL certificate (leave empty to disable verification): ")

            # SSL-Einstellung: Zertifikatspfad verwenden falls angegeben, sonst Verifikation deaktivieren
            verify_ssl = ssl_cert_path if ssl_cert_path.strip() else False

            config = ConfigHandler()
            config.set_config("sync_path", path)
            config.set_config("api_base_url", api_base_url)
            config.set_config("verify_ssl", verify_ssl)

            print(f"\nConfiguration saved to config.json:")
            print(f"  Sync path:   {path}")
            print(f"  API URL:     {api_base_url}")
            print(f"  SSL verify:  {verify_ssl}")
        except Exception as e:
            error_message = f"Error during initialization: {e}"
            print(error_message)
            self.handle_error(error_message)