using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

[Table("PostStats")]
public class PostStats
{
    [Key]
    [Column("post_id")]
    public int PostId { get; set; }

    [Column("view_count")]
    public long ViewCount { get; set; }

    [Column("like_count")]
    public long LikeCount { get; set; }

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; }

    // Navigation
    [ForeignKey("PostId")]
    public Post Post { get; set; } = null!;
}
