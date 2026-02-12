using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Backend.Entities;
using Microsoft.IdentityModel.Tokens;

namespace Backend.Services;

/// <summary>
/// JWT token generation service
/// </summary>
public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<JwtTokenService> _logger;

    public JwtTokenService(IConfiguration configuration, ILogger<JwtTokenService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    /// <inheritdoc/>
    public (string Token, int ExpiresIn) GenerateAccessToken(User user)
    {
        var jwtSettings = _configuration.GetSection("Jwt");
        var key = jwtSettings["Key"] ?? throw new InvalidOperationException("JWT Key is not configured");
        var issuer = jwtSettings["Issuer"] ?? "FloriaAPI";
        var audience = jwtSettings["Audience"] ?? "FloriaApp";
        var accessTokenMinutes = int.Parse(jwtSettings["AccessTokenMinutes"] ?? "60");

        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new(ClaimTypes.Role, user.Role),
            new("name", user.Name)
        };

        var expires = DateTime.UtcNow.AddMinutes(accessTokenMinutes);
        var expiresInSeconds = accessTokenMinutes * 60;

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: expires,
            signingCredentials: credentials
        );

        var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

        _logger.LogInformation("Generated JWT token for user {UserId}", user.UserId);

        return (tokenString, expiresInSeconds);
    }

    /// <inheritdoc/>
    public string? GenerateRefreshToken(User user)
    {
        // TODO: Implement refresh token generation
        // This is a placeholder for future implementation
        // Should generate a secure random token and store in RefreshTokens table
        _logger.LogDebug("Refresh token generation not yet implemented for user {UserId}", user.UserId);
        return null;
    }
}
