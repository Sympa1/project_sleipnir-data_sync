namespace data_sync.API.Tests;

public class TestService
{
    // Steuert Tests und wird je nach Option in der Programm.cs ausgeführt
    public void ChoiceTest(int testVariante)
    {
        switch (testVariante)
        {
            case 1:
                DbErrorLogServiceTests dbErrorLogTests = new DbErrorLogServiceTests();
                dbErrorLogTests.LogDbErrorAsync_ShouldLogException();
                break;
            case 2:
                // Testvariante 2 ausführen
                break;
            default:
                // Standardaktion oder Fehlerbehandlung
                break;
        }
    }
}