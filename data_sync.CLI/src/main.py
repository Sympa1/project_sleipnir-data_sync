import argparse
import os

from backend.commands import InitCommand, ScanCommand, ManifestCommand, DownloadCommand


def main():
    """Main Funktion for Data Synchronization CLI Tool"""

    # ArgumentParser erstellen mit Beschreibung
    parser = argparse.ArgumentParser(
        description="Data Synchronization CLI Tool",
        add_help=True)

    # Erstellt eine Gruppe von Argumenten/Flags, die sich gegenseitig ausschließen.
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

    # Argumente/Flags parsen
    args = parser.parse_args()

    if args.init:
        init_command = InitCommand()
        init_command.execute()

    elif args.scan:
        scan_command = ScanCommand()
        scan_command.execute()

    elif args.manifest:
        manifest_command = ManifestCommand()
        manifest_command.execute()

    elif args.download:
        manifest_command = ManifestCommand()
        files_to_sync = manifest_command.execute()

        download_command = DownloadCommand()
        download_command.execute(files_to_sync)

    elif args.upload:
        print("upload process started")

    elif args.sync:
        print("sync process started")


if __name__ == '__main__':
    try:
        main()
    finally:
        print("\n Data Sync CLI execution completed.")