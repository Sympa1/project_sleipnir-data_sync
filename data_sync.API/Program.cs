using data_sync.API.Services;

// TODO: DbStartup fertigstellen und hier aufrufen.

// .env einmalig beim Start laden via EnvLoadeService (sucht Projektstamm).
// → Die Methode liest die .env Datei (falls vorhanden) und schreibt die Werte in das Prozess-Environment.
// → Bei Fehlern oder wenn die Datei fehlt, wird ein Log-Eintrag via FileLogService erzeugt.
EnvLoadeService.LoadDotEnv();

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

// Registriere GetFilesToSyncService als Scoped (mit automatischem Dispose).
builder.Services.AddScoped<GetFilesToSyncService>();

// Registriere MariaDbService als Scoped (wird pro Request neu erstellt und automatisch disposed)
builder.Services.AddScoped<MariaDbService>();

var app = builder.Build();

// DB-Startup-Checks in einem Scope ausführen (Scoped Services korrekt verwenden)
using (var scope = app.Services.CreateScope())
{
    var dbStartup = scope.ServiceProvider.GetRequiredService<DbStartupCheckService>();
    var log = scope.ServiceProvider.GetRequiredService<FileLogService>();
    try
    {
        dbStartup.CheckDatabaseConnection();
        dbStartup.CheckDatabaseTables();
    }
    catch (Exception ex)
    {
        log.WriteToLog($"DB-Startup-Fehler: {ex}", "DBStartup");
        Console.WriteLine($"DB-Startup-Fehler: {ex.Message}");
    }
}

// Configure the HTTP request pipeline.
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();