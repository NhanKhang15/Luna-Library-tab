namespace Backend.DTOs;

public class PostListResponseDto
{
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public List<PostListItemDto> Items { get; set; } = new();
}
