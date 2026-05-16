import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import '../models/settings.dart';
import '../models/sync_models.dart';
import 'file_scanner_service.dart';
import 'settings_service.dart';
import 'sync_api_service.dart';
import 'sync_state_service.dart';

/// Orchestriert Manifest, Upload, Download und Löschungen für die Flutter-App.
class SyncService {
  SyncService({
    SettingsService? settingsService,
    FileScannerService? fileScannerService,
    SyncApiService? syncApiService,
    SyncStateService? syncStateService,
  }) : _settingsService = settingsService ?? SettingsService(),
       _fileScannerService = fileScannerService ?? FileScannerService(),
       _syncApiService = syncApiService ?? SyncApiService(),
       _syncStateService = syncStateService ?? SyncStateService();

  final SettingsService _settingsService;
  final FileScannerService _fileScannerService;
  final SyncApiService _syncApiService;
  final SyncStateService _syncStateService;

  /// Führt nur die Download-Phase des Sync-Prozesses aus.
  Future<void> runDownload({
    required void Function(String message) onLog,
  }) async {
    await _run(mode: SyncRunMode.download, onLog: onLog);
  }

  /// Führt nur die Upload-Phase des Sync-Prozesses aus.
  Future<void> runUpload({
    required void Function(String message) onLog,
  }) async {
    await _run(mode: SyncRunMode.upload, onLog: onLog);
  }

  /// Führt den vollständigen Sync-Ablauf aus.
  Future<void> runFullSync({
    required void Function(String message) onLog,
  }) async {
    await _run(mode: SyncRunMode.fullSync, onLog: onLog);
  }

  /// Führt je nach Modus den passenden Sync-Ablauf aus.
  Future<void> _run({
    required SyncRunMode mode,
    required void Function(String message) onLog,
  }) async {
    final settings = await _loadSettings();
    final syncRootPath = settings.syncPath!.trim();
    final apiBaseUrl = settings.apiUrl!.trim();
    final allowInsecureTlsForLocalhost =
        settings.allowInsecureTlsForLocalhost;

    onLog('Nutze API: ${_syncApiService.describeBaseUrl(apiBaseUrl)}');
    if (allowInsecureTlsForLocalhost) {
      onLog('Lokale HTTPS-Zertifikate fuer localhost und LAN-Adressen sind aktiviert.');
    }
    onLog('Scanne lokales Verzeichnis ...');

    final currentFiles = await _fileScannerService.scanFiles(syncRootPath);
    final currentFilesByPath = {
      for (final file in currentFiles) file.relativePath: file,
    };

    final previousStates = await _syncStateService.getAllStates();
    final deletedEntries = previousStates.values
        .where((entry) => !currentFilesByPath.containsKey(entry.relativePath))
        .map((entry) => entry.toDeletedDescriptor())
        .toList()
      ..sort((left, right) => left.relativePath.compareTo(right.relativePath));

    final manifest = _buildManifest(
      currentFiles: currentFiles,
      previousStates: previousStates,
    )..addAll(deletedEntries);

    onLog(
      'Manifest erstellt: ${currentFiles.length} aktuelle, '
      '${deletedEntries.length} geloeschte Dateien.',
    );

    final manifestResponse = await _syncApiService.sendManifest(
      apiBaseUrl: apiBaseUrl,
      manifest: manifest,
      allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
    );

    final responseByPath = {
      for (final file in manifestResponse) file.relativePath: file,
    };

    onLog('Serverantwort erhalten: ${manifestResponse.length} Eintraege.');

    if (mode == SyncRunMode.download || mode == SyncRunMode.fullSync) {
      await _runDownloads(
        apiBaseUrl: apiBaseUrl,
        syncRootPath: syncRootPath,
        manifestResponse: manifestResponse,
        allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
        onLog: onLog,
      );
    }

    if (mode == SyncRunMode.upload || mode == SyncRunMode.fullSync) {
      await _runUploads(
        apiBaseUrl: apiBaseUrl,
        syncRootPath: syncRootPath,
        manifestResponse: manifestResponse,
        currentFilesByPath: currentFilesByPath,
        allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
        onLog: onLog,
      );
    }

    if (mode == SyncRunMode.fullSync) {
      await _runDeletionSync(
        apiBaseUrl: apiBaseUrl,
        syncRootPath: syncRootPath,
        manifestResponse: manifestResponse,
        deletedEntries: deletedEntries,
        responseByPath: responseByPath,
        allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
        onLog: onLog,
      );
    }

    onLog('${mode.label} abgeschlossen.');
  }

