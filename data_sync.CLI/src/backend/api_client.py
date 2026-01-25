import requests
import json


class ApiClient:
    """
    Ein einfacher API-Client zur Kommunikation mit einer RESTful API.
    Unterstützt GET, POST, PUT, DELETE Anfragen sowie Datei-Uploads und -Downloads.
    Anhand der Base-URL wird zwischen http und https unterschieden.
    """
    def __init__(self, base_url: str, verify_ssl: bool = True):
        """
        Initialisiert den ApiClient mit der Basis-URL der API.
        :param base_url: Basis-URL der API
        :param verify_ssl: SSL-Zertifikatsverifizierung aktivieren (Default: True für Sicherheit)
        """
        self.base_url = base_url
        self.verify_ssl = verify_ssl

    def get(self, endpoint: str, params=None):
        """
        Führt eine GET-Anfrage an die API durch.
        :param endpoint: API-Endpunkt
        :param params: Query-Parameter als Dictionary (z.B. {"filePath": "path/to/file.txt"})
        :return: Antwort der API als JSON
        """
        response = requests.get(f"{self.base_url}/{endpoint}", params=params, verify=self.verify_ssl)
        response.raise_for_status()  # Hebt eine Ausnahme bei HTTP-Fehlern hervor
        return response.json()

    def post(self, endpoint: str, json=None, params=None):
        """
        Führt eine POST-Anfrage an die API durch.
        :param endpoint: API-Endpunkt
        :param json: JSON-Daten als Dictionary oder Liste (z.B. [{"FilePath": "...", "Hashvalue": "..."}])
        :param params: Query-Parameter als Dictionary (z.B. {"version": "1.0"})
        :return: Antwort der API als JSON
        """
        url = f"{self.base_url}/{endpoint}"
        
        response = requests.post(url, json=json, params=params, verify=self.verify_ssl)
        
        response.raise_for_status()  # Hebt eine Ausnahme bei HTTP-Fehlern hervor
        return response.json()

    def put(self, endpoint: str, data=None, params=None):
        """
        Führt eine PUT-Anfrage an die API durch.
        :param endpoint: API-Endpunkt
        :param data: JSON-Daten als Dictionary oder Liste
        :param params: Query-Parameter als Dictionary
        :return: Antwort der API als JSON
        """
        response = requests.put(f"{self.base_url}/{endpoint}", json=data, params=params, verify=self.verify_ssl)
        response.raise_for_status()  # Hebt eine Ausnahme bei HTTP-Fehlern hervor
        return response.json()

    def delete(self, endpoint: str, params=None):
        """
        Führt eine DELETE-Anfrage an die API durch.
        :param endpoint: API-Endpunkt
        :param params: Query-Parameter als Dictionary (z.B. {"filePath": "path/to/file.txt"})
        :return: Antwort der API als JSON
        """
        response = requests.delete(f"{self.base_url}/{endpoint}", params=params, verify=self.verify_ssl)
        response.raise_for_status()  # Hebt eine Ausnahme bei HTTP-Fehlern hervor
        return response.json()

    def upload_files(self, endpoint: str, files, params=None):
        """
        Führt eine POST-Anfrage mit Datei-Upload an die API durch.
        :param endpoint: API-Endpunkt
        :param files: Dictionary mit Dateien für multipart/form-data (z.B. {"files": [open("file.txt", "rb"), ...]})
        :param params: Query-Parameter (z.B. {"basePath": "folder/subfolder"})
        :return: Antwort der API als JSON
        """
        response = requests.post(f"{self.base_url}/{endpoint}", files=files, params=params, verify=self.verify_ssl)
        response.raise_for_status()
        return response.json()

    def download_file(self, endpoint: str, params=None):
        """
        Führt eine GET-Anfrage zum Download einer Datei durch.
        :param endpoint: API-Endpunkt
        :param params: Query-Parameter (z.B. {"filePath": "folder/file.txt"})
        :return: Binärdaten der Datei
        """
        response = requests.get(f"{self.base_url}/{endpoint}", params=params, verify=self.verify_ssl)
        response.raise_for_status()
        return response.content
