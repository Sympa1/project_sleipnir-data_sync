import hashlib
from pathlib import Path
from datetime import datetime

class FileScanner:
    def __init__(self, base_path: str):
        self.base_path = base_path

    def scan_files(self):
        """
        Scannt das Verzeichnis und sammelt Informationen über alle Dateien.
        :return:
        """
        pass

    def calculate_hash(self, file_path: str):
        """
        Berechnet den Hashwert einer Datei.
        :param file_path:
        :return:
        """
        pass