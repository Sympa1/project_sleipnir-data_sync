using data_sync.API.DTOs;

namespace data_sync.API.Services;

// TODO:
//  - Datei löschen (ToDelet) - Logik nach Foreach-Schleife: DB-Dateien, die nicht im Manifest sind
//  - Query-Optimierung: 3 separate Queries zu einem SELECT kombinieren (hash_value, file_path, modified_at)
//  - Parameter-Bug: dbCommand.Parameters müssen zwischen Queries gelöscht werden (Parameters.Clear())
//  - Nullable-Vergleiche absichern: DateTime? vor Vergleich auf HasValue prüfen (Z. 99, 104)
//  - Ineffiziente DB-Connection: Nicht für jede Datei neue Connection öffnen

public class GetFilesToSyncService
{
    private readonly MariaDbService _dbService;
    
    public GetFilesToSyncService(MariaDbService mariaDbService)
    {
        _dbService = mariaDbService;
    }
    
    /// <summary>
    /// Ermittelt, anhand der Manifestliste, die zu synchronisierenden Dateien.
    /// </summary>
    /// <param name="manifests">Liste: ManifestDto</param>
    /// <returns>Liste: filesToSync</returns>
    public async Task<List<ManifestResponseDto>> GetFilesToSync(List<ManifestEntryDto> manifests)
    {
        List<ManifestResponseDto> filesToSync = new List<ManifestResponseDto>();

        foreach (var manifest in manifests)
        {
            ManifestResponseDto manifestOut = new ManifestResponseDto
                {
                    FileName = manifest.FileName, 
                    FilePath =  manifest.FilePath,
                    FileSize = manifest.FileSize,
                    Hashvalue = manifest.Hashvalue,
                    CreatedAt = manifest.CreatedAt,
                    LastModified = manifest.LastModified,
                    FileState = manifest.FileState,
                    ToUpload = false,
                    ToDelet = false,
                    ToDownload = false
                }; 
            
            await using (var connection = await _dbService.OpenConnectionAsync())
            {
                if (connection != null)
                {
                    await using (var dbCommand = connection.CreateCommand())
                    {
                        // Optimalerweise noch zusätlich den Dateipfad prüfen
                        dbCommand.CommandText = "SELECT hash_value FROM SyncFiles WHERE file_path = @filePath;";
                        dbCommand.Parameters.AddWithValue("@filePath", manifest.FilePath);
                        string? hashFromDb = await dbCommand.ExecuteScalarAsync() as string;
                        
                        dbCommand.CommandText = "SELECT file_path FROM SyncFiles WHERE hash_value = @hashValue;";
                        dbCommand.Parameters.AddWithValue("@hashValue", manifest.Hashvalue);
                        string? filePathFromDb = await dbCommand.ExecuteScalarAsync() as string;
                        
                        dbCommand.CommandText = "SELECT modified_at FROM SyncFiles WHERE file_path = @filePath;";
                        dbCommand.Parameters.AddWithValue("@filePath", manifest.FilePath);
                        string? modifiedAtFromDb = await dbCommand.ExecuteScalarAsync() as string;
                        
                        DateTime? lastModifiedAtFromDb = null;

                        if (!string.IsNullOrEmpty(modifiedAtFromDb))
                        {
                            lastModifiedAtFromDb = DateTime.Parse(modifiedAtFromDb);
                        }

                        if (string.IsNullOrEmpty(hashFromDb))
                        {
                            // Datei existiert nicht in DB → neue Datei, muss hochgeladen werden
                            manifestOut.ToUpload = true;
                        }
                        else if (hashFromDb != manifest.Hashvalue)
                        {
                            await using (var dbCommand2 = connection.CreateCommand())
                            {
                                if (!lastModifiedAtFromDb.HasValue) // Prüft, ob der Wert null ist. Null = false / Wert = true
                                {
                                    // Kein valides Datum in DB -> behandeln (hier: Client als neuer behandeln)
                                    manifestOut.ToUpload = true;
                                }
                                else if (manifest.LastModified > lastModifiedAtFromDb.Value)
                                {
                                    manifestOut.ToUpload = true;
                                }
                                else if (manifest.LastModified < lastModifiedAtFromDb.Value)
                                {
                                    manifestOut.ToDownload = true;
                                }
                                else
                                {
                                    manifestOut.FileState = FileChangeState.Conflict;
                                }
                            }
                        }
                        else if (filePathFromDb != manifest.FilePath)
                        {
                            // Datei wurde verschoben/umbenannt
                            if (lastModifiedAtFromDb < manifest.LastModified)
                            {
                                // Client hat die aktuellere Version → hochladen
                                manifestOut.ToUpload = true;
                            }
                            else if (lastModifiedAtFromDb > manifest.LastModified)
                            {
                                // Server hat die aktuellere Version → herunterladen
                                manifestOut.ToDownload = true;
                            }
                        }
                        else
                        {
                            // Hash gleich → Datei ist synchron, nicht nötig zu synchronisieren
                            manifestOut.FileState = FileChangeState.Unchanged;
                        }
                    }
                }
            }
            filesToSync.Add(manifestOut);
        }
        
        return filesToSync;
    }
}