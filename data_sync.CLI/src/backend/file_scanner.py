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

    def calculate_hash(self, file_path: str) -> str:
        """
        Berechnet den SHA256-Hash einer Datei.
        :param file_path: Pfad zur Datei
        :return: SHA256-Hash als Hexadezimal-String
        """
        # SHA256-Hasher-Objekt erstellen
        hasher = hashlib.sha256()
        
        # Datei im Binary-Modus öffnen
        with open(file_path, 'rb') as f:
            # Datei in 8KB-Chunks lesen, um Speicher zu schonen
            # Walross-Operator := liest Daten und weist sie chunk zu (in einem Schritt)
            while chunk := f.read(8192):
                # Jeden Chunk zum Hash hinzufügen (inkrementell)
                hasher.update(chunk)
        
        # Fertigen Hash als Hex-String zurückgeben
        return hasher.hexdigest()