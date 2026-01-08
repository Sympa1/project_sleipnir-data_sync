from abc import ABC, abstractmethod
import os
from ..handlers.db_logger import DbLogger
from ..handlers.file_logger import FileLogger

# TODO: Die Erbenden Command-Klassen implementieren und in die main.py integrieren.

class BaseCommand(ABC):
    """
    Abstrakte Basisklasse für alle Command-Klassen.
    Definiert gemeinsame Methoden und erzwingt Implementierung von execute().
    """

    @abstractmethod
    def execute(self):
        """
        Führt den Command aus.
        Muss von jeder abgeleiteten Command-Klasse implementiert werden.
        """
        pass

    def validate_config(self) -> bool:
        """
        Prüft ob die config.json Datei existiert.
        :return: True wenn Config existiert, False sonst
        """
        if not os.path.exists("config.json"):
            error_message = "config.json not found. Please run --init first."
            print(error_message)
            self.handle_error(error_message)
            return False
        return True

    def handle_error(self, error_message: str):
        """
        Zentrale Fehlerbehandlung mit Fallback-Mechanismus.
        Versucht primär in DB zu loggen, bei Fehler Fallback auf File-Logger.
        :param error_message: Fehlerbeschreibung
        """
        try:
            # Primär: In DB loggen
            DbLogger.log(error_message)
        except Exception as db_error:
            # Fallback: In Datei loggen wenn DB nicht erreichbar
            file_logger = FileLogger("error.log")
            file_logger.write_log(f"DB logging failed: {db_error}")
            file_logger.write_log(f"Original error: {error_message}")

    def load_config(self):
        pass