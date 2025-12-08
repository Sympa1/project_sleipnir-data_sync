using data_sync.API.Services;

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

// DB-Verbindungstest beim Start
// TODO: Hier per DI den DbStartupCheckService aufrufen, der den Test durchführt.

// Configure the HTTP request pipeline.
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();