using Backend.Data;
using Backend.DTOs;
using Backend.Enums;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class VideoService : IVideoService
{
    private readonly AppDbContext _context;

    public VideoService(AppDbContext context)
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

    public async Task<VideoListResponseDto> GetVideosAsync(
        string? q,
        string? sort,
        int page,
        int pageSize,
        bool? premium,
        bool? isShort,
        string? tagName,
        int? userId)
    {
        // Validate and clamp pageSize
        pageSize = Math.Clamp(pageSize, 1, 50);
        page = Math.Max(1, page);

        // Start with published videos only
        var query = _context.Videos
            .Include(v => v.Expert)
            .Include(v => v.Stats)
            .Include(v => v.VideoTags)
                .ThenInclude(vt => vt.Tag)
            .Where(v => v.Status == "published")
            .AsQueryable();

        // Search filter (title and description)
        if (!string.IsNullOrWhiteSpace(q))
        {
            var searchTerm = q.Trim().ToLower();
            query = query.Where(v =>
                v.Title.ToLower().Contains(searchTerm) ||
                (v.Description != null && v.Description.ToLower().Contains(searchTerm)));
        }

        // Premium filter
        if (premium.HasValue)
        {
            query = query.Where(v => v.IsPremium == premium.Value);
        }

        // Short video filter
        if (isShort.HasValue)
        {
            query = query.Where(v => v.IsShort == isShort.Value);
        }

        // Tag filter by name
        if (!string.IsNullOrWhiteSpace(tagName))
        {
            query = query.Where(v => v.VideoTags.Any(vt => vt.Tag.Name == tagName));
        }

        // Get total count before pagination
        var total = await query.CountAsync();

        // Sorting
        var sortOption = SortOption.TRENDING;
        if (!string.IsNullOrWhiteSpace(sort))
        {
            if (!Enum.TryParse<SortOption>(sort, true, out sortOption))
            {
                throw new ArgumentException($"Invalid sort: {sort}. Valid values: TRENDING, NEWEST, MOST_VIEWED, MOST_LIKED");
            }
        }

        query = sortOption switch
        {
            SortOption.NEWEST => query.OrderByDescending(v => v.PublishedAt),
            SortOption.MOST_VIEWED => query.OrderByDescending(v => v.Stats != null ? v.Stats.ViewCount : 0)
                                           .ThenByDescending(v => v.PublishedAt),
            SortOption.MOST_LIKED => query.OrderByDescending(v => v.Stats != null ? v.Stats.LikeCount : 0)
                                          .ThenByDescending(v => v.PublishedAt),
            _ => query.OrderByDescending(v => (v.Stats != null ? v.Stats.LikeCount + v.Stats.ViewCount : 0))
                      .ThenByDescending(v => v.PublishedAt) // TRENDING
        };

        // Pagination
        var videos = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        // Get viewer state if userId provided (batch query to avoid N+1)
        var likedVideoIds = new HashSet<int>();

        if (userId.HasValue && videos.Any())
        {
            var videoIds = videos.Select(v => v.VideoId).ToList();

            likedVideoIds = (await _context.VideoLikes
                .Where(l => l.UserId == userId.Value && videoIds.Contains(l.VideoId))
                .Select(l => l.VideoId)
                .ToListAsync()).ToHashSet();
        }

        // Map to DTOs
        var items = videos.Select(v => new VideoListItemDto
        {
            Id = v.VideoId,
            Title = v.Title,
            ThumbnailUrl = v.ThumbnailUrl,
            Duration = FormatDuration(v.DurationSeconds),
            ViewCount = v.Stats?.ViewCount ?? 0,
            LikeCount = v.Stats?.LikeCount ?? 0,
            PublishedAt = v.PublishedAt,
            IsPremium = v.IsPremium,
            IsShort = v.IsShort,
            Expert = v.Expert != null ? new ExpertDto
            {
                ExpertId = v.Expert.ExpertId,
                FullName = v.Expert.FullName,
                Specialization = v.Expert.Specialization
            } : null,
            ViewerState = new ViewerStateDto
            {
                Liked = likedVideoIds.Contains(v.VideoId)
            }
        }).ToList();

        return new VideoListResponseDto
        {
            Page = page,
            PageSize = pageSize,
            Total = total,
            Items = items
        };
    }

    public async Task<VideoDetailDto?> GetVideoDetailAsync(int id, int? userId)
    {
        // Check if video exists and is published
        var video = await _context.Videos
            .Include(v => v.Expert)
            .Include(v => v.Stats)
            .Include(v => v.VideoCategories)
                .ThenInclude(vc => vc.Category)
            .FirstOrDefaultAsync(v => v.VideoId == id && v.Status == "published");

        if (video == null)
        {
            return null;
        }

        // Atomic view count increment
        await _context.VideoStats
            .Where(s => s.VideoId == id)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(s => s.ViewCount, s => s.ViewCount + 1)
                .SetProperty(s => s.UpdatedAt, DateTime.UtcNow));

        // Refresh stats after increment
        var updatedStats = await _context.VideoStats
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.VideoId == id);

        // Get viewer state
        var liked = false;

        if (userId.HasValue)
        {
            liked = await _context.VideoLikes
                .AnyAsync(l => l.UserId == userId.Value && l.VideoId == id);
        }

        // Get ALL category names
        var categoryNames = video.VideoCategories
            .Where(vc => vc.Category != null)
            .Select(vc => vc.Category!.Name)
            .ToList();

        return new VideoDetailDto
        {
            Id = video.VideoId,
            Title = video.Title,
            Description = video.Description,
            ThumbnailUrl = video.ThumbnailUrl,
            VideoUrl = video.VideoUrl,
            Duration = FormatDuration(video.DurationSeconds),
            DurationSeconds = video.DurationSeconds,
            Categories = categoryNames,
            PublishedAt = video.PublishedAt,
            ViewCount = updatedStats?.ViewCount ?? 1,
            LikeCount = updatedStats?.LikeCount ?? 0,
            IsPremium = video.IsPremium,
            IsShort = video.IsShort,
            Expert = video.Expert != null ? new ExpertDto
            {
                ExpertId = video.Expert.ExpertId,
                FullName = video.Expert.FullName,
                Specialization = video.Expert.Specialization
            } : null,
            ViewerState = new ViewerStateDto
            {
                Liked = liked
            }
        };
    }

    public async Task<RelatedContentResponseDto> GetRelatedContentAsync(int videoId, int page, int pageSize)
    {
        pageSize = Math.Clamp(pageSize, 1, 20);
        page = Math.Max(1, page);

        // Get category IDs from the current video
        var categoryIds = await _context.VideoCategories
            .Where(vc => vc.VideoId == videoId)
            .Select(vc => vc.CategoryId)
            .ToListAsync();

        if (!categoryIds.Any())
        {
            return new RelatedContentResponseDto
            {
                Page = page,
                PageSize = pageSize,
                Total = 0,
                Items = new List<RelatedContentItemDto>()
            };
        }

        // Get related posts (same categories)
        var relatedPosts = await _context.Posts
            .Include(p => p.PostCategories)
            .Where(p => p.Status == "published")
            .Where(p => p.PostCategories.Any(pc => categoryIds.Contains(pc.CategoryId)))
            .OrderByDescending(p => p.PublishedAt)
            .Select(p => new RelatedContentItemDto
            {
                Id = p.PostId,
                Type = "post",
                Title = p.Title,
                ThumbnailUrl = p.ThumbnailUrl
            })
            .ToListAsync();

        // Get related videos (same categories, exclude current video)
        var relatedVideos = await _context.Videos
            .Include(v => v.VideoCategories)
            .Where(v => v.Status == "published" && v.VideoId != videoId)
            .Where(v => v.VideoCategories.Any(vc => categoryIds.Contains(vc.CategoryId)))
            .OrderByDescending(v => v.PublishedAt)
            .Select(v => new RelatedContentItemDto
            {
                Id = v.VideoId,
                Type = "video",
                Title = v.Title,
                ThumbnailUrl = v.ThumbnailUrl
            })
            .ToListAsync();

        // Combine and paginate
        var allItems = relatedPosts.Concat(relatedVideos)
            .OrderBy(x => Guid.NewGuid()) // Shuffle for variety
            .ToList();

        var total = allItems.Count;
        var pagedItems = allItems
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return new RelatedContentResponseDto
        {
            Page = page,
            PageSize = pageSize,
            Total = total,
            Items = pagedItems
        };
    }

    public async Task<LikeToggleResponseDto> ToggleLikeAsync(int videoId, int userId)
    {
        // Check if video exists
        var videoExists = await _context.Videos.AnyAsync(v => v.VideoId == videoId && v.Status == "published");
        if (!videoExists)
        {
            throw new KeyNotFoundException($"Video with id {videoId} not found");
        }

        // Check current like status
        var existingLike = await _context.VideoLikes
            .FirstOrDefaultAsync(l => l.UserId == userId && l.VideoId == videoId);

        bool liked;
        
        if (existingLike != null)
        {
            // Unlike: Remove the like
            _context.VideoLikes.Remove(existingLike);
            
            // Decrement like count atomically
            await _context.VideoStats
                .Where(s => s.VideoId == videoId)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(s => s.LikeCount, s => s.LikeCount > 0 ? s.LikeCount - 1 : 0)
                    .SetProperty(s => s.UpdatedAt, DateTime.UtcNow));
            
            liked = false;
        }
        else
        {
            // Like: Add the like
            var newLike = new Entities.VideoLike
            {
                UserId = userId,
                VideoId = videoId,
                CreatedAt = DateTime.UtcNow
            };
            _context.VideoLikes.Add(newLike);
            
            // Increment like count atomically
            await _context.VideoStats
                .Where(s => s.VideoId == videoId)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(s => s.LikeCount, s => s.LikeCount + 1)
                    .SetProperty(s => s.UpdatedAt, DateTime.UtcNow));
            
            liked = true;
        }

        await _context.SaveChangesAsync();

        // Get updated like count
        var stats = await _context.VideoStats
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.VideoId == videoId);

        return new LikeToggleResponseDto
        {
            Liked = liked,
            LikeCount = stats?.LikeCount ?? 0
        };
    }
}

