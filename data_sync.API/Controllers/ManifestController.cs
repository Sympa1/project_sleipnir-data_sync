using Microsoft.AspNetCore.Mvc;
using data_sync.API.DTOs;
using data_sync.API.Services;

namespace data_sync.API.Controllers;

// NOTE: Beim Download zum Client muss anschließend der Hashwert vom Client neu berechnet und in der ClientDB aktualisiert werden.

[ApiController]
[Route("api/sync/[controller]")]
public class ManifestController : ControllerBase
{
    private readonly GetFilesToSyncService _filesToSyncService;
    
    /// <summary>
    /// Konstruktor für ManifestController, der GetFilesToSyncService injiziert.
    /// </summary>
    /// <param name="filesToSyncService"></param>
    public ManifestController(GetFilesToSyncService filesToSyncService)
    {
        _filesToSyncService = filesToSyncService;
    }
    
    [HttpPost]
    public async Task<IActionResult> PostManifestByClient([FromBody] List<ManifestEntryDto> manifests)
    {
        if (manifests.Count == 0)
            return BadRequest("Manifest missing or invalid.");
        
        // Ermittle Dateien, die synchronisiert werden müssen
        var filesToSync = await _filesToSyncService.GetFilesToSync(manifests);
        
        // Gib dem Client die Liste der zu synchronisierenden Dateien zurück
        return Ok(filesToSync);
    }
}

