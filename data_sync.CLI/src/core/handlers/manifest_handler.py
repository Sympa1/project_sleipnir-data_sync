import json

from datetime import datetime
from .sqlite_handler import SqliteHandler
from ..api_client import ApiClient
from .config_handler import ConfigHandler


class ManifestHandler:
    """
    Klasse zum Erstellen und Senden von Manifests für die Datensynchronisation.
    Das Manifest wird aus Daten in der sqlite-Datenbank erstellt und an eine API gesendet.
    """
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

        # SQL Abfrage zum Abrufen aller Datensätze

        # Ausfphrung der Abfrage und Speichern der Ergebnisse in einer Variable

        # manifest Array initialisieren
        # Manifest enthält alle Datensätze als Liste von Objekten
        manifest = []

        # Durchlaufen der Datensätze und Hinzufügen zum Manifest mitztels for Schleife

        return manifest

    def send_manifest(self):
        """
        Sendet das Manifest an die API.
        :param: None
        :return: API-Antwort als JSON
        """
        manifest = self.create_manifest()
        response = self.api.post("/manifest", json=manifest)
        return response.json()