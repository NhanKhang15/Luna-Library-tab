using Backend.DTOs;

namespace Backend.Services;

public interface IVideoService
{
    Task<VideoListResponseDto> GetVideosAsync(
        string? q,
        string? sort,
        int page,
        int pageSize,
        bool? premium,
        bool? isShort,
        string? tagName,
        int? userId);

    Task<VideoDetailDto?> GetVideoDetailAsync(int id, int? userId);

    Task<RelatedContentResponseDto> GetRelatedContentAsync(int videoId, int page, int pageSize);

    Task<LikeToggleResponseDto> ToggleLikeAsync(int videoId, int userId);
}

