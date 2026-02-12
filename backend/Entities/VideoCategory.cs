using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Backend.Entities;

[Table("VideoCategories")]
[PrimaryKey(nameof(VideoId), nameof(CategoryId))]
public class VideoCategory
{
    [Column("video_id")]
    public int VideoId { get; set; }

    [Column("category_id")]
    public int CategoryId { get; set; }

    // Navigation
    [ForeignKey("VideoId")]
    public Video Video { get; set; } = null!;

    [ForeignKey("CategoryId")]
    public ContentCategory Category { get; set; } = null!;
}
