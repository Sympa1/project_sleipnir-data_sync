namespace data_sync.API.Services;

public class DbStartupCheckService
{
    public void CheckDatabaseConnection()
    {
        var logService = new FileLogService();
        try
        {
            using (var dbService = new MariaDbService())
            {
                using (var connection = dbService.OpenConnection())
                {
                    if (connection != null)
                    {
                        Console.WriteLine("MariaDB-Verbindung erfolgreich getestet.");
                        dbService.CloseConnection();
                    }
                    else
                    {
                        Console.WriteLine("MariaDB-Verbindung fehlgeschlagen. Details siehe Logfile.");
                    }
                }
            }
        }
        catch (Exception ex)
        {
            logService.WriteToLog($"DB-Verbindungstest fehlgeschlagen: {ex}", "DBStartupTest");
            Console.WriteLine($"✗ Fehler beim DB-Verbindungstest: {ex.Message}");
        }
        
        
    }
}