namespace data_sync.API.Services;

/// <summary>
/// Führt Startup-Checks für die MariaDB-Datenbank durch.
/// Prüft die Datenbankverbindung und erstellt erforderliche Tabellen.
/// </summary>
public class DbStartupCheckService : IAsyncDisposable
{
    private readonly MariaDbService _dbService;

    public DbStartupCheckService(MariaDbService mariaDbService)
    {
        _dbService = mariaDbService;
    }
    
    /// <summary>
    /// Testet die Verbindung zur MariaDB-Datenbank.
    /// Gibt Erfolgs- oder Fehlermeldung aus und protokolliert Fehler.
    /// </summary>
    public async Task CheckDatabaseConnectionAsync()
    {
        var logService = new FileLogService();
        try
        {
            await using (var connection = await _dbService.OpenConnectionAsync())
            {
                if (connection != null)
                {
                    Console.WriteLine("MariaDB-Verbindung erfolgreich getestet.");
                }
                else
                {
                    Console.WriteLine("MariaDB-Verbindung fehlgeschlagen.");
                }
            }
        }
        catch (Exception ex)
        {
            logService.WriteToLog($"DB-Verbindungstest fehlgeschlagen: {ex}", "DBStartupTest");
            Console.WriteLine($"Fehler beim DB-Verbindungstest: {ex.Message}");
        }
        
        
    }
    
    /// <summary>
    /// Erstellt die erforderlichen Datenbanktabellen, falls diese nicht existieren.
    /// <b>Tabellen</b>: SyncFiles, SyncEvent, FehlerProtokoll, LastSyncState
    /// </summary>
    public async Task CheckDatabaseTablesAsync()
    {
        var logService = new FileLogService();
        try
        {
            await using (var connection = await _dbService.OpenConnectionAsync())
            {
                if (connection != null)
                {
                    // Implementiere hier die Logik zum Überprüfen der erforderlichen Tabellen.
                    await using (var dbCommand = connection.CreateCommand())
                    {
                        dbCommand.CommandText = @"
                        CREATE TABLE IF NOT EXISTS SyncFiles (
    sync_file_id INT AUTO_INCREMENT PRIMARY KEY,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(1024) NOT NULL,
    file_size BIGINT NOT NULL,
    hash_value VARCHAR(64) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    file_state ENUM('new', 'modified', 'unchanged', 'deleted', 'conflict') NOT NULL
);

CREATE TABLE IF NOT EXISTS SyncEvent (
    sync_event_id INT AUTO_INCREMENT PRIMARY KEY,
    sync_file_id INT NOT NULL,
    event_type ENUM('created', 'modified', 'deleted', 'error') NOT NULL,
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_details TEXT,
    FOREIGN KEY (sync_file_id) REFERENCES SyncFiles(sync_file_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS FehlerProtokoll (
    fehler_protokoll_id INT AUTO_INCREMENT PRIMARY KEY,
    fehler_beschreibung TEXT NOT NULL,
    fehler_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS LastSyncState (
    file_path VARCHAR(768) PRIMARY KEY,
    hash_value VARCHAR(64) NOT NULL,
    file_size BIGINT NOT NULL,
    last_synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);";
                        
                        // Asynchrone Ausführung — blockiert nicht
                        await dbCommand.ExecuteNonQueryAsync();
                        Console.WriteLine("Datenbanktabellen erfolgreich erstellt/geprüft.");
                    }
                }
                else
                {
                    Console.WriteLine("MariaDB-Verbindung fehlgeschlagen.");
                }
            }
        }
        catch (Exception ex)
        {
            logService.WriteToLog($"DB-Verbindungstest fehlgeschlagen: {ex}", "DBStartupTest");
            Console.WriteLine($"Fehler beim DB-Verbindungstest: {ex.Message}");
        }
        
        
    }
    
    /// <summary>
    /// Gibt die MariaDbService-Ressource frei.
    /// </summary>
    public async ValueTask DisposeAsync()
    {
        await _dbService.DisposeAsync();
    }
}
