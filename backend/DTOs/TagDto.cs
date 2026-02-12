namespace Backend.DTOs;

/// <summary>
/// DTO for Tag in API response
/// </summary>
public class TagDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
}

/// <summary>
/// Response DTO for list of tags
/// </summary>
public class TagListResponseDto
{
    public List<TagDto> Items { get; set; } = new();
}
