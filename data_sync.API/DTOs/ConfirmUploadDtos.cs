namespace data_sync.API.DTOs;

public class ConfirmUploadResponseDto
{
    public int SuccessCount { get; set; }
    public int ErrorCount { get; set; }
    public List<ValidationErrorDto> Errors { get; set; }
}

public class ValidationErrorDto
{
    public string FileName { get; set; }
    public string ErrorMessage { get; set; }
}