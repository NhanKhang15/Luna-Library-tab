namespace Backend.DTOs;

public class PostListItemDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public long ViewCount { get; set; }
    public long LikeCount { get; set; }
    public DateTime? PublishedAt { get; set; }
    public bool IsPremium { get; set; }
    public ExpertDto? Expert { get; set; }
    public ViewerStateDto ViewerState { get; set; } = new();
    // Note: category and suggestionKey not in database schema
}
