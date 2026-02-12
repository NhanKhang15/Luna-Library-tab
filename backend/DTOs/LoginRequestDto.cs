using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs;

/// <summary>
/// Request DTO for login endpoint
/// </summary>
public class LoginRequestDto
{
    /// <summary>
    /// User's email address (email field in DB)
    /// </summary>
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    public string EmailOrUsername { get; set; } = string.Empty;

    /// <summary>
    /// User's password (will be verified against BCrypt hash)
    /// </summary>
    [Required(ErrorMessage = "Password is required")]
    [MinLength(6, ErrorMessage = "Password must be at least 6 characters")]
    public string Password { get; set; } = string.Empty;
}
