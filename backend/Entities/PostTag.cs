using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

[Table("PostTags")]
public class PostTag
{
    [Column("post_id")]
    public int PostId { get; set; }

    [Column("tag_id")]
    public int TagId { get; set; }

    // Navigation
    [ForeignKey("PostId")]
    public Post Post { get; set; } = null!;

    [ForeignKey("TagId")]
    public Tag Tag { get; set; } = null!;
}
