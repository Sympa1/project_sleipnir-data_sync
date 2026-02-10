using data_sync.API.DTOs;
using Microsoft.Extensions.Logging;

namespace data_sync.API.Services;


public class GetFilesToSyncService
{
    private readonly MariaDbService _dbService;
    private readonly ILogger<GetFilesToSyncService> _logger;
    
    public GetFilesToSyncService(MariaDbService mariaDbService, ILogger<GetFilesToSyncService> logger)
    {
        _dbService = mariaDbService;
        _logger = logger;
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
                        // Suche nach Dateipfad in DB
                        dbCommand.CommandText = "SELECT hash_value, last_modified, file_state FROM SyncFiles WHERE file_path = @filePath;";
                        dbCommand.Parameters.AddWithValue("@filePath", manifest.FilePath);
                        
                        await using (var reader = await dbCommand.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                // Datei mit gleichem Pfad in DB gefunden
                                // Sicherstellen das NULL-Werte mit Werten versehen werden, sodass es keinen Fehler gibt
                                // Setzt den Wert auf 0 oder 1 wenn der Wert NULL ist. Die Zahl wird als String gespeichert
                                string? hashFromDb = reader.IsDBNull(0) ? null : reader.GetString(0);
                                DateTime? modifiedAtFromDb = reader.IsDBNull(1) ? null : reader.GetDateTime(1);
                                string? fileStateFromDb = reader.IsDBNull(2) ? null : reader.GetString(2);
                                
                                // DEBUG Logging
                                _logger.LogInformation($"Comparing file: {manifest.FilePath}");
                                _logger.LogInformation($"  Client hash: {manifest.Hashvalue}");
                                _logger.LogInformation($"  Server hash: {hashFromDb}");
                                _logger.LogInformation($"  Equal: {hashFromDb == manifest.Hashvalue}");
                                
                                // Prüfe ob Datei auf Server gelöscht wurde
                                if (fileStateFromDb == "deleted")
                                {
                                    manifestOut.ToDelet = true;
                                    manifestOut.FileState = FileChangeState.Deleted;
                                }
                                else if (hashFromDb == manifest.Hashvalue)
                                {
                                    // Hash gleich → Datei ist synchron
                                    _logger.LogInformation($"  Decision: UNCHANGED (hashes match)");
                                    manifestOut.FileState = FileChangeState.Unchanged;
                                }
                                else
                                {
                                    // Hash unterschiedlich → Konflikt-Auflösung per Timestamp
                                    _logger.LogInformation($"  Decision: Comparing timestamps (hashes differ)");
                                    if (modifiedAtFromDb.HasValue && manifest.LastModified > modifiedAtFromDb.Value)
                                    {
                                        _logger.LogInformation($"  Decision: TO_UPLOAD (client newer)");
                                        manifestOut.ToUpload = true;
                                    }
                                    else if (modifiedAtFromDb.HasValue && manifest.LastModified < modifiedAtFromDb.Value)
                                    {
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
                                // Kein Eintrag mit diesem Pfad → prüfe ob Datei verschoben wurde
                                // Es kann nur einen aktiven Reader geben, also diesen schließen
                                await reader.CloseAsync();
                                dbCommand.Parameters.Clear();
                                
                                // Suche nach Hash (verschobene/umbenannte Datei?)
                                dbCommand.CommandText = "SELECT file_path, last_modified FROM SyncFiles WHERE hash_value = @hashValue;";
                                dbCommand.Parameters.AddWithValue("@hashValue", manifest.Hashvalue);
                                
                                await using (var reader2 = await dbCommand.ExecuteReaderAsync())
                                {
                                    if (await reader2.ReadAsync())
                                    {
                                        // Datei mit gleichem Hash aber anderem Pfad gefunden
                                        string existingFilePath = reader2.GetString(0);
                                        DateTime? modifiedAtFromDb = reader2.IsDBNull(1) ? null : reader2.GetDateTime(1);
                                        
                                        // Prüfe ob es wirklich eine Verschiebung ist (gleicher Dateiname)
                                        string existingFileName = Path.GetFileName(existingFilePath);
                                        string manifestFileName = Path.GetFileName(manifest.FilePath);
                                        
                                        if (existingFileName == manifestFileName)
                                        {
                                            // Gleicher Name + Hash → wahrscheinlich verschoben/umbenannt
                                            _logger.LogInformation($"Possible file move detected: {existingFilePath} -> {manifest.FilePath}");
                                            
                                            if (modifiedAtFromDb.HasValue && manifest.LastModified > modifiedAtFromDb.Value)
                                            {
                                                // Client hat neuere Version → hochladen
                                                manifestOut.ToUpload = true;
                                            }
                                            else if (modifiedAtFromDb.HasValue && manifest.LastModified < modifiedAtFromDb.Value)
                                            {
                                                // Server hat neuere Version → herunterladen
                                                manifestOut.ToDownload = true;
                                            }
                                            else
                                            {
                                                // Timestamps gleich → hochladen (Client-Änderung akzeptieren)
                                                manifestOut.ToUpload = true;
                                            }
                                        }
                                        else
                                        {
                                            // Unterschiedlicher Name → neue Datei mit gleichem Inhalt (Kopie/Duplikat)
                                            _logger.LogInformation($"New file with existing content: {manifest.FilePath} (duplicate of {existingFilePath})");
                                            manifestOut.ToUpload = true;
                                        }
                                    }
                                    else
                                    {
                                        // Weder Pfad noch Hash gefunden → wenn Filestat != 'deleted' = neue Datei
                                        //if (fileStateFromDb != "Deleted")
                                        if (manifest.FileState == FileChangeState.Deleted)
                                        {
                                            manifestOut.ToDelet = true;
                                        }
                                        else
                                        {
                                            manifestOut.ToUpload = true;
                                        }
                                            
                                    }
                                }
                            }
                        }
                    }
                }
            }
            filesToSync.Add(manifestOut);
        }
        
        // Finde Server-Dateien die nicht im Manifest sind
        await using (var connection = await _dbService.OpenConnectionAsync())
        {
            if (connection != null)
            {
                await using (var dbCommand = connection.CreateCommand())
                {
                    // Hole alle Dateipfade aus der DB
                    dbCommand.CommandText = "SELECT file_path, file_name, file_size, hash_value, created_at, last_modified, file_state FROM SyncFiles;";
                    
                    await using (var reader = await dbCommand.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            string filePathFromDb = reader.GetString(0);
                            
                            // Prüfe ob dieser Pfad im Manifest vorhanden ist
                            bool existsInManifest = manifests.Any(m => m.FilePath == filePathFromDb);
                            
                            if (!existsInManifest)
                            {
                                // Datei ist auf Server aber nicht im Client-Manifest
                                string fileNameFromDb = reader.GetString(1);
                                long fileSizeFromDb = reader.GetInt64(2);
                                string hashValueFromDb = reader.IsDBNull(3) ? string.Empty : reader.GetString(3);
                                DateTime createdAtFromDb = reader.IsDBNull(4) ? DateTime.MinValue : reader.GetDateTime(4);
                                DateTime modifiedAtFromDb = reader.IsDBNull(5) ? DateTime.MinValue : reader.GetDateTime(5);
                                string fileStateFromDb = reader.IsDBNull(6) ? "Unchanged" : reader.GetString(6);
                                
                                ManifestResponseDto serverFile = new ManifestResponseDto
                                {
                                    FileName = fileNameFromDb,
                                    FilePath = filePathFromDb,
                                    FileSize = fileSizeFromDb,
                                    Hashvalue = hashValueFromDb,
                                    CreatedAt = createdAtFromDb,
                                    LastModified = modifiedAtFromDb,
                                    FileState = Enum.Parse<FileChangeState>(fileStateFromDb, ignoreCase:true), // Enum großgeschrieben, in DB kleingeschrieben
                                    ToUpload = false,
                                    ToDelet = fileStateFromDb == "Deleted",
                                    ToDownload = fileStateFromDb != "Deleted"
                                };
                                
                                filesToSync.Add(serverFile);
                            }
                        }
                    }
                }
            }
        }
        
        return filesToSync;
    }
}