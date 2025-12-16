using Microsoft.AspNetCore.Mvc;
using data_sync.API.DTOs;
using data_sync.API.Services;

namespace data_sync.API.Controllers;

// NOTE: Beim Download zum Client muss anschließend der Hashwert vom Client neu berechnet und in der ClientDB aktualisiert werden.

[ApiController]
[Route("api/[controller]")]
public class SyncController : ControllerBase
{
    private readonly GetFilesToSyncService _filesToSyncService;
    
    /// <summary>
    /// Konstruktor für SyncController, der GetFilesToSyncService injiziert.
    /// </summary>
    /// <param name="filesToSyncService"></param>
    public SyncController(GetFilesToSyncService filesToSyncService)
    {
        _filesToSyncService = filesToSyncService;
    }
    
    [HttpPost]
    [Route("manifest")]
    public async Task<IActionResult> PostManifestByClient([FromBody] List<ManifestEntryDto> manifests)
    {
        if (manifests.Count == 0)
            return BadRequest("Manifest missing or invalid.");
        
        // Ermittle Dateien, die synchronisiert werden müssen
        var filesToSync = await _filesToSyncService.GetFilesToSync(manifests);
        
        // Gib dem Client die Liste der zu synchronisierenden Dateien zurück
        return Ok(filesToSync);
    }

    [HttpPost]
    [Route("upload")]
    public async Task<IActionResult> UploadFile()
    {
        // Vorbereitungen zum Upload einer Datei
        return null;
    }
    
    [HttpGet]
    [Route("download")]
    public async Task<IActionResult> DownloadFile([FromQuery] string filePath)
    {
        // Vorbereitungen zum download einer Datei
        return null;
    }
    
    // TODO: Wie mache ich das mit dem löschen von Dateien?
}

