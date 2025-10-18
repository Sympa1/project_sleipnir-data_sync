using Microsoft.AspNetCore.Mvc;
using Sleipnir.API.DTOs;

namespace Sleipnir.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FileSyncController : Controller
{
    [HttpPost]
    public async Task<IActionResult> PostManifestByClient([FromBody] ManifestDto manifest)
    {
        if (manifest == null)
            return BadRequest("Manifest missing or invalid.");
        
        // TODO: Implementierung Methoden zum Agleich, welche Dateien geupdated werden müssen.
        
        // TODO: Ok richtig? Ich will ja dem CLient eine Liste der zu syncenden Dateien zurückgeben.
        return Ok();
    }
}