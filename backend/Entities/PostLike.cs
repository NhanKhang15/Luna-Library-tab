using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Backend.Entities;

[Table("PostLikes")]
[PrimaryKey(nameof(UserId), nameof(PostId))]
public class PostLike
{
    [Column("user_id")]
    public int UserId { get; set; }

    [Column("post_id")]
    public int PostId { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }

    // Navigation
    [ForeignKey("PostId")]
    public Post Post { get; set; } = null!;
}
