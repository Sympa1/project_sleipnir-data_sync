using Sleipnir.API.DTOs;
namespace Sleipnir.API.Services;

public class GetFilesToSyncService
{
    private readonly MySQLService _mySqlService;

    /// <summary>
    /// Konstruktor für GetFilesToSyncService, der MySQLService injiziert.
    /// </summary>
    /// <param name="mySqlService"></param>
    public GetFilesToSyncService(MySQLService mySqlService)
    {
        _mySqlService = mySqlService;
    }
    
    public async Task<List<FilesToSyncDto>> GetFilesToSync(List<ManifestDto> manifests)
    {
        List<FilesToSyncDto> filesToSync = new List<FilesToSyncDto>();
        // TODO: Implementierung DB Connection
        
        // TODO: foreach über Manifests
            // TODO: Prüfen ob Datei in DB existiert
            // TODO: Wenn nicht, in neue Liste aufnehmen

            return filesToSync;
    }
}