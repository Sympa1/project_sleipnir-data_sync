import argparse
import os
from backend.commands.init_command import InitCommand
from backend.commands.scan_command import ScanCommand


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

    group.add_argument(
        '--scan', '-c',
        action='store_true',
        help='Scannt das Verzeichnis und aktualisiert die Datenbank mit Datei-Informationen'
    )

    # Argumente parsen
    args = parser.parse_args()

    if args.sync:
        print("sync process started")

    elif args.scan:
        if not os.path.exists("config.json"):
            print("config.json not found. Please run the --init command first to set up the database and configuration.")
            return
        else:
            print("scan process started")
            scan_command = ScanCommand()
            scan_command.execute()

    elif args.manifest:
        if not os.path.exists("config.json"):
            print("config.json not found. Please run the --init command first to set up the database and configuration.")
            return
        else:
            print("manifest process started")



    elif args.download:
        print("download process started")

    elif args.upload:
        print("upload process started")

    elif args.init:
        init_command = InitCommand()
        init_command.execute()


if __name__ == '__main__':
    try:
        main()
    finally:
        print("\n Data Sync CLI execution completed.")