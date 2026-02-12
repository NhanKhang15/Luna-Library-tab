namespace Backend.DTOs;

public class VideoListItemDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string Duration { get; set; } = "0:00";  // Formatted MM:SS
    public long ViewCount { get; set; }
    public long LikeCount { get; set; }
    public DateTime? PublishedAt { get; set; }
    public bool IsPremium { get; set; }
    public bool IsShort { get; set; }
    public ExpertDto? Expert { get; set; }
    public ViewerStateDto ViewerState { get; set; } = new();
}

public class VideoListResponseDto
{
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public List<VideoListItemDto> Items { get; set; } = new();
}
