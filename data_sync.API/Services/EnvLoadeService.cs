using DotNetEnv; // --> NuGet-Paket DotNetEnv

namespace data_sync.API.Services;

/// <summary>
/// EnvLoadeService
/// ----------------
/// Hilfsklasse zum Laden von Umgebungsvariablen aus einer .env-Datei.
/// Vorhandene Prozess-Umgebungsvariablen bleiben dabei der bevorzugte Fallback,
/// damit Container-Deployments ohne lokale .env-Datei funktionieren.
///
/// Verwendung:
/// - Aufruf von <see cref="LoadDotEnv()"/> beim Applikationsstart lädt die .env-Datei
///   (falls vorhanden) aus dem Arbeitsverzeichnis und schreibt die Werte in die Prozess-Environment.
/// - Fehlt die Datei, können die Werte weiterhin direkt aus den Umgebungsvariablen des Prozesses stammen
///   (zum Beispiel aus Docker Compose).
/// - Aufruf von <see cref="BuildConnectionStringFromEnv()"/> erzeugt einen ConnectionString,
///   wenn die erforderlichen ENV-Variablen vorhanden sind.
///
/// Erwartete Variablen in der .env-Datei:
/// - DB_HOST    (z. B. localhost)
/// - DB_PORT    (optional, z. B. 5432)
/// - DB_NAME    (z. B. postgres)
/// - DB_USER    (z. B. postgres)
/// - DB_PASSWORD (optional)
///
/// Fehlerverhalten:
/// - Fehlt die .env-Datei und es sind auch keine erforderlichen ENV-Variablen vorhanden,
///   wird ein Eintrag in das Error-Log via FileLogService geschrieben.
/// - Tritt beim Erzeugen des ConnectionStrings eine Exception auf, wird ebenfalls in das Log geschrieben.
///</summary>
public class EnvLoadeService
{
    /// <summary>
    /// Lädt die .env-Datei aus dem Arbeitsverzeichnis und gibt true zurück, wenn die Datei gefunden und geladen wurde.
    /// </summary>
    /// <returns>bool: true, wenn .env gefunden und geladen wurde; false sonst.</returns>
    public static bool LoadDotEnv()
    {
        try
        {
            // Aktuelles Arbeitsverzeichnis
            string currentDir = Environment.CurrentDirectory;

            // Projektstammverzeichnis suchen (ein oder zwei Ebenen nach oben).
            //string projectDir = Path.GetFullPath(Path.Combine(currentDir, "..", "..", ".."));

            string envPath = Path.Combine(currentDir, ".env");

            if (File.Exists(envPath))
            {
                Env.Load(envPath);
                Console.WriteLine($".env geladen aus: {envPath}");
                return true;
            }

            if (HasRequiredDatabaseVariables())
            {
                Console.WriteLine("Keine lokale .env-Datei gefunden. Vorhandene Umgebungsvariablen werden verwendet.");
                return false;
            }

            var logger = new FileLogService();
            logger.WriteToLog($".env-Datei nicht gefunden im Arbeitsverzeichnis: {envPath}", "EnvLoad");

            Console.WriteLine(".env-Datei nicht gefunden und keine vollständige Datenbankkonfiguration in den Umgebungsvariablen vorhanden.");
            return false;
        }
        catch (Exception ex)
        {
            // Bei Fehlern während des Ladens -> Log
            var logger = new FileLogService();
            logger.WriteToLog($"Fehler beim Laden der .env Datei: {ex}", "EnvLoadException");

            Console.WriteLine($"Fehler beim Laden der .env Datei: {ex.Message}");
            return false;
        }
    }

    /// <summary>
    /// Prüft, ob die für die Datenbankverbindung erforderlichen Umgebungsvariablen bereits gesetzt sind.
    /// </summary>
    /// <returns>True, wenn alle Pflichtvariablen vorhanden sind, sonst false.</returns>
    private static bool HasRequiredDatabaseVariables()
    {
        string? dbHost = Environment.GetEnvironmentVariable("DB_HOST");
        string? dbName = Environment.GetEnvironmentVariable("DB_NAME");
        string? dbUser = Environment.GetEnvironmentVariable("DB_USER");
        string? dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");

        return !string.IsNullOrWhiteSpace(dbHost)
               && !string.IsNullOrWhiteSpace(dbName)
               && !string.IsNullOrWhiteSpace(dbUser)
               && !string.IsNullOrWhiteSpace(dbPassword);
    }

    /// <summary>
    /// Baut einen MariaDB-ConnectionString aus den Umgebungsvariablen (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD).
    /// Gibt null zurück, wenn nicht genügend Variablen gesetzt sind.
    /// </summary>
    /// <returns>ConnectionString oder null</returns>
    public static string? BuildConnectionStringFromEnv()
    {
        try
        {
            string? dbHost = Environment.GetEnvironmentVariable("DB_HOST");
            string? dbPort = Environment.GetEnvironmentVariable("DB_PORT");
            string? dbName = Environment.GetEnvironmentVariable("DB_NAME");
            string? dbUser = Environment.GetEnvironmentVariable("DB_USER");
            string? dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");

            if (string.IsNullOrWhiteSpace(dbHost) || string.IsNullOrWhiteSpace(dbName) || string.IsNullOrWhiteSpace(dbUser))
            {
                // Unvollständige Angaben -> return null.
                return null;
            }

            // Nur Segment anhängen, wenn Variable gesetzt -> verhindert unnötige Semikolons.
            var portSegment = string.IsNullOrWhiteSpace(dbPort) ? string.Empty : $";Port={dbPort}";
            var passwordSegment = string.IsNullOrWhiteSpace(dbPassword) ? string.Empty : $";Password={dbPassword}";

            var cs = $"Host={dbHost}{portSegment};Database={dbName};Username={dbUser}{passwordSegment}";
            return cs;
        }
        catch (Exception ex)
        {
            var logger = new FileLogService();
            logger.WriteToLog($"Fehler beim Erzeugen des ConnectionStrings aus ENV: {ex}", "EnvBuildException");
            return null;
        }
    }
}
