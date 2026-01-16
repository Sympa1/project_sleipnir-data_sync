from .base_command import BaseCommand


class DownloadCommand(BaseCommand):
    def execute(self, files_to_sync):
        print("Download process started")
        for file in files_to_sync:
            # Prüfen, ob die Datei heruntergeladen werden muss

            # Wenn nicht Skipping
            # Wenn ja Download starten
            # Terminalausgabe das Datei XYZ runtergeladen wird
            # Tracken wieviel Downloads erfolgreich waren und wieviel fehlschlugen

        # Ausgabe wieviele Download, von wieviel Downloads erfolgreich waren

        print("Download process completed")