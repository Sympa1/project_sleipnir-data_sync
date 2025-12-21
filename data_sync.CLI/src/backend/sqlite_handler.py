import sqlite3

class SqliteHandler:
    def __init__(self, db_path="cli_db.db"):
        self.db_path = db_path

    def execute_query(self, query, params=None):
        """
        Führt eine SQL-Abfrage aus und gibt die Ergebnisse zurück. Dazu wird eine Verbindung zur SQLite-Datenbank
        hergestellt und anschließend geschlossen.
        Fehler werden abgefangen und protokolliert.
        Beispiel für eine SELECT-Abfrage:
            query = "INSERT INTO users (name, age) VALUES (?, ?)"
                    handler.execute_query(query, ("Max", 25))
        :param query: SQL Abfrage als String
        :param params: Als Tupel übergebene Parameter für die SQL-Abfrage
        :return:
        """
        def execute_query(self, query, params=None):
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