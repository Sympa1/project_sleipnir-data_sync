namespace data_sync.API.Services;

// TODO: MariaDbService auf async umstellen: IAsyncDisposable. Sollten auch Open- & Close-Methoden async sein?
// TODO: In der Methode LogDbErrorAsync Exception-Handling einbauen und die using Blöcke auf async stellen.
// TODO: Ggf. die Programm.cs bzw. den DbStartupcheckService anpassen, damit async passt.

/// <summary>
/// Diese Klasse stellt eine Methode zum Protokollieren von Datenbankfehlern in der FehlerProtokoll-Tabelle bereit.
/// Sie nutzt den MariaDbService per DI, um eine Verbindung zur Datenbank herzustellen.
/// </summary>
public class DbErrorLogService
{
    // Private, readonly Feld speichert die injizierte MariaDBService-Instanz
    // '_' ist C#-Konvention für private Felder
    private readonly MariaDbService _dbService;

    // Konstruktor mit Parameter: Der DI-Container ruft das auf und übergibt MariaDbService
    // So wird die Abhängigkeit "injiziert" statt hart codiert
    public DbErrorLogService(MariaDbService mariaDbService)
    {
        // Speichert die Referenz für die ganze Klassenlebensdauer
        _dbService = mariaDbService;
    }
    /// <summary>
    /// Schreibt eine aussagekräftige Fehlermeldung in die FehlerProtokoll-Tabelle.
    /// Dazu wird ex. Message und ex. StackTrace genutzt.
    /// </summary>
    /// <param name="ex"></param>
    /// <param name="contextInfo"></param>
    public async Task LogDbErrorAsync(Exception ex, string contextInfo)
    {
        using (var connection = _dbService.OpenConnection())
        {
            if (connection != null)
            {
                using (var dbCommand = connection.CreateCommand())
                {
                    // ex. Message: Gibt die kurze Fehlermeldung als Text zurück
                    // ex. StackTrace: Zeigt die Call-Stack-Information - welche Methoden aufgerufen wurden
                    var fehlerBeschreibung = $"Fehler im Kontext '{contextInfo}': {ex.Message}\nStackTrace: {ex.StackTrace}";
                    dbCommand.CommandText = @"
                        INSERT INTO FehlerProtokoll (fehler_beschreibung)
                        VALUES (@fehlerBeschreibung);";
                    
                    dbCommand.Parameters.AddWithValue("@fehlerBeschreibung", fehlerBeschreibung);
                    
                    await dbCommand.ExecuteNonQueryAsync();
                }
            }
        }
    }
}