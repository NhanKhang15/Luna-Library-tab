namespace Backend.DTOs;

public class PostContentDto
{
    public string? Summary { get; set; }
    public string? Body { get; set; }
}

public class PostDetailDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public List<string> Categories { get; set; } = new();  // All categories from ContentCategories.name
    public DateTime? PublishedAt { get; set; }
    public long ViewCount { get; set; }
    public long LikeCount { get; set; }
    public bool IsPremium { get; set; }
    public ExpertDto? Expert { get; set; }
    public PostContentDto Content { get; set; } = new();
    public ViewerStateDto ViewerState { get; set; } = new();
}
