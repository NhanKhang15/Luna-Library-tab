namespace Backend.DTOs;

public class SearchResultDto
{
    public int Id { get; set; }
    public string Type { get; set; } = string.Empty; // "post" or "video"
    public string Title { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string? Duration { get; set; } // Only for videos
    public long ViewCount { get; set; }
    public long LikeCount { get; set; }
    public DateTime? PublishedAt { get; set; }
}

public class SearchResponseDto
{
    public string Query { get; set; } = string.Empty;
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public List<SearchResultDto> Items { get; set; } = new();
}
