namespace Backend.DTOs;

public class VideoDetailDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string VideoUrl { get; set; } = string.Empty;
    public string Duration { get; set; } = "0:00";  // Formatted MM:SS
    public int DurationSeconds { get; set; }
    public List<string> Categories { get; set; } = new();
    public DateTime? PublishedAt { get; set; }
    public long ViewCount { get; set; }
    public long LikeCount { get; set; }
    public bool IsPremium { get; set; }
    public bool IsShort { get; set; }
    public ExpertDto? Expert { get; set; }
    public ViewerStateDto ViewerState { get; set; } = new();
}
