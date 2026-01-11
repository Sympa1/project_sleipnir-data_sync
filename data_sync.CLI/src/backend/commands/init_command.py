from .base_command import BaseCommand
from ..handlers.config_handler import ConfigHandler
from ..db_setup import DbSetup


class InitCommand(BaseCommand):
    """
    Kommand-Klasse zum Initialisieren der Datenbank und Konfigurieren des Synchronisierungspfads.
    1. Initialisiert die Datenbank.
    2. Fordert den Benutzer auf, den Pfad zur Synchronisierung einzugeben.
    3. Speichert den Pfad und die API-Basis-URL in der Konfigurationsdatei.
    4. Behandelt Fehler und gibt entsprechende Meldungen aus.
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

            print("\n\n Please configure your path to sync in config.json before proceeding.")
            path = input("Enter the path to sync: ")
            # TODO: Die Hardcoded URL durch die Benutzereingabe ersetzen
            # api_base_url = input("Enter the api base url: ")
            api_base_url = "https://localhost:7169/api/sync"

            config = ConfigHandler()
            config.set_config("api_base_url", api_base_url)
            config.set_config("sync_path", path)
            print(f"Sync path '{path}' saved to config.json.")
        except Exception as e:
            error_message = f"Error during initialization: {e}"
            print(error_message)
            self.handle_error(error_message)