using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Entities;

/// <summary>
/// RefreshToken entity for future refresh token implementation.
/// Currently a placeholder for extensibility.
/// </summary>
[Table("RefreshTokens")]
public class RefreshToken
{
    [Key]
    [Column("token_id")]
    public int TokenId { get; set; }

    [Column("user_id")]
    [Required]
    public int UserId { get; set; }

    [Column("token")]
    [Required]
    [StringLength(500)]
    public string Token { get; set; } = string.Empty;

    [Column("expires_at")]
    [Required]
    public DateTime ExpiresAt { get; set; }

    [Column("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    [Column("revoked_at")]
    public DateTime? RevokedAt { get; set; }

    [Column("is_revoked")]
    public bool IsRevoked { get; set; } = false;

    // Navigation property
    public virtual User? User { get; set; }
}
