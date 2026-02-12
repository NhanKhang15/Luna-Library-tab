using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

[Table("VideoTags")]
public class VideoTag
{
    [Column("video_id")]
    public int VideoId { get; set; }

    [Column("tag_id")]
    public int TagId { get; set; }

    // Navigation
    [ForeignKey("VideoId")]
    public Video Video { get; set; } = null!;

    [ForeignKey("TagId")]
    public Tag Tag { get; set; } = null!;
}
