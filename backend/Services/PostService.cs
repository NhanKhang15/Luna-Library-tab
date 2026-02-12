using Backend.Data;
using Backend.DTOs;
using Backend.Enums;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class PostService : IPostService
{
    private readonly AppDbContext _context;

    public PostService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PostListResponseDto> GetPostsAsync(
        string? q,
        string? sort,
        int page,
        int pageSize,
        bool? premium,
        string? tagName,
        int? userId)
    {
        // Validate and clamp pageSize
        pageSize = Math.Clamp(pageSize, 1, 50);
        page = Math.Max(1, page);

        // Start with published posts only
        var query = _context.Posts
            .Include(p => p.Expert)
            .Include(p => p.Stats)
            .Include(p => p.PostTags)
                .ThenInclude(pt => pt.Tag)
            .Where(p => p.Status == "published")
            .AsQueryable();

        // Search filter (title and summary)
        if (!string.IsNullOrWhiteSpace(q))
        {
            var searchTerm = q.Trim().ToLower();
            query = query.Where(p =>
                p.Title.ToLower().Contains(searchTerm) ||
                (p.Summary != null && p.Summary.ToLower().Contains(searchTerm)));
        }

        // Premium filter
        if (premium.HasValue)
        {
            query = query.Where(p => p.IsPremium == premium.Value);
        }

        // Tag filter by name
        if (!string.IsNullOrWhiteSpace(tagName))
        {
            query = query.Where(p => p.PostTags.Any(pt => pt.Tag.Name == tagName));
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
            SortOption.NEWEST => query.OrderByDescending(p => p.PublishedAt),
            SortOption.MOST_VIEWED => query.OrderByDescending(p => p.Stats != null ? p.Stats.ViewCount : 0)
                                           .ThenByDescending(p => p.PublishedAt),
            SortOption.MOST_LIKED => query.OrderByDescending(p => p.Stats != null ? p.Stats.LikeCount : 0)
                                          .ThenByDescending(p => p.PublishedAt),
            _ => query.OrderByDescending(p => (p.Stats != null ? p.Stats.LikeCount + p.Stats.ViewCount : 0))
                      .ThenByDescending(p => p.PublishedAt) // TRENDING
        };

        // Pagination
        var posts = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        // Get viewer state if userId provided (batch query to avoid N+1)
        var likedPostIds = new HashSet<int>();

        if (userId.HasValue && posts.Any())
        {
            var postIds = posts.Select(p => p.PostId).ToList();

            likedPostIds = (await _context.PostLikes
                .Where(l => l.UserId == userId.Value && postIds.Contains(l.PostId))
                .Select(l => l.PostId)
                .ToListAsync()).ToHashSet();
        }

        // Map to DTOs
        var items = posts.Select(p => new PostListItemDto
        {
            Id = p.PostId,
            Title = p.Title,
            ThumbnailUrl = p.ThumbnailUrl,
            ViewCount = p.Stats?.ViewCount ?? 0,
            LikeCount = p.Stats?.LikeCount ?? 0,
            PublishedAt = p.PublishedAt,
            IsPremium = p.IsPremium,
            Expert = p.Expert != null ? new ExpertDto
            {
                ExpertId = p.Expert.ExpertId,
                FullName = p.Expert.FullName,
                Specialization = p.Expert.Specialization
            } : null,
            ViewerState = new ViewerStateDto
            {
                Liked = likedPostIds.Contains(p.PostId)
            }
        }).ToList();

        return new PostListResponseDto
        {
            Page = page,
            PageSize = pageSize,
            Total = total,
            Items = items
        };
    }

    public async Task<PostDetailDto?> GetPostDetailAsync(int id, int? userId)
    {
        // Check if post exists and is published
        var post = await _context.Posts
            .Include(p => p.Expert)
            .Include(p => p.Stats)
            .Include(p => p.PostCategories)
                .ThenInclude(pc => pc.Category)
            .FirstOrDefaultAsync(p => p.PostId == id && p.Status == "published");

        if (post == null)
        {
            return null;
        }

        // Atomic view count increment
        await _context.PostStats
            .Where(s => s.PostId == id)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(s => s.ViewCount, s => s.ViewCount + 1)
                .SetProperty(s => s.UpdatedAt, DateTime.UtcNow));

        // Refresh stats after increment
        var updatedStats = await _context.PostStats
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.PostId == id);

        // Get viewer state
        var liked = false;

        if (userId.HasValue)
        {
            liked = await _context.PostLikes
                .AnyAsync(l => l.UserId == userId.Value && l.PostId == id);
        }

        // Get ALL category names
        var categoryNames = post.PostCategories
            .Where(pc => pc.Category != null)
            .Select(pc => pc.Category!.Name)
            .ToList();

        return new PostDetailDto
        {
            Id = post.PostId,
            Title = post.Title,
            ThumbnailUrl = post.ThumbnailUrl,
            Categories = categoryNames,
            PublishedAt = post.PublishedAt,
            ViewCount = updatedStats?.ViewCount ?? 1,
            LikeCount = updatedStats?.LikeCount ?? 0,
            IsPremium = post.IsPremium,
            Expert = post.Expert != null ? new ExpertDto
            {
                ExpertId = post.Expert.ExpertId,
                FullName = post.Expert.FullName,
                Specialization = post.Expert.Specialization
            } : null,
            Content = new PostContentDto
            {
                Summary = post.Summary,
                Body = post.Content
            },
            ViewerState = new ViewerStateDto
            {
                Liked = liked
            }
        };
    }

    public async Task<LikeToggleResponseDto> ToggleLikeAsync(int postId, int userId)
    {
        // Check if post exists
        var postExists = await _context.Posts.AnyAsync(p => p.PostId == postId);
        if (!postExists)
        {
            throw new KeyNotFoundException($"Post with id {postId} not found");
        }

        // Check current like status
        var existingLike = await _context.PostLikes
            .FirstOrDefaultAsync(l => l.UserId == userId && l.PostId == postId);

        bool liked;
        
        if (existingLike != null)
        {
            // Unlike: Remove the like
            _context.PostLikes.Remove(existingLike);
            
            // Decrement like count atomically
            await _context.PostStats
                .Where(s => s.PostId == postId)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(s => s.LikeCount, s => s.LikeCount > 0 ? s.LikeCount - 1 : 0)
                    .SetProperty(s => s.UpdatedAt, DateTime.UtcNow));
            
            liked = false;
        }
        else
        {
            // Like: Add the like
            var newLike = new Entities.PostLike
            {
                UserId = userId,
                PostId = postId,
                CreatedAt = DateTime.UtcNow
            };
            _context.PostLikes.Add(newLike);
            
            // Increment like count atomically
            await _context.PostStats
                .Where(s => s.PostId == postId)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(s => s.LikeCount, s => s.LikeCount + 1)
                    .SetProperty(s => s.UpdatedAt, DateTime.UtcNow));
            
            liked = true;
        }

        await _context.SaveChangesAsync();

        // Get updated like count
        var stats = await _context.PostStats
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.PostId == postId);

        return new LikeToggleResponseDto
        {
            Liked = liked,
            LikeCount = stats?.LikeCount ?? 0
        };
    }

    public async Task<RelatedContentResponseDto> GetRelatedContentAsync(int postId, int page, int pageSize)
    {
        pageSize = Math.Clamp(pageSize, 1, 20);
        page = Math.Max(1, page);

        // Get category IDs from the current post
        var categoryIds = await _context.PostCategories
            .Where(pc => pc.PostId == postId)
            .Select(pc => pc.CategoryId)
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

        // Get related posts (same categories, exclude current post)
        var relatedPosts = await _context.Posts
            .Include(p => p.PostCategories)
            .Where(p => p.Status == "published" && p.PostId != postId)
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

        // Get related videos (same categories)
        var relatedVideos = await _context.Videos
            .Include(v => v.VideoCategories)
            .Where(v => v.Status == "published")
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
}
