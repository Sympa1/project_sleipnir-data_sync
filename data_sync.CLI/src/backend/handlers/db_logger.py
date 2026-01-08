from .sqlite_handler import SqliteHandler

class DbLogger:
    """Eine Klasse zum Protokollieren von Nachrichten in der Datenbank."""
    @staticmethod
    def log(fehler_beschreibung: str):
        """
        Protokolliert eine Nachricht in der Datenbank.
        :param fehler_beschreibung: str
        :return:
        """
        db_handler = SqliteHandler()
        query = "INSERT INTO FehlerProtokoll (fehler_beschreibung) VALUES (?)"
        db_handler.execute_query(query, (fehler_beschreibung, ))