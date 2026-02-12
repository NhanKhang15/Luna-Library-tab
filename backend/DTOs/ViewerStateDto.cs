namespace Backend.DTOs;

public class ViewerStateDto
{
    public bool Liked { get; set; }
    // Note: saved not available - PostSaves table doesn't exist in schema
}
