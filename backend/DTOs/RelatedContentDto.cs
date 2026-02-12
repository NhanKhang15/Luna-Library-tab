namespace Backend.DTOs;

/// <summary>
/// A single related content item (post or video)
/// </summary>
public class RelatedContentItemDto
{
    public int Id { get; set; }
    public string Type { get; set; } = string.Empty; // "post" or "video"
    public string Title { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
}

/// <summary>
/// Paginated response for related content
/// </summary>
public class RelatedContentResponseDto
{
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public List<RelatedContentItemDto> Items { get; set; } = new();
}
