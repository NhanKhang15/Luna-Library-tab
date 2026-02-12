using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

[ApiController]
[Route("api/v1/posts")]
public class PostsController : ControllerBase
{
    private readonly IPostService _postService;

    public PostsController(IPostService postService)
    {
        _postService = postService;
    }

    /// <summary>
    /// List Foundation Posts with search, sort, and pagination
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(PostListResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PostListResponseDto>> GetPosts(
        [FromQuery] string? q,
        [FromQuery] string? sort,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] bool? premium = null,
        [FromQuery] string? tag = null)
    {
        try
        {
            var userId = GetUserId();
            var result = await _postService.GetPostsAsync(q, sort, page, pageSize, premium, tag, userId);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get Post Detail with atomic view count increment
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(PostDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PostDetailDto>> GetPostDetail(int id)
    {
        var userId = GetUserId();
        var result = await _postService.GetPostDetailAsync(id, userId);

        if (result == null)
        {
            return NotFound(new { error = $"Post with id {id} not found" });
        }

        return Ok(result);
    }

    /// <summary>
    /// Toggle like on a post (like/unlike)
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
            var result = await _postService.ToggleLikeAsync(id, userId.Value);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
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
        // Note: Don't use GetPostDetailAsync here - it increments view count!
        // Just get related content directly (it handles non-existent post gracefully)
        var result = await _postService.GetRelatedContentAsync(id, page, pageSize);
        return Ok(result);
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