  /// Validiert die Einstellungen für einen Sync-Lauf.
  Future<Settings> _loadSettings() async {
    final settings = await _settingsService.getAllSettings();
    final syncPath = settings.syncPath?.trim();
    final apiUrl = settings.apiUrl?.trim();

    if (syncPath == null || syncPath.isEmpty) {
      throw Exception('Es ist kein Sync-Verzeichnis konfiguriert.');
    }

    if (apiUrl == null || apiUrl.isEmpty) {
      throw Exception('Es ist keine API-URL konfiguriert.');
    }

    await _ensureAndroidSharedStorageAccess(syncPath);

    final syncDirectory = Directory(syncPath);

    if (!await syncDirectory.exists()) {
      throw Exception('Das konfigurierte Sync-Verzeichnis existiert nicht.');
    }

    return settings;
  }

  /// Prüft auf Android den Dateisystemzugriff für sichtbare gemeinsame Ordner.
  Future<void> _ensureAndroidSharedStorageAccess(String syncPath) async {
    if (!Platform.isAndroid) {
      return;
    }

    final usesSharedStorage =
        syncPath.startsWith('/storage/') || syncPath.startsWith('/sdcard/');

    if (!usesSharedStorage) {
      return;
    }

    final status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      return;
    }

    throw Exception(
      'Android braucht "Alle Dateien verwalten", damit sichtbare Ordner wie '
      'Documents/data_sync gelesen und geschrieben werden koennen. '
      'Erteile die Berechtigung in den Einstellungen und waehle den Ordner '
      'anschliessend erneut aus.',
    );
  }

  /// Baut das Manifest für lokale Dateien anhand des letzten Sync-Zustands.
  List<SyncFileDescriptor> _buildManifest({
    required List<SyncFileDescriptor> currentFiles,
    required Map<String, SyncStateEntry> previousStates,
  }) {
    final manifest = currentFiles
        .map((file) {
          final previousState = previousStates[file.relativePath];
          return file.copyWith(
            changeState: _determineChangeState(file, previousState),
          );
        })
        .toList()
      ..sort((left, right) => left.relativePath.compareTo(right.relativePath));

    return manifest;
  }

  /// Leitet aus aktuellem und letztem Stand den lokalen Änderungszustand ab.
  FileChangeState _determineChangeState(
    SyncFileDescriptor currentFile,
    SyncStateEntry? previousState,
  ) {
    if (previousState == null) {
      return FileChangeState.newFile;
    }

    if (previousState.sha256 == currentFile.sha256 &&
        previousState.size == currentFile.size) {
      return FileChangeState.unchanged;
    }

    return FileChangeState.modified;
  }

  /// Lädt alle vom Server angeforderten Dateien herunter.
  Future<void> _runDownloads({
    required String apiBaseUrl,
    required String syncRootPath,
    required List<SyncManifestResponse> manifestResponse,
    required bool allowInsecureTlsForLocalhost,
    required void Function(String message) onLog,
  }) async {
    final filesToDownload = manifestResponse
        .where((file) => file.toDownload)
        .toList()
      ..sort((left, right) => left.relativePath.compareTo(right.relativePath));

    if (filesToDownload.isEmpty) {
      onLog('Keine Downloads erforderlich.');
      return;
    }

    for (final file in filesToDownload) {
      onLog('Downloade ${file.relativePath} ...');

      await _syncApiService.downloadFile(
        apiBaseUrl: apiBaseUrl,
        syncRootPath: syncRootPath,
        file: file,
        allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
      );

      await _syncStateService.upsertState(
        SyncStateEntry.fromManifestResponse(file),
      );

      onLog('Download abgeschlossen: ${file.relativePath}');
    }
  }

  /// Lädt alle vom Server angeforderten lokalen Dateien hoch.
  Future<void> _runUploads({
    required String apiBaseUrl,
    required String syncRootPath,
    required List<SyncManifestResponse> manifestResponse,
    required Map<String, SyncFileDescriptor> currentFilesByPath,
    required bool allowInsecureTlsForLocalhost,
    required void Function(String message) onLog,
  }) async {
    final filesToUpload = manifestResponse
        .where((file) => file.toUpload)
        .toList()
      ..sort((left, right) => left.relativePath.compareTo(right.relativePath));

    if (filesToUpload.isEmpty) {
      onLog('Keine Uploads erforderlich.');
      return;
    }

    for (final file in filesToUpload) {
      final localFile = currentFilesByPath[file.relativePath];

      if (localFile == null) {
        onLog('Upload uebersprungen: ${file.relativePath} wurde lokal nicht gefunden.');
        continue;
      }

      onLog('Lade ${file.relativePath} hoch ...');

      await _syncApiService.uploadFile(
        apiBaseUrl: apiBaseUrl,
        syncRootPath: syncRootPath,
        file: localFile,
        allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
      );

      await _syncStateService.upsertState(
        SyncStateEntry.fromDescriptor(localFile),
      );

      onLog('Upload abgeschlossen: ${file.relativePath}');
    }
  }

  /// Verarbeitet serverseitige und lokale Löschungen.
  Future<void> _runDeletionSync({
    required String apiBaseUrl,
    required String syncRootPath,
    required List<SyncManifestResponse> manifestResponse,
    required List<SyncFileDescriptor> deletedEntries,
    required Map<String, SyncManifestResponse> responseByPath,
    required bool allowInsecureTlsForLocalhost,
    required void Function(String message) onLog,
  }) async {
    await _processRemoteDeletions(
      syncRootPath: syncRootPath,
      manifestResponse: manifestResponse,
      onLog: onLog,
    );

    await _processLocalDeletions(
      apiBaseUrl: apiBaseUrl,
      deletedEntries: deletedEntries,
      responseByPath: responseByPath,
      allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
      onLog: onLog,
    );
  }

  /// Löscht lokal Dateien, die vom Server als gelöscht markiert wurden.
  Future<void> _processRemoteDeletions({
    required String syncRootPath,
    required List<SyncManifestResponse> manifestResponse,
    required void Function(String message) onLog,
  }) async {
    final filesToDeleteLocally = manifestResponse
        .where((file) => file.toDelete)
        .toList()
      ..sort((left, right) => left.relativePath.compareTo(right.relativePath));

    if (filesToDeleteLocally.isEmpty) {
      onLog('Keine serverseitigen Loeschungen zu uebernehmen.');
      return;
    }

    for (final file in filesToDeleteLocally) {
      final localFile = File(path.join(syncRootPath, file.relativePath));

      if (await localFile.exists()) {
        await localFile.delete();
        onLog('Lokal geloescht: ${file.relativePath}');
      } else {
        onLog('Bereits lokal entfernt: ${file.relativePath}');
      }

      await _syncStateService.deleteState(file.relativePath);
    }
  }

  /// Meldet lokal gelöschte Dateien an den Server.
  Future<void> _processLocalDeletions({
    required String apiBaseUrl,
    required List<SyncFileDescriptor> deletedEntries,
    required Map<String, SyncManifestResponse> responseByPath,
    required bool allowInsecureTlsForLocalhost,
    required void Function(String message) onLog,
  }) async {
    if (deletedEntries.isEmpty) {
      onLog('Keine lokalen Loeschungen zu melden.');
      return;
    }

    for (final file in deletedEntries) {
      final serverDecision = responseByPath[file.relativePath];

      if (serverDecision?.toDownload == true) {
        onLog(
          'Server-Loeschung uebersprungen: ${file.relativePath} wird erneut heruntergeladen.',
        );
        continue;
      }

      if (serverDecision?.toDelete == true) {
        await _syncStateService.deleteState(file.relativePath);
        onLog('Server meldet Datei bereits als geloescht: ${file.relativePath}');
        continue;
      }

      onLog('Melde Loeschung an Server: ${file.relativePath}');

      await _syncApiService.deleteRemoteFile(
        apiBaseUrl: apiBaseUrl,
        relativePath: file.relativePath,
        allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
      );

      await _syncStateService.deleteState(file.relativePath);
      onLog('Server-Loeschung bestaetigt: ${file.relativePath}');
    }
  }
}

/// Beschreibt die verfügbaren Ausführungsarten des Sync-Prozesses.
enum SyncRunMode {
  download,
  upload,
  fullSync,
}

/// Liefert die Anzeige-Bezeichnung für einen Sync-Modus.
extension SyncRunModeExtension on SyncRunMode {
  /// Gibt die Kurzbezeichnung für Logs und Statusmeldungen zurück.
  String get label {
    switch (this) {
      case SyncRunMode.download:
        return 'Download';
      case SyncRunMode.upload:
        return 'Upload';
      case SyncRunMode.fullSync:
        return 'Sync';
    }
  }
}
