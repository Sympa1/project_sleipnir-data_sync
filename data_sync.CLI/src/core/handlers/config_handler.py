import json
import os


class ConfigHandler:
    """
    Klasse zum Lesen und Schreiben von Konfigurationsdaten in einer JSON-Datei.
    """
    def __init__(self, filename = "config.json"):
        """
        Initialisiert den ConfigHandler mit dem Pfad zur Konfigurationsdatei und lädt die Configdatei.
        Es können mit dem Objekt sofort die Methoden zum Lesen und Schreiben der Konfiguration verwendet werden.
        :param filename:
        """
        self.filename = filename
        self.data = {}
        self.load_json() # lädt automatisch die Config beim Erstellen des Objektes

    def load_json(self):
        """Liest das JSON File ein. Wenn die Datei nicht existiert, wird eine neue erstellt.
        :return: None
        """
        if not os.path.exists(self.filename):
            self.data = {} # Oder Standardwerte hier setzen
            self.save_config()
        else:
            with open(self.filename, 'r') as f:
                self.data = json.load(f)

    def save_config(self):
        """Speichert die Werte im JSON File.
        :return: None
        """
        with open(self.filename, 'w') as f:
            json.dump(self.data, f, indent=2)

    def get_config(self, key):
        """Gibt den Wert für den angegebenen Schlüssel zurück, oder None, wenn der Schlüssel nicht existiert.
        :param key: Schlüssel der Konfiguration
        :return: Wert der Konfiguration oder None
        """
        return self.data.get(key)

    def set_config(self, key, value):
        """Setzt den Wert für den angegebenen Schlüssel und speichert die Konfiguration.
        :param key: Schlüssel der Konfiguration
        :param value: Wert der Konfiguration
        :return: None
         """
        self.data[key] = value
        self.save_config()