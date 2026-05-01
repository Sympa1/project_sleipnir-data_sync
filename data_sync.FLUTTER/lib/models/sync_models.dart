/// Repräsentiert den Änderungszustand einer Datei im Sync-Prozess.
enum FileChangeState {
  newFile,
  modified,
  unchanged,
  deleted,
  conflict,
}

/// Wandelt Datei-Zustände in das API-Format und zurück.
extension FileChangeStateExtension on FileChangeState {
  /// Liefert den Enum-Wert im Format der ASP.NET API.
  String toApiValue() {
    switch (this) {
      case FileChangeState.newFile:
        return 'New';
      case FileChangeState.modified:
        return 'Modified';
      case FileChangeState.unchanged:
        return 'Unchanged';
      case FileChangeState.deleted:
        return 'Deleted';
      case FileChangeState.conflict:
        return 'Conflict';
    }
  }

  /// Liest einen API-Wert und ordnet ihn einem lokalen Enum zu.
  static FileChangeState fromApiValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'new':
        return FileChangeState.newFile;
      case 'modified':
        return FileChangeState.modified;
      case 'deleted':
        return FileChangeState.deleted;
      case 'conflict':
        return FileChangeState.conflict;
      case 'unchanged':
      default:
        return FileChangeState.unchanged;
    }
  }
}

/// Beschreibt eine lokale Datei für das Manifest und Uploads.
class SyncFileDescriptor {
  SyncFileDescriptor({
    required this.fileName,
    required this.relativePath,
    required this.size,
    required this.sha256,
    required this.createdAt,
    required this.lastModified,
    required this.changeState,
  });

  final String fileName;
  final String relativePath;
  final int size;
  final String sha256;
  final DateTime createdAt;
  final DateTime lastModified;
  final FileChangeState changeState;

  /// Serialisiert den Eintrag für die Manifest-API.
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'relativePath': relativePath,
      'size': size,
      'sha256': sha256,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastModified': lastModified.toUtc().toIso8601String(),
      'changeState': changeState.toApiValue(),
    };
  }

  /// Erstellt eine geänderte Kopie des Datei-Deskriptors.
  SyncFileDescriptor copyWith({
    String? fileName,
    String? relativePath,
    int? size,
    String? sha256,
    DateTime? createdAt,
    DateTime? lastModified,
    FileChangeState? changeState,
  }) {
    return SyncFileDescriptor(
      fileName: fileName ?? this.fileName,
      relativePath: relativePath ?? this.relativePath,
      size: size ?? this.size,
      sha256: sha256 ?? this.sha256,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      changeState: changeState ?? this.changeState,
    );
  }
}

/// Beschreibt einen Manifest-Eintrag aus der Serverantwort.
class SyncManifestResponse {
  SyncManifestResponse({
    required this.fileName,
    required this.relativePath,
    required this.size,
    required this.sha256,
    required this.createdAt,
    required this.lastModified,
    required this.changeState,
    required this.toUpload,
    required this.toDelete,
    required this.toDownload,
  });

  final String fileName;
  final String relativePath;
  final int size;
  final String sha256;
  final DateTime createdAt;
  final DateTime lastModified;
  final FileChangeState changeState;
  final bool toUpload;
  final bool toDelete;
  final bool toDownload;

  /// Erstellt ein Modell aus einem JSON-Objekt der Manifest-API.
  factory SyncManifestResponse.fromJson(Map<String, dynamic> json) {
    return SyncManifestResponse(
      fileName: json['fileName'] as String? ?? '',
      relativePath: json['relativePath'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      sha256: json['sha256'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastModified:
          DateTime.tryParse(json['lastModified'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      changeState: FileChangeStateExtension.fromApiValue(
        json['changeState'] as String?,
      ),
      toUpload: json['toUpload'] as bool? ?? false,
      toDelete: json['toDelete'] as bool? ?? false,
      toDownload: json['toDownload'] as bool? ?? false,
    );
  }
}

/// Speichert den letzten erfolgreichen lokalen Sync-Zustand einer Datei.
class SyncStateEntry {
  SyncStateEntry({
    required this.fileName,
    required this.relativePath,
    required this.size,
    required this.sha256,
    required this.createdAt,
    required this.lastModified,
  });

  final String fileName;
  final String relativePath;
  final int size;
  final String sha256;
  final DateTime createdAt;
  final DateTime lastModified;

  /// Baut einen Sync-State aus einem lokalen Datei-Deskriptor.
  factory SyncStateEntry.fromDescriptor(SyncFileDescriptor descriptor) {
    return SyncStateEntry(
      fileName: descriptor.fileName,
      relativePath: descriptor.relativePath,
      size: descriptor.size,
      sha256: descriptor.sha256,
      createdAt: descriptor.createdAt,
      lastModified: descriptor.lastModified,
    );
  }

  /// Baut einen Sync-State aus einem Server-Download.
  factory SyncStateEntry.fromManifestResponse(SyncManifestResponse response) {
    return SyncStateEntry(
      fileName: response.fileName,
      relativePath: response.relativePath,
      size: response.size,
      sha256: response.sha256,
      createdAt: response.createdAt,
      lastModified: response.lastModified,
    );
  }

  /// Baut einen Sync-State aus einer SQLite-Zeile.
  factory SyncStateEntry.fromMap(Map<String, dynamic> map) {
    return SyncStateEntry(
      fileName: map['file_name'] as String,
      relativePath: map['file_path'] as String,
      size: (map['file_size'] as num).toInt(),
      sha256: map['hash_value'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      lastModified: DateTime.parse(map['last_modified'] as String).toUtc(),
    );
  }

  /// Baut einen Manifest-Eintrag für lokal gelöschte Dateien.
  SyncFileDescriptor toDeletedDescriptor() {
    return SyncFileDescriptor(
      fileName: fileName,
      relativePath: relativePath,
      size: size,
      sha256: sha256,
      createdAt: createdAt,
      lastModified: lastModified,
      changeState: FileChangeState.deleted,
    );
  }
}
