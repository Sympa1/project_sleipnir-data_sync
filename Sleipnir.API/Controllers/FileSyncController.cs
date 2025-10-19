using Microsoft.AspNetCore.Mvc;
using Sleipnir.API.DTOs;

namespace Sleipnir.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FileSyncController : Controller
{
    [HttpPost]
    public async Task<IActionResult> PostManifestByClient([FromBody] List<ManifestDto> manifests)
    {
        if (manifests == null || manifests.Count == 0)
            return BadRequest("Manifest missing or invalid.");
        //TODO: .env File hinzufügen.
        
        // TODO: Implementierung Methoden zum Abgleich, welche Dateien geupdated werden müssen.
        
        // TODO: Ok richtig? Ich will ja dem Client eine Liste der zu syncenden Dateien zurückgeben.
        return Ok(manifests.Count);
    }
}