import hashlib
from pathlib import Path
from datetime import datetime
from .models import SyncFileModel

class FileScanner:
    def __init__(self, base_path: str):
        self.base_path = Path(base_path).expanduser().resolve()

    def scan_files(self):
        """
        Scannt das Verzeichnis und sammelt Informationen über alle Dateien.
        :return:
        """
        # Rekursiv alle Elemente (Dateien + Ordner) im base_path durchlaufen
        # rglob('*') = 'r' für recursive, '*' für alle Dateien/Ordner
        for element in self.base_path.rglob('*'):
            
            # Nur Dateien verarbeiten, Ordner überspringen
            if element.is_file():
                # Datei-Metadaten einmalig auslesen (Performance-Optimierung)
                # stat() gibt Größe, Erstellungsdatum und Änderungsdatum zurück
                stats = element.stat()
                
                # SyncFileModel-Objekt mit allen Datei-Informationen erstellen
                sync_file = SyncFileModel(
                    file_name=element.name,  # Nur der Dateiname (z.B. "example1.txt")
                    file_path=str(element.relative_to(self.base_path)),  # Relativer Pfad (z.B. "unterverzeichnis1/datei.txt")
                    file_size=stats.st_size,  # Dateigröße in Bytes
                    hash_value=self.calculate_hash(str(element)),  # SHA256-Hash des Dateiinhalts
                    created_at=datetime.fromtimestamp(stats.st_ctime),  # Erstellungsdatum als DateTime-Objekt
                    last_modified=datetime.fromtimestamp(stats.st_mtime)  # Änderungsdatum als DateTime-Objekt
                )
                
                # TODO: sync_file zu einer Liste hinzufügen
                # TODO: Liste in die Datenbank schreiben

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
        with open(file_path, 'rb') as file:
            # Datei in 8KB-Chunks lesen, um Speicher zu schonen
            # Walross-Operator := liest Daten und weist sie chunk zu (in einem Schritt)
            while chunk := file.read(8192):
                # Jeden Chunk zum Hash hinzufügen (inkrementell)
                hasher.update(chunk)
        
        # Fertigen Hash als Hex-String zurückgeben
        return hasher.hexdigest()

if __name__ == "__main__":
    file_scanner = FileScanner("~/dev/data_sync.CLI/test_data")

    # / Operator fügt Pfadkomponenten zusammen und nutzt automatisch das OS-spezifische Trennzeichen (\ unter Windows, / unter Linux)
    file_hash = file_scanner.calculate_hash(str(file_scanner.base_path / "example.txt"))

    print(f"SHA256 Hash: {file_hash}")