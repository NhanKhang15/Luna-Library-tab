using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

/// <summary>
/// Maps to existing Users table in Floria_2 database
/// </summary>
[Table("Users")]
public class User
{
    [Key]
    [Column("user_id")]
    public int UserId { get; set; }

    [Column("email")]
    [Required]
    [StringLength(255)]
    public string Email { get; set; } = string.Empty;

    [Column("password_hashed")]
    [Required]
    [StringLength(255)]
    public string PasswordHashed { get; set; } = string.Empty;

    [Column("name")]
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Column("phone")]
    [StringLength(20)]
    public string? Phone { get; set; }

    [Column("active")]
    public bool Active { get; set; } = true;

    [Column("role")]
    [Required]
    [StringLength(50)]
    public string Role { get; set; } = "user";

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;
}
