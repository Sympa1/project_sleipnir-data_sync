import '../handlers/sqlite_handler.dart';
import '../models/sync_models.dart';

/// Verwaltet den letzten erfolgreichen Sync-Zustand lokaler Dateien.
class SyncStateService {
  SyncStateService({SqliteHandler? sqliteHandler})
    : _sqliteHandler = sqliteHandler ?? SqliteHandler();

  final SqliteHandler _sqliteHandler;

  /// Lädt alle bekannten Sync-Zustände aus SQLite.
  Future<Map<String, SyncStateEntry>> getAllStates() async {
    final results = await _sqliteHandler.executeQuery(
      '''
      SELECT file_name, file_path, file_size, hash_value, created_at, last_modified
      FROM last_sync_state
      ''',
    );

    final states = <String, SyncStateEntry>{};

    for (final row in results) {
      final entry = SyncStateEntry.fromMap(row);
      states[entry.relativePath] = entry;
    }

    return states;
  }

  /// Legt einen Sync-Zustand an oder aktualisiert ihn.
  Future<void> upsertState(SyncStateEntry entry) async {
    await _sqliteHandler.executeQuery(
      '''
      INSERT INTO last_sync_state (
        file_name,
        file_path,
        file_size,
        hash_value,
        created_at,
        last_modified
      ) VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(file_path) DO UPDATE SET
        file_name = excluded.file_name,
        file_size = excluded.file_size,
        hash_value = excluded.hash_value,
        created_at = excluded.created_at,
        last_modified = excluded.last_modified
      ''',
      params: [
        entry.fileName,
        entry.relativePath,
        entry.size,
        entry.sha256,
        entry.createdAt.toUtc().toIso8601String(),
        entry.lastModified.toUtc().toIso8601String(),
      ],
      returnResult: false,
    );
  }

  /// Entfernt einen Sync-Zustand nach einer bestätigten Löschung.
  Future<void> deleteState(String relativePath) async {
    await _sqliteHandler.executeQuery(
      'DELETE FROM last_sync_state WHERE file_path = ?',
      params: [relativePath],
      returnResult: false,
    );
  }
}
