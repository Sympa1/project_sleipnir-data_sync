from .base_command import BaseCommand
from ..handlers.config_handler import ConfigHandler
from ..file_scanner import FileScanner
from ..handlers.sqlite_handler import SqliteHandler

import os

class ScanCommand(BaseCommand):
    def execute(self):
        if not self.validate_config():
            config_error = "Configuration validation failed. Aborting scan."
            print(config_error)
            self.handle_error(config_error)
            return

        try:
            print("Scanning directory and updating database with file information...")

            config = ConfigHandler()
            sync_path = config.get_config("sync_path")

            if not sync_path or not os.path.exists(sync_path):
                error_message = f"Sync path '{sync_path}' is invalid or does not exist."
                print(error_message)
                self.handle_error(error_message)
                return

            file_scanner = FileScanner(sync_path)
            file_list = file_scanner.scan_files()


            # TODO:
            #  !!! WICHTIG !!! Ich muss mir noch überlegen wie ich das handhabe wenn die Datei geändert wurde und
            #  der Pfad sich geändert hat (also verschoben wurde).

            db_handler = SqliteHandler()
            for file_info in file_list:
                self._process_file(file_info, db_handler)

            self._mark_deleted_file(file_list, db_handler)

            print("Scan completed successfully.")

        except Exception as e:
            error_message = f"Error during scan process: {e}"
            print(error_message)
            self.handle_error(error_message)

    def _process_file(self, file_info, db_handler):
        # 1. Prüfe: Existiert file_path?
        result_by_path = db_handler.execute_query(
            "SELECT hash_value FROM SyncFiles WHERE file_path = ?",
            (file_info.file_path,)
        )

        # Werte werden als True gewertet
        # Prüft ob die Datei am alten Ort existiert
        if result_by_path:
            db_hash_value = result_by_path[0][0]
            if db_hash_value != file_info.hash_value:
                self._update_file(file_info, db_handler)
            else:
                self._skip_file(file_info, db_handler)

        # Datei existiert nicht am alten Ort
        else:
            # 2. Nicht am alten Ort → Wurde sie verschoben?
            # Prüft anhand des Dateinamens + Hashwerts
            result_by_hash = db_handler.execute_query(
                "SELECT file_path FROM SyncFiles WHERE file_name = ? AND hash_value = ?",
                (file_info.file_name, file_info.hash_value)
            )

            # Datei wurde gefunden, wenn die Variable einen Wert hat
            # Datei wurde verschoben
            if result_by_hash:
                self._update_file_path(db_handler,
                                       old_path=result_by_hash[0][0], # execute_query gibt eine Liste von Tupeln zurück
                                       new_path=file_info.file_path)

            # Datei wurde nicht gefunden
            else:
                # Komplett neue Datei
                self._insert_new_file(file_info, db_handler)


    def _update_file(self, file_info, db_handler):
        """
        Aktualisiert die Datei-Informationen in der Datenbank.
        :param file_info:
        :return:
        """

        query_params = (file_info.file_size,
                        file_info.hash_value,
                        file_info.last_modified,
                        "modified",  # Steht für den Datei-Zustand
                        file_info.file_path)

        query = ("UPDATE SyncFiles SET "
                    "file_size = ?, "
                    "hash_value = ?, "
                    "last_modified = ?, "
                    "file_state = ? "
                 "WHERE file_path = ?")

        db_handler.execute_query(query, query_params)

        print(f"Updated file: {file_info.file_path}")

    def _update_file_path(self, db_handler, old_path, new_path):
        """
        Aktualisiert den Datei-Pfad in der Datenbank.
        :param db_handler:
        :param old_path:
        :param new_path:
        :return:
        """

        query_params = (new_path,
                        "modified",  # Steht für den Datei-Zustand
                        old_path)

        query = ("UPDATE SyncFiles SET "
                    "file_path = ?, "
                    "file_state = ? "
                 "WHERE file_path = ?")

        db_handler.execute_query(query, query_params)

        print(f"Updated file path from {old_path} to {new_path}")

    def _insert_new_file(self, file_info, db_handler):
        """
        Fügt eine neue Datei in die Datenbank ein.
        :param file_info:
        :return:
        """

        query_params = (file_info.file_name,
                        file_info.file_path,
                        file_info.file_size,
                        file_info.hash_value,
                        file_info.created_at,
                        file_info.last_modified,
                        "new")  # Steht für den Datei-Zustand

        query = ("INSERT INTO SyncFiles"
                    "(file_name,"
                    "file_path,"
                    "file_size,"
                    "hash_value,"
                    "created_at,"
                    "last_modified,"
                    "file_state)"
                 "VALUES (?, ?, ?, ?, ?, ?, ?)")

        db_handler.execute_query(query, query_params)

        print(f"Inserted new file: {file_info.file_path}")

    def _mark_deleted_file(self, file_list, db_handler) :
        """
        Markiert die Datei in der Datenbank als gelöscht.
        :param file_list:
        :param db_handler:
        :return:
        """
        file_paths = []
        for file_info in file_list:
            file_paths.append(file_info.file_path)

        query_params = tuple(file_paths)

        # Erstelle dynamische SQL-Platzhalter für alle Dateipfade
        # Bei 3 Dateien: ['?', '?', '?'] → "?,?,?"
        # Wird benötigt für: WHERE file_path NOT IN (?,?,?)
        placeholder = ','.join(['?'] * len(file_paths))

        query = f"UPDATE SyncFiles SET file_state = 'deleted' WHERE file_path NOT IN ({placeholder})"

        db_handler.execute_query(query, query_params)

        query = f"SELECT file_path FROM SyncFiles WHERE file_path NOT IN ({placeholder}) AND file_state = 'deleted'"
        query_result = db_handler.execute_query(query, query_params)
        print(str(query_result))
        if query_result:
            print(f"Marked files as deleted:")
            for row in query_result:
                print(f"- {row[0]}")
        else:
            print("No files to mark as deleted.")


    def _skip_file(self, file_info, db_handler):
        """
        Überspringt die Datei, da keine Änderungen festgestellt wurden.
        :param file_info:
        :param db_handler:
        :return:
        """
        print(f"Skipping {file_info.file_path} - unchanged")