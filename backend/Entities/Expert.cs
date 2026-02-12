using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

[Table("Experts")]
public class Expert
{
    [Key]
    [Column("expert_id")]
    public int ExpertId { get; set; }

    [Column("full_name")]
    [Required]
    [MaxLength(100)]
    public string FullName { get; set; } = string.Empty;

    [Column("specialization")]
    [MaxLength(100)]
    public string? Specialization { get; set; }

    [Column("contact_info")]
    [MaxLength(255)]
    public string? ContactInfo { get; set; }

    [Column("user_id")]
    public int? UserId { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; }

    // Navigation
    public ICollection<Post> Posts { get; set; } = new List<Post>();
}
