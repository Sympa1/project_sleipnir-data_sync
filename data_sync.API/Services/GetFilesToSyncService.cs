using data_sync.API.DTOs;

namespace data_sync.API.Services;

public class GetFilesToSyncService
{
    /// <summary>
    /// Ermittelt, anhand der Manifestliste, die zu synchronisierenden Dateien.
    /// </summary>
    /// <param name="manifests">Liste: ManifestDto</param>
    /// <returns>Liste: filesToSync</returns>
    public async Task<List<FilesToSyncDto>> GetFilesToSync(List<ManifestDto> manifests)
    {
        List<FilesToSyncDto> filesToSync = new List<FilesToSyncDto>();
        
        return filesToSync;
    }
}