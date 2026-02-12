using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Backend.Entities;

[Table("VideoLikes")]
[PrimaryKey(nameof(UserId), nameof(VideoId))]
public class VideoLike
{
    [Column("user_id")]
    public int UserId { get; set; }

    [Column("video_id")]
    public int VideoId { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }

    // Navigation
    [ForeignKey("VideoId")]
    public Video Video { get; set; } = null!;
}
