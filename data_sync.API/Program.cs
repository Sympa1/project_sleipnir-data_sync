using System.Net;
using data_sync.API.Services;
using Microsoft.AspNetCore.HttpOverrides;
//using data_sync.API.Tests;

static void ConfigureEndpoint(Microsoft.AspNetCore.Server.Kestrel.Core.KestrelServerOptions options, string url, bool useHttps)
{
    var endpointUri = new Uri(url);
    var port = endpointUri.Port;

    void ConfigureListenOptions(Microsoft.AspNetCore.Server.Kestrel.Core.ListenOptions listenOptions)
    {
        if (useHttps)
        {
            listenOptions.UseHttps();
        }
    }

    if (endpointUri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase))
    {
        options.ListenLocalhost(port, ConfigureListenOptions);
        return;
    }

    if (endpointUri.Host is "0.0.0.0" or "::" or "+")
    {
        options.ListenAnyIP(port, ConfigureListenOptions);
        return;
    }

    if (IPAddress.TryParse(endpointUri.Host, out var ipAddress))
    {
        options.Listen(ipAddress, port, ConfigureListenOptions);
        return;
    }

    options.ListenAnyIP(port, ConfigureListenOptions);
}

// .env einmalig beim Start laden via EnvLoadeService (sucht Projektstamm).
EnvLoadeService.LoadDotEnv();

// Testmodus-Flag
//bool testMode = true;
bool testMode = false;


var builder = WebApplication.CreateBuilder(args);
bool enableHttpsEndpoint = builder.Configuration.GetValue("EnableHttpsEndpoint", builder.Environment.IsDevelopment());
bool enableHttpsRedirection = builder.Configuration.GetValue("EnableHttpsRedirection", enableHttpsEndpoint);

builder.WebHost.ConfigureKestrel(options =>
{
    // Deaktiviert die minimale Datenrate fuer eingehende Request-Bodies.
    options.Limits.MinRequestBodyDataRate = null;

    var httpUrl = builder.Configuration["ServerEndpoints:Http:Url"] ?? "http://0.0.0.0:5000";
    ConfigureEndpoint(options, httpUrl, useHttps: false);

    if (enableHttpsEndpoint)
    {
        var httpsUrl = builder.Configuration["ServerEndpoints:Https:Url"];

        if (!string.IsNullOrWhiteSpace(httpsUrl))
        {
            ConfigureEndpoint(options, httpsUrl, useHttps: true);
        }
    }
});

// Add services to the container.
builder.Services.AddControllers()
    // JSON-Deserialisierung: PascalCase (statt default camelCase) akzeptieren
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = null;
    });

builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    // Caddy setzt diese Header, damit ASP.NET das urspruengliche HTTPS-Schema kennt.
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedHost;

    // Im Compose-Netz bekommt der Proxy eine dynamische interne IP.
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
});

if (testMode)
{
    //builder.Services.AddScoped<TestService>();
}

// NOTE: Damit die Ressourcen wieder freigegeben werden, wenn der Scope endet, muss IDisposable implementiert sein.
// Registriere GetFilesToSyncService als Scoped (mit automatischem Dispose).
builder.Services.AddScoped<GetFilesToSyncService>();

// Registriere MariaDbService als Scoped (wird pro Request neu erstellt und automatisch disposed)
builder.Services.AddScoped<MariaDbService>();

builder.Services.AddScoped<UpdateMetadataService>();

// Registriere SyncStateService für LastSyncState-Verwaltung
builder.Services.AddScoped<SyncStateService>();

var app = builder.Build();

// DB-Startup-Checks direkt instanziieren (nicht aus DI)
FileLogService log = new FileLogService("Db-Startup.log");

    try
    {
        var scope = app.Services.CreateScope();
        var mariaDbService = scope.ServiceProvider.GetRequiredService<MariaDbService>();
        
        await using (var dbStartup = new DbStartupCheckService(mariaDbService))
        {
            await dbStartup.CheckDatabaseConnectionAsync();
            await dbStartup.CheckDatabaseTablesAsync();
        }
    }
    catch (Exception ex)
    {
        log.WriteToLog($"DB-Startup-Fehler: {ex}", "DBStartup");
        Console.WriteLine($"DB-Startup-Fehler: {ex.Message}"); 
    }

// Testmodus prüfen (Programmargumente)
// if (testMode)
// {
//     using (var scope = app.Services.CreateScope())
//     {
//         var testService = scope.ServiceProvider.GetRequiredService<TestService>();
//         // Hier können verschiedene Testmethoden aufgerufen werden
//         testService.ChoiceTest(1); // Beispiel: Testvariante 1 ausführen
//     }
// }

// Muss vor weiterer Middleware laufen, damit Request.Scheme hinter Caddy korrekt auf https steht.
app.UseForwardedHeaders();

// HTTPS-Umleitung bleibt konfigurierbar, damit Container ohne Zertifikat sauber per HTTP laufen koennen.
if (enableHttpsRedirection)
{
    app.UseHttpsRedirection();
}

app.UseAuthorization();
app.MapControllers();

app.Run();
