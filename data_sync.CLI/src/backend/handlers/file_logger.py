from datetime import datetime


class FileLogger:
    """
    Klasse zum Schreiben von Log-Nachrichten in eine Datei mit Zeitstempel.
    Der Dateiname kann beim Erstellen der Klasse angegeben werden.
    Standardmäßig wird "error.log" verwendet.
    """
    def __init__(self, file_name:str = "error.log"):
        self.file_name = file_name

    def write_log(self, message: str):
        """
        Estellt oder öffnet die Log-Datei und schreibt eine Log-Nachricht mit Zeitstempel.
        Der Typ der Nachricht wird aus dem Dateinamen abgeleitet.
        :param message: str
        :return: None
        """

        # Durch Split entsteht eine Liste, erstes Element ist der Typ
        message_type = self.file_name.split(".")[0].upper() + ": "

        with open(self.file_name, 'a') as log_file:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            log_file.write(f"[{timestamp}]\n {message_type} {message}\n")

        print(f"📑 [{timestamp}] {message_type} {message}\n")
