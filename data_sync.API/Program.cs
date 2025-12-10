using data_sync.API.Services;

// .env einmalig beim Start laden via EnvLoadeService (sucht Projektstamm).
// → Die Methode liest die .env Datei (falls vorhanden) und schreibt die Werte in das Prozess-Environment.
// → Bei Fehlern oder wenn die Datei fehlt wird ein Log-Eintrag via FileLogService erzeugt.
EnvLoadeService.LoadDotEnv();

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

// NOTE: Damit die Ressourcen wieder freigegeben werden, wenn der Scope endet, muss IDisposable implementiert sein.
// Registriere GetFilesToSyncService als Scoped (mit automatischem Dispose).
builder.Services.AddScoped<GetFilesToSyncService>();

// Registriere MariaDbService als Scoped (wird pro Request neu erstellt und automatisch disposed)
builder.Services.AddScoped<MariaDbService>();

var app = builder.Build();

// DB-Startup-Checks direkt instanziieren (nicht aus DI)
FileLogService log = new FileLogService("Db-Startup.log");

    try
    {
        using (var dbStartup = new DbStartupCheckService())
        {
            dbStartup.CheckDatabaseConnection();
            dbStartup.CheckDatabaseTables();
        }
    }
    catch (Exception ex)
    {
        log.WriteToLog($"DB-Startup-Fehler: {ex}", "DBStartup");
        Console.WriteLine($"DB-Startup-Fehler: {ex.Message}");
    }

// Testmodus prüfen (Programmargumente)
// Wenn testMode == true, dann werden die Tests ausgeführt.

// Configure the HTTP request pipeline.
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();