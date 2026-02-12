using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

[ApiController]
[Route("api/v1/videos")]
public class VideosController : ControllerBase
{
    private readonly IVideoService _videoService;

    public VideosController(IVideoService videoService)
    {
        _videoService = videoService;
    }

    /// <summary>
    /// List Videos with search, sort, and pagination
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(VideoListResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<VideoListResponseDto>> GetVideos(
        [FromQuery] string? q,
        [FromQuery] string? sort,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] bool? premium = null,
        [FromQuery] bool? isShort = null,
        [FromQuery] string? tag = null)
    {
        try
        {
            var userId = GetUserId();
            var result = await _videoService.GetVideosAsync(q, sort, page, pageSize, premium, isShort, tag, userId);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get Video Detail with atomic view count increment
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(VideoDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<VideoDetailDto>> GetVideoDetail(int id)
    {
        var userId = GetUserId();
        var result = await _videoService.GetVideoDetailAsync(id, userId);

        if (result == null)
        {
            return NotFound(new { error = $"Video with id {id} not found" });
        }

        return Ok(result);
    }

    /// <summary>
    /// Get related content (posts and videos with same categories)
    /// </summary>
    [HttpGet("{id:int}/related")]
    [ProducesResponseType(typeof(RelatedContentResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<RelatedContentResponseDto>> GetRelatedContent(
        int id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {
        // Note: Don't use GetVideoDetailAsync here - it increments view count!
        // Just get related content directly (it handles non-existent video gracefully)
        var result = await _videoService.GetRelatedContentAsync(id, page, pageSize);
        return Ok(result);
    }

    /// <summary>
    /// Toggle like on a video (like/unlike)
    /// Requires X-User-Id header
    /// </summary>
    [HttpPost("{id:int}/like")]
    [ProducesResponseType(typeof(LikeToggleResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<LikeToggleResponseDto>> ToggleLike(int id)
    {
        var userId = GetUserId();
        
        if (!userId.HasValue)
        {
            return Unauthorized(new { error = "X-User-Id header is required" });
        }

        try
        {
            var result = await _videoService.ToggleLikeAsync(id, userId.Value);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Parse X-User-Id header for simulated authentication
    /// </summary>
    private int? GetUserId()
    {
        if (Request.Headers.TryGetValue("X-User-Id", out var value) &&
            int.TryParse(value.FirstOrDefault(), out var userId))
        {
            return userId;
        }
        return null;
    }
}

