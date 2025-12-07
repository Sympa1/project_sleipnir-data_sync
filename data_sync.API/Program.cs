using data_sync.API.Services;
using data_sync.API.Data;
using Microsoft.EntityFrameworkCore;
using Npgsql;

// TODO: Migration erstellen und DB Verbindung testen!

var builder = WebApplication.CreateBuilder(args);

// .env einmalig beim Start laden via EnvLoadeService (sucht Projektstamm).
// → Die Methode liest die .env Datei (falls vorhanden) und schreibt die Werte in das Prozess-Environment.
// → Bei Fehlern oder wenn die Datei fehlt, wird ein Log-Eintrag via FileLogService erzeugt.
EnvLoadeService.LoadDotEnv();

// Add services to the container.
builder.Services.AddControllers();

// Registriere GetFilesToSyncService als Scoped (mit automatischem Dispose).
builder.Services.AddScoped<GetFilesToSyncService>();

// ConnectionString
string? connectionString = EnvLoadeService.BuildConnectionStringFromEnv();

// DbContext registrieren (Npgsql provider).
// Scoped lifetime ist Standard: pro HTTP-Request eine Instanz.
builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseNpgsql(connectionString);
});

var app = builder.Build();

// Direkter Npgsql-Open Test für präzise Fehlermeldungen (besser als nur EF CanConnect)
var logger = new FileLogService();
try
{
    await using var directConn = new NpgsqlConnection(connectionString);
    await directConn.OpenAsync();
    // logger.WriteToLog("Direkter Npgsql-Connection Open erfolgreich.", "DBConnection");
    await directConn.CloseAsync();
}
catch (Exception ex)
{
    logger.WriteToLog($"Npgsql Open failed: {ex.GetBaseException()?.Message}\n{ex}", "DBConnectionException");
    Console.WriteLine($"Fehler beim direkten DB-Open: {ex.GetBaseException()?.Message}. Siehe Log.");
}

// Configure the HTTP request pipeline.
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();