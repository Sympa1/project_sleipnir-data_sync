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


            # TODO: Wie speicher ich die Datei-Informationen in der DB, unter berücksichtigung von Datei-Zuständen
            #  (neu, geändert, gelöscht, unverändert, Konflikt)?
            #  Sprich vergleich mit bestehenden DB-Einträgen und entsprechende Updates/Einfügungen/Löschungen durchführen.
            db_handler = SqliteHandler()

            for file_info in file_list:
                query_params =  (file_info.file_name,
                                 file_info.file_path,
                                 file_info.file_size,
                                 file_info.hash_value,
                                 file_info.created_at,
                                 file_info.last_modified,
                                 "new") # Steht für den Datei-Zustand, z.B. 'new', 'modified', 'unchanged', 'deleted', 'conflict'

                query = ("INSERT INTO SyncFiles"
                         "(file_name, file_path, file_size, hash_value, created_at, last_modified, file_state)"
                         "VALUES (?, ?, ?, ?, ?, ?, ?)")

                db_handler.execute_query(query, query_params)

            print("Scan completed successfully.")

        except Exception as e:
            error_message = f"Error during scan process: {e}"
            print(error_message)
            self.handle_error(error_message)