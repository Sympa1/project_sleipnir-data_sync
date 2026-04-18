namespace data_sync.API.Services;

/// <summary>
/// Verwaltet den letzten bekannten Synchronisationsstand einer Datei.
/// </summary>
public class SyncStateService
{
    private readonly MariaDbService _mariaDbService;

    public SyncStateService(MariaDbService mariaDbService)
    {
        _mariaDbService = mariaDbService;
    }

    /// <summary>
    /// Legt den letzten Synchronisationsstand für eine Datei an oder aktualisiert ihn.
    /// </summary>
    public async Task UpdateSyncStateAsync(string filePath, string hashValue, long fileSize)
    {
        await using var connection = await _mariaDbService.OpenConnectionAsync();
        if (connection == null)
        {
            throw new InvalidOperationException("MariaDB connection could not be established.");
        }

        await using var dbCommand = connection.CreateCommand();
        dbCommand.CommandText = @"
            INSERT INTO LastSyncState (file_path, hash_value, file_size)
            VALUES (@filePath, @hashValue, @fileSize)
            ON DUPLICATE KEY UPDATE
                hash_value = @hashValue,
                file_size = @fileSize,
                last_synced_at = CURRENT_TIMESTAMP;";

        dbCommand.Parameters.AddWithValue("@filePath", filePath);
        dbCommand.Parameters.AddWithValue("@hashValue", hashValue);
        dbCommand.Parameters.AddWithValue("@fileSize", fileSize);

        await dbCommand.ExecuteNonQueryAsync();
    }

    /// <summary>
    /// Entfernt den letzten Synchronisationsstand für eine Datei.
    /// </summary>
    public async Task DeleteSyncStateAsync(string filePath)
    {
        await using var connection = await _mariaDbService.OpenConnectionAsync();
        if (connection == null)
        {
            throw new InvalidOperationException("MariaDB connection could not be established.");
        }

        await using var dbCommand = connection.CreateCommand();
        dbCommand.CommandText = "DELETE FROM LastSyncState WHERE file_path = @filePath;";
        dbCommand.Parameters.AddWithValue("@filePath", filePath);

        await dbCommand.ExecuteNonQueryAsync();
    }
}
