-- Create PostTags junction table
CREATE TABLE dbo.PostTags (
    post_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES dbo.Posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES dbo.Tags(tag_id) ON DELETE CASCADE
);
GO

-- Create VideoTags junction table
CREATE TABLE dbo.VideoTags (
    video_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (video_id, tag_id),
    FOREIGN KEY (video_id) REFERENCES dbo.Videos(video_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES dbo.Tags(tag_id) ON DELETE CASCADE
);
GO

-- Sample data: Link posts to tags (adjust IDs based on your data)
-- First, check existing tags:
-- SELECT * FROM dbo.Tags;

-- Example: Link post 1 to tag "Tâm lý" (assuming tag_id = 1)
-- INSERT INTO dbo.PostTags (post_id, tag_id) VALUES (1, 1);

-- Example: Link video 1 to tag "Sinh lý" (assuming tag_id = 2)
-- INSERT INTO dbo.VideoTags (video_id, tag_id) VALUES (1, 2);
