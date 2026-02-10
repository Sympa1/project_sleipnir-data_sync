import sqlite3

from ..models import SyncFileModel, SyncEventModel


class SqliteHandler:
    """
    Klasse zum Umgang mit sqlite-Datenbanken. Wird verwendet, um SQL-Abfragen auszuführen und Ergebnisse zurückzugeben.
    """
    def __init__(self, db_path: str="cli_db.db"):
        """
        Initialisiert den SqliteHandler mit dem Pfad zur sqlite-Datenbank.
        :param db_path: Pfad zur sqlite-Datenbankdatei
        """
        self.db_path = db_path

    def execute_query(self, query: str, params=None):
        """
        Führt eine SQL-Abfrage aus und gibt die Ergebnisse zurück. Dazu wird eine Verbindung zur sqlite-Datenbank
        hergestellt und anschließend geschlossen.
        Fehler werden abgefangen und protokolliert.
        Beispiel für eine SELECT-Abfrage:
            query = "INSERT INTO users (name, age) VALUES (?, ?)"
                    handler.execute_query(query, ("Max", 25))
        :param query: SQL Abfrage als String
        :param params: Als Tupel übergebene Parameter für die SQL-Abfrage
        :return: Eine Liste mit Tupeln als Ergebnis der SQL Abfrage. Jeder Tupel stellt eine Zeile der Abfrage dar.
        """
        try:
            # with ist gleich dem using in C# und sorgt dafür, dass die Verbindung geschlossen wird
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                cursor.execute(query, params or ())
                conn.commit()
                return cursor.fetchall()
        except sqlite3.IntegrityError as e:
            print(f"Integritätsfehler: {e}")
            raise
        except sqlite3.OperationalError as e:
            print(f"Operationsfehler: {e}")
            raise
        except Exception as e:
            print(f"Unbekannter Fehler: {e}")
            raise