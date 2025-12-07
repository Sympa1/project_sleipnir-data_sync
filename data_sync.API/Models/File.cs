namespace data_sync.API.Models;

public class File
{
    public int FileId { get; set; }
    public string Path { get; set; } = string.Empty;
    public long Size { get; set; }
    public DateTime? ModificationTime { get; set; }
    public DateTime CreatedAt { get; set; }
    public string Hash { get; set; } = string.Empty;
    public FileState State { get; set; } = FileState.Modified;
    public DateTime? UpdatedAt { get; set; }
    
    // Navigation Property
    public ICollection<SyncEvent> SyncEvents { get; set; } = new List<SyncEvent>();
}