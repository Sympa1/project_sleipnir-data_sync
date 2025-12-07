namespace data_sync.API.Models;

public class SyncEvent
{
    public int LogId { get; set; }
    public int FileId { get; set; }
    public SyncAction Action { get; set; }
    public DateTime Timestamp { get; set; }
    public string Details { get; set; } = string.Empty;

    // Foreign Key Navigation
    public SyncFile File { get; set; } = null!;
}