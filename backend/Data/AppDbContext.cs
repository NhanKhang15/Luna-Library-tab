using Backend.Entities;
using Microsoft.EntityFrameworkCore;

namespace Backend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    // Posts
    public DbSet<Expert> Experts => Set<Expert>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<PostStats> PostStats => Set<PostStats>();
    public DbSet<PostLike> PostLikes => Set<PostLike>();
    public DbSet<ContentCategory> ContentCategories => Set<ContentCategory>();
    public DbSet<PostCategory> PostCategories => Set<PostCategory>();

    // Videos
    public DbSet<Video> Videos => Set<Video>();
    public DbSet<VideoStats> VideoStats => Set<VideoStats>();
    public DbSet<VideoLike> VideoLikes => Set<VideoLike>();
    public DbSet<VideoCategory> VideoCategories => Set<VideoCategory>();

    // Tags
    public DbSet<Tag> Tags => Set<Tag>();
    public DbSet<PostTag> PostTags => Set<PostTag>();
    public DbSet<VideoTag> VideoTags => Set<VideoTag>();

    // Users & Auth
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Expert configuration
        modelBuilder.Entity<Expert>(entity =>
        {
            entity.HasKey(e => e.ExpertId);
        });

        // Post configuration
        modelBuilder.Entity<Post>(entity =>
        {
            entity.HasKey(e => e.PostId);
            
            entity.HasOne(p => p.Expert)
                .WithMany(e => e.Posts)
                .HasForeignKey(p => p.ExpertId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(p => p.Stats)
                .WithOne(s => s.Post)
                .HasForeignKey<PostStats>(s => s.PostId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // PostStats configuration
        modelBuilder.Entity<PostStats>(entity =>
        {
            entity.HasKey(e => e.PostId);
        });

        // PostLike configuration (composite key)
        modelBuilder.Entity<PostLike>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.PostId });
            
            entity.HasOne(l => l.Post)
                .WithMany(p => p.Likes)
                .HasForeignKey(l => l.PostId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ContentCategory configuration
        modelBuilder.Entity<ContentCategory>(entity =>
        {
            entity.HasKey(e => e.CategoryId);
        });

        // PostCategory configuration (junction table)
        modelBuilder.Entity<PostCategory>(entity =>
        {
            entity.HasKey(e => new { e.PostId, e.CategoryId });

            entity.HasOne(pc => pc.Post)
                .WithMany(p => p.PostCategories)
                .HasForeignKey(pc => pc.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(pc => pc.Category)
                .WithMany()
                .HasForeignKey(pc => pc.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ============== VIDEO CONFIGURATIONS ==============

        // Video configuration
        modelBuilder.Entity<Video>(entity =>
        {
            entity.HasKey(e => e.VideoId);
            
            entity.HasOne(v => v.Expert)
                .WithMany()
                .HasForeignKey(v => v.ExpertId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(v => v.Stats)
                .WithOne(s => s.Video)
                .HasForeignKey<VideoStats>(s => s.VideoId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // VideoStats configuration
        modelBuilder.Entity<VideoStats>(entity =>
        {
            entity.HasKey(e => e.VideoId);
        });

        // VideoLike configuration (composite key)
        modelBuilder.Entity<VideoLike>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.VideoId });
            
            entity.HasOne(l => l.Video)
                .WithMany(v => v.Likes)
                .HasForeignKey(l => l.VideoId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // VideoCategory configuration (junction table)
        modelBuilder.Entity<VideoCategory>(entity =>
        {
            entity.HasKey(e => new { e.VideoId, e.CategoryId });

            entity.HasOne(vc => vc.Video)
                .WithMany(v => v.VideoCategories)
                .HasForeignKey(vc => vc.VideoId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(vc => vc.Category)
                .WithMany()
                .HasForeignKey(vc => vc.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // ============== TAG CONFIGURATIONS ==============

        // Tag configuration
        modelBuilder.Entity<Tag>(entity =>
        {
            entity.HasKey(e => e.TagId);
        });

        // PostTag configuration (junction table)
        modelBuilder.Entity<PostTag>(entity =>
        {
            entity.HasKey(e => new { e.PostId, e.TagId });

            entity.HasOne(pt => pt.Post)
                .WithMany(p => p.PostTags)
                .HasForeignKey(pt => pt.PostId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(pt => pt.Tag)
                .WithMany(t => t.PostTags)
                .HasForeignKey(pt => pt.TagId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // VideoTag configuration (junction table)
        modelBuilder.Entity<VideoTag>(entity =>
        {
            entity.HasKey(e => new { e.VideoId, e.TagId });

            entity.HasOne(vt => vt.Video)
                .WithMany(v => v.VideoTags)
                .HasForeignKey(vt => vt.VideoId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(vt => vt.Tag)
                .WithMany(t => t.VideoTags)
                .HasForeignKey(vt => vt.TagId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
