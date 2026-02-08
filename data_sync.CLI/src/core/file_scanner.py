import hashlib

from pathlib import Path
from datetime import datetime
from .models import SyncFileModel


class FileScanner:
    """
    Klasse zum Scannen von Dateien in einem Verzeichnis und Sammeln von Datei-Informationen.
    Der Scanner durchsucht rekursiv alle Unterverzeichnisse und erstellt für jede Datei ein SyncFileModel-Objekt.
    Bei der Initialisierung wird das Basisverzeichnis festgelegt.
    """
    def __init__(self, base_path: str):
        """
        Initialisiert den FileScanner mit dem Basisverzeichnis.
        :param base_path:
        """
        self.base_path = Path(base_path).expanduser().resolve()

    def scan_files(self):
        """
        Scannt das Verzeichnis rekursiv und sammelt Informationen über alle Dateien.
        :return: Liste von SyncFileModel-Objekten mit Datei-Informationen
        """
        file_list = []
        # Rekursiv alle Elemente (Dateien + Ordner) im base_path durchlaufen
        # rglob('*') = 'r' für recursive, '*' für alle Dateien/Ordner
        for element in self.base_path.rglob('*'):
            
            # Nur Dateien verarbeiten, Ordner überspringen
            if element.is_file():
                # Datei-Metadaten einmalig auslesen (Performance-Optimierung)
                # stat() gibt Größe, Erstellungsdatum und Änderungsdatum in einem stat_result Objekt zurück
                stats = element.stat()
                
                # SyncFileModel-Objekt mit allen Datei-Informationen erstellen
                sync_file = SyncFileModel(
                    file_name=element.name,  # Nur der Dateiname (z.B. "example1-deleted.txt")
                    file_path=str(element.relative_to(self.base_path)).replace("\\", "/"),  # Normalisiere zu Forward Slashes für plattformübergreifende Kompatibilität
                    file_size=stats.st_size,  # Dateigröße in Bytes
                    hash_value=self.calculate_hash(str(element)),  # SHA256-Hash des Dateiinhalts
                    created_at=datetime.fromtimestamp(stats.st_ctime),  # Erstellungsdatum als DateTime-Objekt
                    last_modified=datetime.fromtimestamp(stats.st_mtime)  # Änderungsdatum als DateTime-Objekt
                )
                file_list.append(sync_file)

        return file_list

    def calculate_hash(self, file_path: str) -> str:
        """
        Berechnet den SHA256-Hash einer Datei.
        :param file_path: Pfad zur Datei
        :return: SHA256-Hash als Hexadezimal-String
        """
        # SHA256-Hasher-Objekt erstellen
        hasher = hashlib.sha256()
        
        # Datei im Binary-Modus öffnen
        with open(file_path, 'rb') as file:
            # Datei in 8KB-Chunks lesen, um Speicher zu schonen
            # Walross-Operator := liest Daten und weist sie chunk zu (in einem Schritt)
            while chunk := file.read(8192):
                # Jeden Chunk zum Hash hinzufügen (inkrementell)
                hasher.update(chunk)
        
        # Fertigen Hash als Hex-String zurückgeben
        return hasher.hexdigest()