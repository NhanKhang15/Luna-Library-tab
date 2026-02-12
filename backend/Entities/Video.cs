using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

[Table("Videos")]
public class Video
{
    [Key]
    [Column("video_id")]
    public int VideoId { get; set; }

    [Column("expert_id")]
    public int? ExpertId { get; set; }

    [Column("title")]
    [Required]
    [MaxLength(255)]
    public string Title { get; set; } = string.Empty;

    [Column("description")]
    public string? Description { get; set; }

    [Column("thumbnail_url")]
    [MaxLength(500)]
    public string? ThumbnailUrl { get; set; }

    [Column("video_url")]
    [Required]
    [MaxLength(500)]
    public string VideoUrl { get; set; } = string.Empty;

    [Column("duration_seconds")]
    public int DurationSeconds { get; set; }

    [Column("is_short")]
    public bool IsShort { get; set; }

    [Column("is_premium")]
    public bool IsPremium { get; set; }

    [Column("status")]
    [MaxLength(20)]
    public string Status { get; set; } = "draft";

    [Column("published_at")]
    public DateTime? PublishedAt { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }

    [Column("updated_at")]
    public DateTime UpdatedAt { get; set; }

    // Navigation
    [ForeignKey("ExpertId")]
    public Expert? Expert { get; set; }

    public VideoStats? Stats { get; set; }
    public ICollection<VideoLike> Likes { get; set; } = new List<VideoLike>();
    public ICollection<VideoCategory> VideoCategories { get; set; } = new List<VideoCategory>();
    public ICollection<VideoTag> VideoTags { get; set; } = new List<VideoTag>();
}
