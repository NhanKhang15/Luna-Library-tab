using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SearchController : ControllerBase
{
    private readonly ISearchService _searchService;

    public SearchController(ISearchService searchService)
    {
        _searchService = searchService;
    }

    /// <summary>
    /// Search Posts and Videos by title
    /// GET /api/search?q=keyword&page=1&pageSize=10
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<SearchResponseDto>> Search(
        [FromQuery] string? q,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        if (string.IsNullOrWhiteSpace(q))
        {
            return Ok(new SearchResponseDto
            {
                Query = "",
                Page = page,
                PageSize = pageSize,
                Total = 0,
                Items = new List<SearchResultDto>()
            });
        }

        var result = await _searchService.SearchAsync(q, page, pageSize);
        return Ok(result);
    }
}
