using Backend.Data;
using Backend.DTOs;
using Backend.Entities;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

/// <summary>
/// Authentication service implementation
/// </summary>
public class AuthService : IAuthService
{
    private readonly AppDbContext _context;
    private readonly IJwtTokenService _jwtTokenService;
    private readonly ILogger<AuthService> _logger;

    // TODO: Implement rate limiting / account lockout
    // Consider adding: IDistributedCache for tracking failed attempts
    // private readonly int MaxFailedAttempts = 5;
    // private readonly TimeSpan LockoutDuration = TimeSpan.FromMinutes(15);

    public AuthService(
        AppDbContext context,
        IJwtTokenService jwtTokenService,
        ILogger<AuthService> logger)
    {
        _context = context;
        _jwtTokenService = jwtTokenService;
        _logger = logger;
    }

    /// <inheritdoc/>
    public async Task<AuthResult> LoginAsync(LoginRequestDto request)
    {
        _logger.LogInformation("Login attempt for: {Email}", request.EmailOrUsername);

        // Find user by email (case-insensitive)
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Email.ToLower() == request.EmailOrUsername.ToLower());

        // User not found - return generic error to prevent user enumeration
        if (user == null)
        {
            _logger.LogWarning("Login failed: User not found for {Email}", request.EmailOrUsername);
            return AuthResult.Unauthorized("Invalid email or password");
        }

        // Check if account is active
        if (!user.Active)
        {
            _logger.LogWarning("Login failed: Account disabled for user {UserId}", user.UserId);
            return AuthResult.Forbidden("Account is disabled. Please contact support.");
        }

        // Verify password using BCrypt
        bool isPasswordValid;
        try
        {
            isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHashed);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "BCrypt verification error for user {UserId}", user.UserId);
            return AuthResult.Unauthorized("Invalid email or password");
        }

        if (!isPasswordValid)
        {
            _logger.LogWarning("Login failed: Invalid password for user {UserId}", user.UserId);
            // TODO: Track failed attempts for rate limiting
            return AuthResult.Unauthorized("Invalid email or password");
        }

        // Generate tokens
        var (accessToken, expiresIn) = _jwtTokenService.GenerateAccessToken(user);
        var refreshToken = _jwtTokenService.GenerateRefreshToken(user);

        _logger.LogInformation("Login successful for user {UserId}", user.UserId);

        // Build response
        var response = new LoginResponseDto
        {
            AccessToken = accessToken,
            ExpiresIn = expiresIn,
            RefreshToken = refreshToken,
            User = new UserDto
            {
                Id = user.UserId,
                Email = user.Email,
                Name = user.Name,
                Role = user.Role
            }
        };

        return AuthResult.Ok(response);
    }

    /// <inheritdoc/>
    public async Task<RegisterResult> RegisterAsync(SignupRequestDto request)
    {
        _logger.LogInformation("Registration attempt for: {Email}", request.Email);

        // Check if email already exists (case-insensitive)
        var emailExists = await _context.Users
            .AnyAsync(u => u.Email.ToLower() == request.Email.ToLower());

        if (emailExists)
        {
            _logger.LogWarning("Registration failed: Email already exists - {Email}", request.Email);
            return RegisterResult.Conflict("An account with this email already exists");
        }

        // Hash password using BCrypt
        string passwordHash;
        try
        {
            passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password, workFactor: 12);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "BCrypt hashing error during registration");
            return RegisterResult.BadRequest("Failed to process password");
        }

        // Create new user entity
        var user = new User
        {
            Email = request.Email.Trim(),
            PasswordHashed = passwordHash,
            Name = request.Name.Trim(),
            Phone = request.Phone?.Trim(),
            Active = true,
            Role = "user", // Default role for new registrations
            CreatedAt = DateTime.Now
        };

        try
        {
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Registration successful for user {UserId} - {Email}", user.UserId, user.Email);

            // Build response
            var response = new SignupResponseDto
            {
                Success = true,
                Message = "Registration successful. You can now login with your credentials.",
                User = new UserDto
                {
                    Id = user.UserId,
                    Email = user.Email,
                    Name = user.Name,
                    Role = user.Role
                }
            };

            return RegisterResult.Ok(response);
        }
        catch (DbUpdateException ex)
        {
            _logger.LogError(ex, "Database error during registration for {Email}", request.Email);
            
            // Check for unique constraint violation
            if (ex.InnerException?.Message.Contains("UNIQUE") == true ||
                ex.InnerException?.Message.Contains("duplicate") == true)
            {
                return RegisterResult.Conflict("An account with this email already exists");
            }

            return RegisterResult.BadRequest("Failed to create account. Please try again.");
        }
    }
}
