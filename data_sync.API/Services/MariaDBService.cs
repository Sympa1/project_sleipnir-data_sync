using MySql.Data.MySqlClient;

namespace data_sync.API.Services;

/// <summary>
/// Service für die Verwaltung der MariaDB-Datenbankverbindung.
/// Liest Verbindungsdaten aus .env und stellt Verbindungen bereit.
/// </summary>
public class MariaDbService : IAsyncDisposable
{
    private readonly string _connectionString;
    private MySqlConnection? _connection;

    /// <summary>
    /// Konstruktor: Liest DB-Verbindungsdaten aus Umgebungsvariablen (.env).
    /// Wirft Exception bei fehlenden Daten.
    /// </summary>
    public MariaDbService()
    {
        // Umgebungsvariablen aus .env lesen
        var server = Environment.GetEnvironmentVariable("DB_HOST");
        var port = Environment.GetEnvironmentVariable("DB_PORT");
        var database = Environment.GetEnvironmentVariable("DB_NAME");
        var user = Environment.GetEnvironmentVariable("DB_USER");
        var password = Environment.GetEnvironmentVariable("DB_PASSWORD");

        // Validierung: Alle erforderlichen Variablen müssen gesetzt sein
        if (string.IsNullOrWhiteSpace(server) ||
            string.IsNullOrWhiteSpace(database) ||
            string.IsNullOrWhiteSpace(user) ||
            string.IsNullOrWhiteSpace(password))
        {
            var errorMsg = "MariaDB-Verbindungsdaten fehlen in .env (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD).";
            var logService = new FileLogService("db_error.log");
            logService.WriteToLog(errorMsg, "DBServiceError");
            throw new InvalidOperationException(errorMsg);
        }

        // Connection String über MySqlConnectionStringBuilder erstellen
        var builder = new MySqlConnectionStringBuilder
        {
            Server = server,
            Port = string.IsNullOrWhiteSpace(port) ? 3306 : Convert.ToUInt32(port),
            Database = database,
            UserID = user,
            Password = password,
            SslMode = MySqlSslMode.Required, // TLS-Verschlüsselung aktiviert
            TlsVersion = "Tls12" // TLS 1.3 für maximale Sicherheit
        };

        _connectionString = builder.ConnectionString;
    }

    /// <summary>
    /// Öffnet eine neue Verbindung zur MariaDB asynchron. Die Verbindung wird automatisch durch IAsyncDisposable geschlossen.
    /// </summary>
    /// <returns>Geöffnete MySqlConnection oder null bei Fehlern.</returns>
    public async Task<MySqlConnection?> OpenConnectionAsync()
    {
        try
        {
            _connection = new MySqlConnection(_connectionString);
            // Asynchrones Öffnen der Verbindung
            await _connection.OpenAsync();
            return _connection;
        }
        catch (Exception e)
        {
            var logService = new FileLogService("db_error.log");
            logService.WriteToLog($"MariaDB-Verbindung fehlgeschlagen: {e}", "DBConnectionError");
            return null;
        }
    }

    /// <summary>
    /// Schließt die aktuelle Verbindung asynchron, falls sie offen ist.
    /// </summary>
    public async Task CloseConnectionAsync()
    {
        if (_connection?.State == System.Data.ConnectionState.Open)
        {
            // Asynchrones Schließen der Verbindung
            await _connection.CloseAsync();
        }
    }

    /// <summary>
    /// Gibt die Datenbankverbindung asynchron frei (IAsyncDisposable Interface).
    /// Diese Methode wird beim "await using" automatisch aufgerufen.
    /// </summary>
    public async ValueTask DisposeAsync()
    {
        // Schließe die Verbindung, bevor sie freigegeben wird
        if (_connection?.State == System.Data.ConnectionState.Open)
        {
            await _connection.CloseAsync();
        }

        // Gib die Ressourcen frei
        _connection?.Dispose();
    }
}