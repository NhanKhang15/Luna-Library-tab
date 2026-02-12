using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

[Table("VideoStats")]
public class VideoStats
{
    [Key]
    [Column("video_id")]
    public int VideoId { get; set; }

    [Column("view_count")]
    public long ViewCount { get; set; }

    [Column("like_count")]
    public long LikeCount { get; set; }

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; }

    // Navigation
    [ForeignKey("VideoId")]
    public Video Video { get; set; } = null!;
}
