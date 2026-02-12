namespace Backend.DTOs;

/// <summary>
/// Response DTO for successful registration
/// </summary>
public class SignupResponseDto
{
    /// <summary>
    /// Whether registration was successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Success message
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// Registered user information
    /// </summary>
    public UserDto? User { get; set; }
}
