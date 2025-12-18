using Microsoft.AspNetCore.Mvc;
using data_sync.API.DTOs;
using data_sync.API.Services;

namespace data_sync.API.Controllers;

// TODO: Wie mache ich das mit dem löschen von Dateien?

// TODO: Metadaten in der DB des Clients speichern (z.B. Dateigröße, Hash-Wert, Änderungsdatum). Das soll beim
//  Upload passieren.

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
    
    /// <summary>
    /// Gibt dem Client die Liste der Dateien zurück, mit dem Status/Zustand der betreffenden Dateien.
    /// </summary>
    /// <param name="manifests"></param>
    /// <returns></returns>
    [HttpPost("manifest")]
    public async Task<IActionResult> PostManifestByClient([FromBody] List<ManifestEntryDto> manifests)
    {
        if (manifests.Count == 0)
            return BadRequest("Manifest missing or invalid.");
        
        var filesToSync = await _filesToSyncService.GetFilesToSync(manifests); // Ermittle Dateien, die synchronisiert werden müssen
        
        return Ok(filesToSync);  // Gib dem Client die Liste der zu synchronisierenden Dateien zurück
    }
    
    /// <summary>
    /// files und basePath sind die Keywords. basePath wird als Query-Parameter übergeben.
    /// Es können mehrere Dateien gleichzeitig hochgeladen werden, aber sie müssen im selben Verzeichnis liegen.
    /// </summary>
    /// <param name="files">Die Datei(en) die Übertragen werden</param>
    /// <param name="basePath">Der Dateipfad für die Datei(en)</param>
    /// <returns></returns>
    [HttpPost("upload")]
    public async Task<IActionResult> UploadFile(List<IFormFile> files, [FromQuery] string basePath = "")
    {
        if (files == null || files.Count == 0)
        {
            return BadRequest("No files uploaded.");
        }
        
        // TODO: Die Verzeichnisstruktur muss später noch gespiegelt werden.
        // Erstellen des Upload-Verzeichnisses, falls es nicht existiert
        var uploadPath = Path.Combine("uploads", basePath);
        if (!Directory.Exists(uploadPath))
        {
            Directory.CreateDirectory(uploadPath);
        }

        //long size = files.Sum(f => f.Length); // Gesamtgröße aller hochgeladenen Dateien in Bytes
        string size = $"{files.Sum(f => f.Length)} Bytes";

        foreach (var file in files)
        {
            if (file.Length > 0) // Ermittelt die Dateigröße in Bytes
            {
                var fileName = Path.GetFileName(file.FileName); // Extrahiert den Dateinamen
                var fullPath = Path.Combine(uploadPath, fileName);
                
                using (var stream = System.IO.File.Create(Path.Combine(fullPath))) // Erstellt einen Dateistream zum Speichern der Datei
                {
                    await file.CopyToAsync(stream); // Kopiert den Inhalt der hochgeladenen Datei in den Dateistream
                }
            }
        }
        return Ok(new { count = files.Count, size }); // Gibt die Anzahl der hochgeladenen Dateien und deren Gesamtgröße als anonymes Objekt zurück
    }

    // TODO: Eine Base64 kodierte JSON Datei wäre auch eine Möglichkeit, Dateien zu übertragen. Damit könnte man
    //  mehrere Dateien in einem Request übertragen.
    /// <summary>
    /// Download einer Datei anhand des Dateipfads des Servers. Der Pfad wird als Query-Parameter übergeben.
    /// Den Serverdateipfad erält man als Response beim API Call "Manifest".
    /// </summary>
    /// <param name="fileName"></param>
    /// <returns></returns>
    [HttpGet("download")]
    public async Task<IActionResult> DownloadFile([FromQuery] string filePath)
    {
        string fullPath = Path.Combine("uploads", filePath); // Pfad zur Datei im Upload-Verzeichnis

        if (!System.IO.File.Exists(fullPath))
        {
            return NotFound("File not found.");
        }

        var memory = new MemoryStream();
        using (var stream = new FileStream(fullPath, FileMode.Open))
        {
            await stream.CopyToAsync(memory); // Kopiert den Inhalt der Datei in den MemoryStream
        }
        memory.Position = 0; // Setzt die Position des MemoryStreams auf den Anfang zurück

        var contentType = "application/octet-stream"; // Allgemeiner MIME-Typ für Binärdateien
        return File(memory, contentType, fullPath); // Gibt die Datei als Download zurück
    }
}

