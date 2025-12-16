using data_sync.API.DTOs;

namespace data_sync.API.Services;

// TODO: Das Datum (lasModified) wenn es "null" ist, macht aktuell noch Probleme wenn der HashVal nicht gleich ist.
//  Ggf. vorher prüfen ob der Wert "null" ist.

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
    public async Task<List<ManifestOutDto>> GetFilesToSync(List<ManifestEntryDto> manifests)
    {
        List<ManifestOutDto> filesToSync = new List<ManifestOutDto>();

        foreach (var manifest in manifests)
        {
            ManifestOutDto manifestOut = new ManifestOutDto
                {
                    FileName = manifest.FileName, 
                    FilePath =  manifest.FilePath,
                    FileSize = manifest.FileSize,
                    LastModified = manifest.LastModified,
                    Hashvalue = manifest.Hashvalue,
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
                        dbCommand.CommandText = "SELECT hash_value FROM SyncFiles WHERE file_name = @fileName;";
                        dbCommand.Parameters.AddWithValue("@fileName", manifest.FileName);
                        
                        string? hashFromDb = await dbCommand.ExecuteScalarAsync() as string;

                        string halte = "Punkt";
                        
                        if (string.IsNullOrEmpty(hashFromDb))
                        {
                            // Datei existiert nicht in DB → neue Datei, muss hochgeladen werden
                            manifestOut.FileState = FileChangeState.New;
                            manifestOut.ToUpload = true;
                        }
                        else if (hashFromDb != manifest.Hashvalue)
                        {
                            await using (var dbCommand2 = connection.CreateCommand())
                            {
                                DateTime? lastModifiedFromDb = null;
                                // Optimalerweise noch zusätlich den Dateipfad prüfen
                                dbCommand2.CommandText = "SELECT last_modified FROM SyncFiles WHERE file_name = @fileName;";
                                dbCommand2.Parameters.AddWithValue("@fileName", manifest.FileName);
                        
                                string dateFromDb = await dbCommand2.ExecuteScalarAsync() as string;

                                if (!string.IsNullOrEmpty(dateFromDb))
                                { 
                                    lastModifiedFromDb = DateTime.Parse(dateFromDb!);  
                                }
                            
                                if (!lastModifiedFromDb.HasValue) // Prüft, ob der Wert null ist. Null = false / Wert = true
                                {
                                    // Kein valides Datum in DB -> behandeln (hier: Client als neuer behandeln)
                                    manifestOut.FileState = FileChangeState.Modified;
                                    manifestOut.ToUpload = true;
                                }
                                else if (manifest.LastModified > lastModifiedFromDb.Value)
                                {
                                    manifestOut.FileState = FileChangeState.Modified;
                                    manifestOut.ToUpload = true;
                                }
                                else if (manifest.LastModified < lastModifiedFromDb.Value)
                                {
                                    manifestOut.FileState = FileChangeState.Modified;
                                    manifestOut.ToDownload = true;
                                }
                                else
                                {
                                    manifestOut.FileState = FileChangeState.Conflict;
                                }
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