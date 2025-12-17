using Microsoft.AspNetCore.Mvc;
using data_sync.API.DTOs;
using data_sync.API.Services;

namespace data_sync.API.Controllers;

// TODO: Übertragung der Dateidaten implementieren (Upload und Download)
// TODO: Wie mache ich das mit dem löschen von Dateien?
// TODO: Beim Download zum Client muss anschließend der Hashwert vom Client neu berechnet und in der ClientDB aktualisiert werden.

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
    
    [HttpPost("manifest")]
    public async Task<IActionResult> PostManifestByClient([FromBody] List<ManifestEntryDto> manifests)
    {
        if (manifests.Count == 0)
            return BadRequest("Manifest missing or invalid.");
        
        var filesToSync = await _filesToSyncService.GetFilesToSync(manifests); // Ermittle Dateien, die synchronisiert werden müssen
        
        return Ok(filesToSync);  // Gib dem Client die Liste der zu synchronisierenden Dateien zurück
    }

    /// <summary>
    /// Wichtig: Beim Client muss im Body das Formdata mit dem Key "files" verwendet werden.
    /// </summary>
    /// <param name="files"></param>
    /// <returns></returns>
    [HttpPost("upload")]
    public async Task<IActionResult> UploadFile(List<IFormFile> files)
    {
        if (files == null || files.Count == 0)
        {
            return BadRequest("No files uploaded.");
        }
        
        // TODO: Die Verzeichnisstruktur muss später noch gespiegelt werden.
        // Erstellen des Upload-Verzeichnisses, falls es nicht existiert
        var uploadPath = Path.Combine("Uploads");
        if (!Directory.Exists(uploadPath))
        {
            Directory.CreateDirectory(uploadPath);
        }
        
        long size = files.Sum(f => f.Length); // Gesamtgröße aller hochgeladenen Dateien in Bytes

        foreach (var file in files)
        {
            if (file.Length > 0) // Ermittelt die Dateigröße in Bytes
            {
                var fileName = Path.GetFileName(file.FileName); // Extrahiert den Dateinamen
                
                // TODO: Der Pfad muss später noch angepasst werden, um die Verzeichnisstruktur zu erhalten.
                using (var stream = System.IO.File.Create(Path.Combine("Uploads", fileName))) // Erstellt einen Dateistream zum Speichern der Datei
                {
                    await file.CopyToAsync(stream); // Kopiert den Inhalt der hochgeladenen Datei in den Dateistream
                }
            }
        }
        return Ok(new { count = files.Count, size }); // Gibt die Anzahl der hochgeladenen Dateien und deren Gesamtgröße als anonymes Objekt zurück
    }

    [HttpGet("download")]
    public async Task<IActionResult> DownloadFile([FromQuery] string fileName)
    {
        var filePath = Path.Combine("Uploads", fileName); // Pfad zur Datei im Upload-Verzeichnis

        if (!System.IO.File.Exists(filePath))
        {
            return NotFound("File not found.");
        }

        var memory = new MemoryStream();
        using (var stream = new FileStream(filePath, FileMode.Open))
        {
            await stream.CopyToAsync(memory); // Kopiert den Inhalt der Datei in den MemoryStream
        }
        memory.Position = 0; // Setzt die Position des MemoryStreams auf den Anfang zurück

        var contentType = "application/octet-stream"; // Allgemeiner MIME-Typ für Binärdateien
        return File(memory, contentType, fileName); // Gibt die Datei als Download zurück
    }
}

