import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../models/sync_models.dart';

/// Scannt lokale Dateien und erzeugt Manifest-Einträge für den Sync.
class FileScannerService {
  /// Liest alle Dateien im Sync-Verzeichnis rekursiv ein.
  Future<List<SyncFileDescriptor>> scanFiles(String syncRootPath) async {
    final rootDirectory = Directory(syncRootPath);

    if (!await rootDirectory.exists()) {
      throw Exception('Das Sync-Verzeichnis existiert nicht.');
    }

    final files = await _collectSyncFiles(rootDirectory)
      ..sort((left, right) => left.path.compareTo(right.path));

    final descriptors = <SyncFileDescriptor>[];

    for (final file in files) {
      final fileStat = await file.stat();
      final normalizedRelativePath = path
          .relative(file.path, from: rootDirectory.path)
          .replaceAll('\\', '/');

      descriptors.add(
        SyncFileDescriptor(
          fileName: path.basename(file.path),
          relativePath: normalizedRelativePath,
          size: fileStat.size,
          sha256: await _calculateSha256(file),
          createdAt: fileStat.changed.toUtc(),
          lastModified: fileStat.modified.toUtc(),
          changeState: FileChangeState.unchanged,
        ),
      );
    }

    return descriptors;
  }

  /// Sammelt alle Dateien ein und ignoriert Git-Metadatenverzeichnisse.
  Future<List<File>> _collectSyncFiles(Directory rootDirectory) async {
    final pendingDirectories = <Directory>[rootDirectory];
    final files = <File>[];

    while (pendingDirectories.isNotEmpty) {
      final currentDirectory = pendingDirectories.removeLast();

      await for (final entity in currentDirectory.list(followLinks: false)) {
        final entityName = path.basename(entity.path).toLowerCase();

        if (_isGitMetadataEntity(entityName)) {
          continue;
        }

        if (entity is Directory) {
          pendingDirectories.add(entity);
          continue;
        }

        if (entity is File) {
          files.add(entity);
        }
      }
    }

    return files;
  }

  /// Erkennt Git-Metadaten, die nie Teil des eigentlichen Sync-Inhalts sein sollen.
  bool _isGitMetadataEntity(String entityName) {
    return entityName == '.git';
  }

  /// Berechnet den SHA256-Hash einer Datei.
  Future<String> _calculateSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
