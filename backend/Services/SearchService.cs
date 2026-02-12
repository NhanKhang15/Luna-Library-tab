using Backend.Data;
using Backend.DTOs;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class SearchService : ISearchService
{
    private readonly AppDbContext _context;

    public SearchService(AppDbContext context)
    {
        _context = context;
    }

    private static string FormatDuration(int seconds)
    {
        var ts = TimeSpan.FromSeconds(seconds);
        return ts.Hours > 0 
            ? $"{ts.Hours}:{ts.Minutes:D2}:{ts.Seconds:D2}" 
            : $"{ts.Minutes}:{ts.Seconds:D2}";
    }

    public async Task<SearchResponseDto> SearchAsync(string query, int page, int pageSize)
    {
        pageSize = Math.Clamp(pageSize, 1, 50);
        page = Math.Max(1, page);

        if (string.IsNullOrWhiteSpace(query))
        {
            return new SearchResponseDto
            {
                Query = query ?? "",
                Page = page,
                PageSize = pageSize,
                Total = 0,
                Items = new List<SearchResultDto>()
            };
        }

        var searchTerm = query.Trim().ToLower();

        // Search Posts by title
        var postsQuery = _context.Posts
            .Include(p => p.Stats)
            .Where(p => p.Status == "published")
            .Where(p => p.Title.ToLower().Contains(searchTerm))
            .Select(p => new SearchResultDto
            {
                Id = p.PostId,
                Type = "post",
                Title = p.Title,
                ThumbnailUrl = p.ThumbnailUrl,
                Duration = null,
                ViewCount = p.Stats != null ? p.Stats.ViewCount : 0,
                LikeCount = p.Stats != null ? p.Stats.LikeCount : 0,
                PublishedAt = p.PublishedAt
            });

        // Search Videos by title
        var videosQuery = _context.Videos
            .Include(v => v.Stats)
            .Where(v => v.Status == "published")
            .Where(v => v.Title.ToLower().Contains(searchTerm))
            .Select(v => new SearchResultDto
            {
                Id = v.VideoId,
                Type = "video",
                Title = v.Title,
                ThumbnailUrl = v.ThumbnailUrl,
                Duration = FormatDuration(v.DurationSeconds),
                ViewCount = v.Stats != null ? v.Stats.ViewCount : 0,
                LikeCount = v.Stats != null ? v.Stats.LikeCount : 0,
                PublishedAt = v.PublishedAt
            });

        // Combine both queries
        var posts = await postsQuery.ToListAsync();
        var videos = await videosQuery.ToListAsync();

        var allResults = posts.Concat(videos)
            .OrderByDescending(r => r.PublishedAt)
            .ToList();

        var total = allResults.Count;
        var pagedItems = allResults
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return new SearchResponseDto
        {
            Query = query,
            Page = page,
            PageSize = pageSize,
            Total = total,
            Items = pagedItems
        };
    }
}
