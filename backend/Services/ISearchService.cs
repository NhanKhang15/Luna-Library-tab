using Backend.DTOs;

namespace Backend.Services;

public interface ISearchService
{
    Task<SearchResponseDto> SearchAsync(string query, int page, int pageSize);
}
