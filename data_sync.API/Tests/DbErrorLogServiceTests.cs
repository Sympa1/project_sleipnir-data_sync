using System;
using System.Threading.Tasks;
using data_sync.API.Services;
using Xunit;

namespace data_sync.API.Tests;


public class DbErrorLogServiceTests
{
    // Testet, ob LogDbErrorAsync eine Exception protokolliert

    public void LogDbErrorAsync_ShouldLogException()
    {
        // Arrange
        var mariaDbService = new MariaDbService();
        var dbErrorLogService = new DbErrorLogService(mariaDbService);
        var testException = new Exception("Test exception message");
        var contextInfo = "UnitTest";

        // Act
        var logTask = dbErrorLogService.LogDbErrorAsync(testException, contextInfo);
        logTask.Wait(); // Warten auf den Abschluss der asynchronen Methode

        // Assert
        // Hier
    }
}
