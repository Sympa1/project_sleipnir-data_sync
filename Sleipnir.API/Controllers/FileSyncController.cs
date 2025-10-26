using Microsoft.AspNetCore.Mvc;
using Sleipnir.API.DTOs;
using Sleipnir.API.Services;

namespace Sleipnir.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FileSyncController : Controller
{
    // TODO: Per Konstruktor eine Instanz von GetFilesToSyncService injizieren?
    //  ist die dann immer noch für nur einen Request?
    private readonly GetFilesToSyncService _filesToSyncService;
    
    /// <summary>
    /// Konstruktor für FileSyncController, der GetFilesToSyncService injiziert.
    /// </summary>
    /// <param name="filesToSyncService"></param>
    public FileSyncController(GetFilesToSyncService filesToSyncService)
    {
        _filesToSyncService = filesToSyncService;
    }
    
    
    [HttpPost]
    public async Task<IActionResult> PostManifestByClient([FromBody] List<ManifestDto> manifests)
    {
        if (manifests == null || manifests.Count == 0)
            return BadRequest("Manifest missing or invalid.");
        
        // TODO: Implementierung Methoden zum Abgleich, welche Dateien geupdated werden müssen.
        var filesToSync = _filesToSyncService.GetFilesToSync(manifests);
        
        // TODO: Ok richtig? Ich will ja dem Client eine Liste der zu syncenden Dateien zurückgeben.
        return Ok(filesToSync);
    }
}