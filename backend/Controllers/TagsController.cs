using Backend.Data;
using Backend.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers;

[ApiController]
[Route("api/v1/tags")]
public class TagsController : ControllerBase
{
    private readonly AppDbContext _context;

    public TagsController(AppDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get all available tags
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(TagListResponseDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<TagListResponseDto>> GetTags()
    {
        var tags = await _context.Tags
            .OrderBy(t => t.Name)
            .Select(t => new TagDto
            {
                Id = t.TagId,
                Name = t.Name,
                Slug = t.Slug
            })
            .ToListAsync();

        return Ok(new TagListResponseDto { Items = tags });
    }
}
