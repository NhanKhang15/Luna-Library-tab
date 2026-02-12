using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

[Table("Tags")]
public class Tag
{
    [Key]
    [Column("tag_id")]
    public int TagId { get; set; }

    [Column("name")]
    [Required]
    [MaxLength(80)]
    public string Name { get; set; } = string.Empty;

    [Column("slug")]
    [Required]
    [MaxLength(120)]
    public string Slug { get; set; } = string.Empty;

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }

    // Navigation
    public ICollection<PostTag> PostTags { get; set; } = new List<PostTag>();
    public ICollection<VideoTag> VideoTags { get; set; } = new List<VideoTag>();
}
