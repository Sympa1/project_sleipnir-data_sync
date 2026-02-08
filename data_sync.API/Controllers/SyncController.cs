using Microsoft.AspNetCore.Mvc;
using data_sync.API.DTOs;
using data_sync.API.Models;
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
    private readonly SyncStateService _syncStateService;
    private readonly IWebHostEnvironment _envirement;
    
    /// <summary>
    /// Konstruktor für SyncController, der Services injiziert.
    /// </summary>
    public SyncController(
        GetFilesToSyncService filesToSyncService, 
        UpdateMetadataService updateMetadataService,
        SyncStateService syncStateService,
        IWebHostEnvironment envirement)
    {
        _filesToSyncService = filesToSyncService;
        _updateMetadataService = updateMetadataService;
        _syncStateService = syncStateService;
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
        // Leeres Manifest ist OK - neuer Client ohne Dateien
        if (manifests == null)
            return BadRequest("Manifest missing or invalid.");
        
        var filesToSync = await _filesToSyncService.GetFilesToSync(manifests);
        
        return Ok(filesToSync);
    }
    
    /// <summary>
    /// files und basePath sind die Keywords. basePath wird als Query-Parameter übergeben.
    /// Es können mehrere Dateien gleichzeitig hochgeladen werden, aber sie müssen im selben Verzeichnis liegen.
    /// </summary>
    /// <param name="files">Die Datei(en) die übertragen werden</param>
    /// <param name="basePath">Der Dateipfad für die Datei(en)</param>
    /// <returns></returns>
    [HttpPost("upload")]
    public async Task<IActionResult> UploadFile(IFormFile file, [FromQuery] string basePath = "")
    {
        if (file == null || file.Length == 0)
            return BadRequest("No file uploaded.");

        var uploadPath = Path.Combine("uploads", basePath);
        
        if (!Directory.Exists(uploadPath))
            Directory.CreateDirectory(uploadPath);

        var fileName = Path.GetFileName(file.FileName);
        var fullPath = Path.Combine(uploadPath, fileName);

        // Datei speichern
        using (var stream = System.IO.File.Create(fullPath))
        {
            await file.CopyToAsync(stream);
        }

        // Server berechnet Metadaten
        var hashValue = UtilsService.CalculateFileHash(fullPath);
        var fileInfo = new FileInfo(fullPath);

        // DB aktualisieren
        SyncFile metaData = new SyncFile
        {
            FileName = fileName,
            FilePath = fullPath,
            FileSize = fileInfo.Length,
            HashValue = hashValue,
            FileState = FileState.Modified
        };
        
        await _updateMetadataService.UpdateMetadataAsync(metaData);
      
        // LastSyncState aktualisieren nach erfolgreichem Upload
        var relativeFilePath = Path.Combine(basePath, fileName);
        await _syncStateService.UpdateSyncStateAsync(relativeFilePath, hashValue, fileInfo.Length);

        return Ok(new {
            status = "success",
            fileName = fileName,
            hash = hashValue
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
        string fullPath = Path.Combine(_envirement.ContentRootPath, "uploads", cleanFilePath);

        if (!System.IO.File.Exists(fullPath))
        {
            return NotFound("File not found.");
        }

        var memory = new MemoryStream();
        using (var stream = new FileStream(fullPath, FileMode.Open))
        {
            await stream.CopyToAsync(memory);
        }
        memory.Position = 0;

        // LastSyncState aktualisieren nach erfolgreichem Download
        var hashValue = UtilsService.CalculateFileHash(fullPath);
        var fileInfo = new FileInfo(fullPath);
        await _syncStateService.UpdateSyncStateAsync(cleanFilePath, hashValue, fileInfo.Length);

        string contentType = "application/octet-stream";
        return File(memory, contentType, fullPath);
    }

    [HttpDelete("delete")]
    public async Task<IActionResult> DeleteFile([FromQuery] string filePath)
    {
        if (string.IsNullOrEmpty(filePath))
        {
            return BadRequest("File path is required.");
        }
        
        string cleanFilePath = filePath.TrimStart('/', '\\');
        string fullPath = Path.Combine(_envirement.ContentRootPath, "uploads", cleanFilePath); // Pfad zur Datei im Upload-Verzeichnis
        
        if (!System.IO.File.Exists(fullPath))
        {
            return NotFound("File not found.");
        }
        
        try
        {
            System.IO.File.Delete(fullPath); // Löscht die Datei vom Server
            
            // LastSyncState löschen (Datei ist beidseitig gelöscht)
            await _syncStateService.DeleteSyncStateAsync(cleanFilePath);
            
            // Optional: Auch SyncFiles aktualisieren
            // TODO: UpdateMetadataService sollte auch DeleteMetadata() haben
            
            return Ok(new { status = "success", message = "File deleted successfully." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Error deleting file: {ex.Message}");
        }
    }
}

