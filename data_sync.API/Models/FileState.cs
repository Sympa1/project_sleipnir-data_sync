namespace data_sync.API.Models;

public enum FileState
{
    New = 0,      // Datei ist synchronisiert
    Modified = 1,    // Datei wurde lokal geändert
    Deleted = 2,    // Konflikt erkannt
    error = 3      // Datei wurde gelöscht
}