using data_sync.API.Services;
using data_sync.API.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// .env einmalig beim Start laden via EnvLoadeService (sucht Projektstamm)
// → Die Methode liest die .env Datei (falls vorhanden) und schreibt die Werte in das Prozess-Environment.
// → Bei Fehlern oder wenn die Datei fehlt, wird ein Log-Eintrag via FileLogService erzeugt.
EnvLoadeService.LoadDotEnv();

// Add services to the container.
builder.Services.AddControllers();

// Registriere GetFilesToSyncService als Scoped (mit automatischem Dispose)
builder.Services.AddScoped<GetFilesToSyncService>();

// ConnectionString
string? connectionString = EnvLoadeService.BuildConnectionStringFromEnv();

// DbContext registrieren (Npgsql provider)
// Scoped lifetime ist Standard: pro HTTP-Request eine Instanz
builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseNpgsql(connectionString);
});

var app = builder.Build();

// Startup-Check: Probeverbindung zur DB und Logging
// Ziel: Direkt beim Start auffangen, wenn die DB nicht erreichbar ist und einen verständlichen Fehler ins Log schreiben.
try
{
    using var scope = app.Services.CreateScope();
    var services = scope.ServiceProvider;
    var logger = new FileLogService();

    try
    {
        var db = services.GetRequiredService<ApplicationDbContext>();
        // CanConnect() prüft, ob die DB erreichbar ist (keine Migration/Schema-Checks)
        if (!db.Database.CanConnect())
        {
            // Schreibe eine aussagekräftige Fehlermeldung in das Error-Log
            logger.WriteToLog($"Datenbankverbindung konnte nicht hergestellt werden", "DBConnection");
            Console.WriteLine("Warnung: Verbindung zur Datenbank konnte nicht hergestellt werden. Siehe Log.");
        }
    }
    catch (Exception ex)
    {
        // Logge die Exception inkl. maskiertem ConnectionString
        logger.WriteToLog($"Fehler beim Herstellen der DB-Verbindung: {ex}\n", "DBConnectionException");
        Console.WriteLine($"Fehler beim Herstellen der DB-Verbindung: {ex.Message}. Siehe Log.");
    }
}
catch (Exception ex)
{
    // Falls etwas beim Start-Check komplett schiefgeht, loggen
    var logger = new FileLogService();
    logger.WriteToLog($"Unerwarteter Fehler im Startup-Check: {ex}", "StartupCheckException");
}

// Configure the HTTP request pipeline.
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();