namespace data_sync.API.Services;

/// <summary>
/// Führt Startup-Checks für die MariaDB-Datenbank durch.
/// Prüft die Datenbankverbindung und erstellt erforderliche Tabellen.
/// </summary>
public class DbStartupCheckService : IDisposable
{
    private MariaDbService _dbService;
    
    /// <summary>
    /// Testet die Verbindung zur MariaDB-Datenbank.
    /// Gibt Erfolgs- oder Fehlermeldung aus und protokolliert Fehler.
    /// </summary>
    public void CheckDatabaseConnection()
    {
        var logService = new FileLogService();
        try
        {
            using (_dbService = new MariaDbService())
            {
                using (var connection = _dbService.OpenConnection())
                {
                    if (connection != null)
                    {
                        Console.WriteLine("MariaDB-Verbindung erfolgreich getestet.");
                        
                        _dbService.CloseConnection();
                    }
                    else
                    {
                        Console.WriteLine("MariaDB-Verbindung fehlgeschlagen.");
                    }
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
    /// <b>Tabellen</b>: SyncFiles, SyncEvent, FehlerProtokoll
    /// </summary>
    public void CheckDatabaseTables()
    {
        var logService = new FileLogService();
        try
        {
            using (_dbService = new MariaDbService())
            {
                using (var connection = _dbService.OpenConnection())
                {
                    if (connection != null)
                    {
                        Console.WriteLine("MariaDB-Verbindung erfolgreich getestet.");
                        
                        // Impementiere hier die Logik zum Überprüfen der erforderlichen Tabellen.
                        using (var dbCommand = connection.CreateCommand())
                        {
                            dbCommand.CommandText = @"
                            CREATE TABLE IF NOT EXISTS SyncFiles (
                                sync_file_id INT AUTO_INCREMENT PRIMARY KEY,
                                file_name VARCHAR(255) NOT NULL,
                                file_path VARCHAR(512) NOT NULL,
                                last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                status ENUM('pending', 'in_progress', 'completed', 'failed') DEFAULT 'pending',
                                UNIQUE(file_path)
                            );

                            CREATE TABLE IF NOT EXISTS SyncEvent (
                                sync_event_id INT AUTO_INCREMENT PRIMARY KEY,
                                sync_file_id INT NOT NULL,
                                event_type ENUM('created', 'modified', 'deleted', 'error') NOT NULL,
                                event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                event_details TEXT,
                                FOREIGN KEY (`sync_file_id`) REFERENCES `SyncFiles`(`sync_file_id`) ON DELETE CASCADE
                            );

                            CREATE TABLE IF NOT EXISTS FehlerProtokoll (
                                fehler_protokoll_id INT AUTO_INCREMENT PRIMARY KEY,
                                fehler_beschreibung TEXT NOT NULL,
                                fehler_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                            );";
                            
                            dbCommand.ExecuteNonQuery();
                        }
                        
                        _dbService.CloseConnection();
                    }
                    else
                    {
                        Console.WriteLine("MariaDB-Verbindung fehlgeschlagen.");
                    }
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
    public void Dispose()
    {
        _dbService.Dispose();
    }
}