using System;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using data_sync.API.Services;
using Xunit;

namespace data_sync.API.Tests;

/// <summary>
/// Bereitet die DI für die Unittests vor. Das ist notwendi, da Unittests eigentlich als eigenständiges Programm
/// laufen.
/// </summary>
public class CreateServiceProvider
{
    private ServiceProvider _serviceProvider;  // Der DI-Container
    public IServiceScope Scope { get; set; }   // Der aktuelle Scope

    /// <summary>
    /// Wird vor jedem Test aufgerufen und erstellt die Scopes.
    /// </summary>
    public void Initialize()
    {
        var services = new ServiceCollection();  // Neuer Container (wie builder.Services)
        services.AddScoped<MariaDbService>();   // Registriere deine Services
        
        _serviceProvider = services.BuildServiceProvider();  // Container bauen
        Scope = _serviceProvider.CreateScope();  // Einen Scope erstellen
    }

    /// <summary>
    /// Soll nach jedem Test aufgerufen werden.
    /// </summary>
    public void Cleanup()
    {
        Scope?.Dispose();
        _serviceProvider?.Dispose();
    }
}


public class DbErrorLogServiceTests
{
    private CreateServiceProvider _fixture;

    // Konstruktor: Fixture initialisieren
    public DbErrorLogServiceTests()
    {
        _fixture = new CreateServiceProvider();
        _fixture.Initialize();
    }

    public void LogDbErrorAsyncException()
    {
        // Arrange
        // Jetzt holst du MariaDbService aus dem Fixture-Scope statt aus app
        var mariaDbService = _fixture.Scope.ServiceProvider.GetRequiredService<MariaDbService>();
        var dbErrorLogService = new DbErrorLogService(mariaDbService);
        var testException = new Exception("Test exception message");
        var contextInfo = "UnitTest";

        // Act
        var logTask = dbErrorLogService.LogDbErrorAsync(testException, contextInfo);
        logTask.Wait();

        // Assert
    }

    // Cleanup nach dem Test
    public void Dispose()
    {
        _fixture.Cleanup();
    }
}
