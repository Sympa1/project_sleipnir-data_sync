namespace data_sync.API.Models;

public enum SyncAction
{
    Download = 0,  // Datei heruntergeladen
    Upload = 1,    // Datei hochgeladen
    Conflict = 2,  // Konflikt aufgelöst
    Delete = 3,    // Datei gelöscht
    Error = 4      // Fehler bei Synchronisierung
}