using Microsoft.AspNetCore.Mvc;
using data_sync.API.DTOs;
using data_sync.API.Services;
using Mysqlx.Crud;

namespace data_sync.API.Controllers;

// TODO: Wie mache ich das mit dem löschen von Dateien?

// TODO: Metadaten in der DB des Clients speichern (z.B. Dateigröße, Hash-Wert, Änderungsdatum). Das soll beim
//  Upload passieren.

[ApiController]
[Route("api/[controller]")]
public class SyncController : ControllerBase
{
    private readonly GetFilesToSyncService _filesToSyncService;
    private readonly UpdateMetadataService _updateMetadataService;
    private readonly IWebHostEnvironment _envirement;
    
    /// <summary>
    /// Konstruktor für SyncController, der GetFilesToSyncService injiziert.
    /// </summary>
    /// <param name="filesToSyncService"></param>
    public SyncController(GetFilesToSyncService filesToSyncService, UpdateMetadataService updateMetadataService, IWebHostEnvironment envirement)
    {
        _filesToSyncService = filesToSyncService;
        _updateMetadataService = updateMetadataService;
        _envirement = envirement;
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
    /// <param name="files">Die Datei(en) die übertragen werden</param>
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
    
    /// <summary>
    /// Nimmt nach dem Upload im Format des Manifest's die Metadaten entgegen und validiert diese.
    /// Erst wenn die Validierung erfolgreich ist, werden die Metadaten in der DB aktualisiert.
    /// <b>Wichtig:</b> Die Liste an Metadaten muss exakt der Liste der hochgeladenen Dateien entsprechen.
    /// </summary>
    /// <param name="metadata"></param>
    /// <returns></returns>
    [HttpPost("confirm-upload")]
    public async Task<IActionResult> ConfirmUpload([FromBody] List<ManifestEntryDto> metadataList)
    {
        List <ValidationErrorDto> validationErrors = new List <ValidationErrorDto>();
        int successCount = 0;
        
        foreach (var metadata in metadataList)
        {
            string fileName = Path.GetFileName(metadata.FilePath);
            string filePath = Path.Combine("uploads", fileName);

            // Validierung: Datei existiert?
            if (!System.IO.File.Exists(filePath))
            {
                validationErrors.Add(new ValidationErrorDto {FileName = fileName, ErrorMessage = "Datei auf den Server nicht gefunden."});
                continue;
            }

            // Validierung: Hash vergleichen (Client vs. Server)
            string serverHash = UtilsService.CalculateFileHash(filePath);
            if (serverHash != metadata.Hashvalue)
            {
                validationErrors.Add(new ValidationErrorDto {FileName = fileName, ErrorMessage = "Hashwert stimmt nicht überein."});
                continue;
            }

            // Validierung: Dateigröße prüfen
            var fileInfo = new FileInfo(filePath);
            if (fileInfo.Length != metadata.FileSize)
            {
                validationErrors.Add(new ValidationErrorDto {FileName = fileName, ErrorMessage = "Dateigröße stimmt nicht überein."});
                continue;
            }
            
            // Erst jetzt: Metadaten aktualisieren
            await _updateMetadataService.UpdateMetadataAsync(new ManifestEntryDto
            {
                FilePath = metadata.FilePath,
                FileName = metadata.FileName,
                FileSize = fileInfo.Length,
                Hashvalue = serverHash,
                CreatedAt = metadata.CreatedAt,
                LastModified = metadata.LastModified,
                FileState = metadata.FileState
            });

            successCount++;
        }
        return Ok(new ConfirmUploadResponseDto
        {
            SuccessCount = successCount,
            ErrorCount = validationErrors.Count,
            Errors = validationErrors
        });
    }

    // TODO: Eine Base64 kodierte JSON Datei wäre auch eine Möglichkeit, Dateien zu übertragen. Damit könnte man
    //  mehrere Dateien in einem Request übertragen.
    /// <summary>
    /// Download einer Datei anhand des Dateipfads des Servers. Der Pfad wird als Query-Parameter übergeben.
    /// Den Serverdateipfad erhält man als Response beim API Call "Manifest".
    /// </summary>
    /// <param name="fileName"></param>
    /// <returns></returns>
    [HttpGet("download")]
    public async Task<IActionResult> DownloadFile([FromQuery] string filePath)
    {
        string cleanFilePath = filePath.TrimStart('/', '\\');
        string fullPath = Path.Combine(_envirement.ContentRootPath, "uploads", cleanFilePath); // Pfad zur Datei im Upload-Verzeichnis

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

        string contentType = "application/octet-stream"; // Allgemeiner MIME-Typ für Binärdateien
        return File(memory, contentType, fullPath); // Gibt die Datei als Download zurück
    }

    [HttpGet("confirm-download")]
    public async Task<IActionResult> ConfirmDownload([FromQuery] string filePath)
    {
        var responseMetadata = _updateMetadataService.GetMetadataAsync();

        if (responseMetadata == null)
        {
            return NotFound("Metadata not found.");
        }
        else
        {
            return Ok(responseMetadata);
        }
    }
}

