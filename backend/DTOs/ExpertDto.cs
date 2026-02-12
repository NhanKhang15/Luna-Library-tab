namespace Backend.DTOs;

public class ExpertDto
{
    public int ExpertId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Specialization { get; set; }
    // Note: rating and reviewCount not in database schema
}
