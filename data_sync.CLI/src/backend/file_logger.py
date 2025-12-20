from datetime import datetime

class FileLogger:
    """
    Eine einfache Datei-Logger-Klasse zum Schreiben von Log-Nachrichten in eine Datei.
    """
    def __init__(self, file_name:str = "error.log"):
        self.file_name = file_name

    def write_log(self, message: str):
        """
        Estellt oder öffnet die Log-Datei und schreibt eine Log-Nachricht mit Zeitstempel.
        :param message: str
        :return:
        """
        """Schreibt eine Log-Nachricht in die Log-Datei mit Zeitstempel."""
        with open(self.file_name, 'a') as log_file:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            log_file.write(f"[{timestamp}]\nERROR: {message}\n")
