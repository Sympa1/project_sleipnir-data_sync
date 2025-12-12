namespace data_sync.API.DTOs;

/// <summary>
/// DTO Modell für den POST request des Manifests vom Client.
/// </summary>
public class ManifestEntryDto
{
    public string FileName { get; set; }
    public string FilePath { get; set; } // kein absoluter Client-Pfad
    public long FileSize { get; set; }
    public DateTime LastModified { get; set; }
    public string Hashvalue { get; set; }
    public FileChangeState FileState { get; set; }
}

/// <summary>
/// DTO Modell für die Antwort des Manifests an den Client.
/// </summary>
public class ManifestOutDto
{
    // Folgt
}

public enum FileChangeState
{
    New,
    Modified,
    Unchanged,
    Deleted,
    Conflict
}