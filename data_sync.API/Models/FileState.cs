namespace data_sync.API.Models;

public enum FileState
{
    Synced = 0,      // Datei ist synchronisiert
    Modified = 1,    // Datei wurde lokal geändert
    Conflict = 2,    // Konflikt erkannt
    Deleted = 3      // Datei wurde gelöscht
}