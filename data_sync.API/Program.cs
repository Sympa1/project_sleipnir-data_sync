using data_sync.API.Services;
using data_sync.API.Tests;

// .env einmalig beim Start laden via EnvLoadeService (sucht Projektstamm).
EnvLoadeService.LoadDotEnv();

// Testmodus-Flag
//bool testMode = true;
bool testMode = false;


var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

if (testMode)
{
    builder.Services.AddScoped<TestService>();
}

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
if (testMode)
{
    using (var scope = app.Services.CreateScope())
    {
        var testService = scope.ServiceProvider.GetRequiredService<TestService>();
        // Hier können verschiedene Testmethoden aufgerufen werden
        testService.ChoiceTest(1); // Beispiel: Testvariante 1 ausführen
    }
}

// Configure the HTTP request pipeline.
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();