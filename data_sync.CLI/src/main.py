import argparse
import os

from core.commands import InitCommand, ScanCommand, ManifestCommand, DownloadCommand, UploadCommand, DeleteCommand


# TODO: Macht eventuell ein Command für das Löschen von Dateien, zumindest für das löschen von Dateien auf dem Server Sinn?
#  Also z.B. wenn eine Datei lokal gelöscht wurde, soll sie auch auf dem Server gelöscht werden können.
#  Prüfen in welches Verzeichnis wie z.B. die api_client.py Datei abgelegt werden sollen.
#  Das abgleichen, was mit der jeweiligen Datei passieren soll, vereinfachen. Ich denke da an einen if elif else Block.
#  Da soll dann jede eventualität abgedeckt werden.
#  Evtl. auch eine Art Strategy Pattern implementieren?
#  ANALYSE: Im CLient gelöschte Dateien, werden vom Server erneut runtergeladen. Auf dem Server gelöschte Dateien,
#  werden beim Client nicht gelöscht. VORAUSSETZUNG: Es wird davon ausgegangen, dass die Datein jeweils, wo Sie gelöscht
#  wurden, auch gelöscht bleiben sollen. Es wird also nicht davon ausgegangen, dass die Dateien nur temporär gelöscht wurden.


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
        '--delete', '-x',
        action='store_true',
        help='Startet den Löschungsprozess nach Manifestübermittlung.'
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
        manifest_command = ManifestCommand()
        files_to_sync = manifest_command.execute()

        upload_command = UploadCommand()
        upload_command.execute(files_to_sync)

    elif args.delete:
        manifest_command = ManifestCommand()
        files_to_sync = manifest_command.execute()

        delete_command = DeleteCommand()
        delete_command.execute(files_to_sync)

    elif args.sync:
        scan_command = ScanCommand()
        scan_command.execute()

        manifest_command = ManifestCommand()
        files_to_sync = manifest_command.execute()

        download_command = DownloadCommand()
        download_command.execute(files_to_sync)

        upload_command = UploadCommand()
        upload_command.execute(files_to_sync)

        delete_command = DeleteCommand()
        delete_command.execute(files_to_sync)


if __name__ == '__main__':
    try:
        main()
    finally:
        print("\n Data Sync CLI execution completed.")