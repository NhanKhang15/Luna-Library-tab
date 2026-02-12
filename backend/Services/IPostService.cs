using Backend.DTOs;

namespace Backend.Services;

public interface IPostService
{
    Task<PostListResponseDto> GetPostsAsync(
        string? q,
        string? sort,
        int page,
        int pageSize,
        bool? premium,
        string? tagName,
        int? userId);

    Task<PostDetailDto?> GetPostDetailAsync(int id, int? userId);

    Task<LikeToggleResponseDto> ToggleLikeAsync(int postId, int userId);

    Task<RelatedContentResponseDto> GetRelatedContentAsync(int postId, int page, int pageSize);
}
