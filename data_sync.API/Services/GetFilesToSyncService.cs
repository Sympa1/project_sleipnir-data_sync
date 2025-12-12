using data_sync.API.DTOs;

namespace data_sync.API.Services;

public class GetFilesToSyncService
{
    /// <summary>
    /// Ermittelt, anhand der Manifestliste, die zu synchronisierenden Dateien.
    /// </summary>
    /// <param name="manifests">Liste: ManifestDto</param>
    /// <returns>Liste: filesToSync</returns>
    public async Task<List<ManifestOutDto>> GetFilesToSync(List<ManifestEntryDto> manifests)
    {
        List<ManifestOutDto> filesToSync = new List<ManifestOutDto>();
        
        foreach(var manifest in manifests)
        {
            // Test zum schauen wie die Daten als Response zurückgegeben werden
            // Nur Dateien mit Status New, Modified, Deleted oder Conflict werden synchronisiert
            if (manifest.FileState == FileChangeState.New ||
                manifest.FileState == FileChangeState.Modified ||
                manifest.FileState == FileChangeState.Deleted ||
                manifest.FileState == FileChangeState.Conflict)
            {
                filesToSync.Add(new ManifestOutDto
                {
                    FileName = manifest.FileName,
                    FilePath = manifest.FilePath,
                    FileSize = manifest.FileSize,
                    LastModified = manifest.LastModified,
                    Hashvalue = manifest.Hashvalue,
                    FileState = manifest.FileState,
                    ToUpload = false,
                    ToDelet = false,
                    ToDownload = false
                });
            }
        }
        
        return filesToSync;
    }
}