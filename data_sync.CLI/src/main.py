import argparse
from backend import FileLogger, DbSetup, ConfigHandler

def main():
    """Main Funktion for Data Synchronization CLI Tool"""

    # ArgumentParser erstellen mit Beschreibung
    parser = argparse.ArgumentParser(
        description="Data Synchronization CLI Tool",
        add_help=True)

    # Erstellt eine Gruppe von Argumenten, die sich gegenseitig ausschließen.
    # So kann nur eins genutzt werden.
    group = parser.add_mutually_exclusive_group(required=True)

    # Hinzufügen von Argumenten/Flags zur Gruppe
    group.add_argument(
        '--sync', '-s',
        action='store_true',
        help='Startet die Datensynchronisation.'
    )

    group.add_argument(
        '--manifest', '-m',
        action='store_true',
        help='Startet die Manifestabwicklung.'
    )

    group.add_argument(
        '--download', '-d',
        action='store_true',
        help='Startet den Download-Prozess nach Manifestübermittlung.'
    )

    group.add_argument(
        '--upload', '-u',
        action='store_true',
        help='Startet den Upload-Prozess nach Manifestübermittlung.'
    )

    group.add_argument(
        '--init', '-i',
        action='store_true',
        help='Initialisiert die Datenbank.'
    )

    # Argumente parsen
    args = parser.parse_args()

    if args.sync:
        print("sync process started")

    elif args.manifest:
        print("manifest process started")
        log = FileLogger()
        log.write_log("Manifest process initiated.")

    elif args.download:
        print("download process started")

    elif args.upload:
        print("upload process started")

    elif args.init:
        print("Initializing database...")
        DbSetup.setup_db()
        print("Database initialized successfully.")
        print("\n\n Please configure your path to sync in config.json before proceeding.")
        path = input("Enter the path to sync: ")
        config = ConfigHandler()
        config.set_config("sync_path", path)
        print(f"Sync path '{path}' saved to config.json.")


if __name__ == '__main__':
    try:
        main()
    finally:
        print("\n Data Sync CLI execution completed.")