using data_sync.API.DTOs;

namespace data_sync.API.Services;

public class UpdateMetadataService
{
    // Ich habe den Pfad vom Client (inkl. Dateiname)
    // Ich habe die Datei
    
    // Ich muss den Namen extrahieren
    // Ich muss vom Client das Änderungsdatum bekommen
    // Ich muss die Dateigröße ermitteln
    // Ich muss den Hashwert der Datei ermitteln
    // Ich muss vom Client den state der Datei bekommen
    // Ich muss vom CLient den Erstellzeitpunkt der Datei bekommen
    private readonly MariaDbService _mariaDbService;
    public UpdateMetadataService(MariaDbService mariaDbService)
    {
        _mariaDbService = mariaDbService;
    }
    public async Task UpdateMetadataAsync(ManifestEntryDto metaData)
    {
        await using (var connection = await _mariaDbService.OpenConnectionAsync())
        {
            if (connection != null)
            {
                await using (var dbCommand = connection.CreateCommand())
                {
                    // Da der Pfad eindeutig ist, nutze ich ON DUPLICATE KEY UPDATE. Sollte der Eintrag schon existieren, werden die Werte aktualisiert.
                    dbCommand.CommandText = @"
                        INSERT INTO SyncFiles (file_name, file_path, file_size, last_modified, hash_value, file_state)
                        VALUES (@fileName, @filePath, @fileSize, @lastModified, @hashValue, @fileState)
                        ON DUPLICATE KEY UPDATE
                            file_size = @fileSize,
                            last_modified = @lastModified,
                            hash_value = @hashValue,
                            file_state = @fileState;
                    ";

                    dbCommand.Parameters.AddWithValue("@fileName", metaData.FileName);
                    dbCommand.Parameters.AddWithValue("@filePath", metaData.FilePath);
                    dbCommand.Parameters.AddWithValue("@fileSize", metaData.FileSize);
                    dbCommand.Parameters.AddWithValue("@lastModified", metaData.LastModified);
                    dbCommand.Parameters.AddWithValue("@hashValue", metaData.Hashvalue);
                    dbCommand.Parameters.AddWithValue("@fileState", metaData.FileState.ToString());

                    await dbCommand.ExecuteNonQueryAsync();
                }
            }
        }
    }

    public async Task<ConfirmDownloadResponseDto> GetMetadataAsync()
    {
        await using (var connection = await _mariaDbService.OpenConnectionAsync())
        {
            if (connection != null)
            {
                await using (var dbCommand = connection.CreateCommand())
                {
                    dbCommand.CommandText = "SELECT file_name, file_path, file_size, last_modified, hash_value, file_state FROM SyncFiles;";

                    await using (var reader = await dbCommand.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            // Die Zahlen in den Klammern stehen für die Spaltenindizes im SELECT-Statement
                            var response = new ConfirmDownloadResponseDto
                            {
                                FileName = reader.GetString(0),
                                FilePath = reader.GetString(1),
                                FileSize = reader.GetInt64(2),
                                LastModified = reader.GetDateTime(3),
                                Hashvalue = reader.GetString(4),
                                FileState = Enum.Parse<FileChangeState>(reader.GetString(5))
                            };
                            
                            return response;
                        }
                    }
                }
            }
        }
        // Das "!" verhindert eine Warnung bzgl. möglicher Null-Werte
        return null!;
    }
}