namespace Backend.DTOs;

/// Response from toggling like
public class LikeToggleResponseDto
{
    public bool Liked { get; set; }
    public long LikeCount { get; set; }
}
