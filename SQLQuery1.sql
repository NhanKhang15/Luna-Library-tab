USE master;
GO

CREATE DATABASE Floria_2;
GO

USE Floria_2;
GO

-- Bảng Users
CREATE TABLE dbo.Users (
    UserID             INT IDENTITY(1,1) PRIMARY KEY,
    Username           VARCHAR(50)  NOT NULL,
    Email              VARCHAR(100) NULL,
    PhoneNumber        NVARCHAR(20) NULL, 
    
    PasswordHashed     VARBINARY(255) NULL,

    SocialProvider     VARCHAR(20) NULL,
    SocialUID          VARCHAR(255) NULL,

    AuthPrimary        VARCHAR(20) NOT NULL CONSTRAINT DF_Users_AuthPrimary DEFAULT ('local'),
    Status             VARCHAR(20) NOT NULL CONSTRAINT DF_Users_Status DEFAULT ('active'),
    CreatedAt          DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),

    profile_completed  BIT NOT NULL CONSTRAINT DF_Users_ProfileCompleted DEFAULT (0),
    AccountVerified      BIT NOT NULL CONSTRAINT DF_Users_AccountVerified DEFAULT (0),

    CONSTRAINT UQ_Users_Username UNIQUE (Username),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT UQ_Users_Social UNIQUE (SocialProvider, SocialUID),

    -- Enum replacements
    CONSTRAINT CK_Users_SocialProvider CHECK (SocialProvider IN ('google','facebook','Apple') OR SocialProvider IS NULL),
    CONSTRAINT CK_Users_AuthPrimary    CHECK (AuthPrimary IN ('local','google','facebook','Apple')),
    CONSTRAINT CK_Users_Status         CHECK (Status IN ('active','disabled','banned')),

    -- Credential rules (dịch từ MySQL CHECK của m)
    CONSTRAINT CK_Users_Credentials CHECK (
        (AuthPrimary = 'local'
            AND PasswordHashed IS NOT NULL
            AND SocialProvider IS NULL
            AND SocialUID IS NULL)
        OR
        (AuthPrimary IN ('google','facebook','Apple')
            AND PasswordHashed IS NULL
            AND SocialProvider = AuthPrimary
            AND SocialUID IS NOT NULL)
    )
);
GO
  
-- Bảng OTP   
CREATE TABLE dbo.OTPRequests (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    method VARCHAR(10) NOT NULL CHECK (method IN ('email', 'sms')),
    target VARCHAR(255) NOT NULL,
    otp_hash VARCHAR(128) NOT NULL,  -- SHA-256 hex = 64 chars
    attempts INT NOT NULL DEFAULT 0,
    created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    expires_at DATETIME2(0) NOT NULL,
    is_verified BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_OTPRequests_User FOREIGN KEY (user_id) REFERENCES dbo.Users(UserID)
);
GO

-- Bảng UserProfiles
CREATE TABLE UserProfiles (
    profile_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT UNIQUE NOT NULL,
    date_of_birth DATE,
    height FLOAT,
    weight FLOAT,
    medical_history NVARCHAR(MAX),
    blood_type NVARCHAR(10),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
GO

-- Bảng MenstrualCycles
CREATE TABLE MenstrualCycles (
    cycle_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    cycle_length INT,
    recorded_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
GO

-- Bảng Symptoms
CREATE TABLE Symptoms (
    symptom_id INT PRIMARY KEY IDENTITY(1,1),
    symptom_name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX)
);
GO

-- Bảng trung gian CycleSymptoms
CREATE TABLE CycleSymptoms (
    cycle_symptom_id INT PRIMARY KEY IDENTITY(1,1),
    cycle_id INT NOT NULL,
    symptom_id INT NOT NULL,
    severity NVARCHAR(50),
    FOREIGN KEY (cycle_id) REFERENCES MenstrualCycles(cycle_id),
    FOREIGN KEY (symptom_id) REFERENCES Symptoms(symptom_id)
);
GO

-- Bảng CyclePredictions
CREATE TABLE CyclePredictions (
    prediction_id INT PRIMARY KEY IDENTITY(1,1),
    cycle_id INT NOT NULL,
    predicted_ovulation DATE,
    predicted_period DATE,
    confidence_score FLOAT,
    FOREIGN KEY (cycle_id) REFERENCES MenstrualCycles(cycle_id)
);
GO

-- Bảng Experts
CREATE TABLE Experts (
    expert_id INT PRIMARY KEY IDENTITY(1,1),
    full_name NVARCHAR(100) NOT NULL,
    title NVARCHAR(100) NULL,      -- e.g. 'ThS. Tâm lý học'
    bio NVARCHAR(MAX) NULL,        -- 'Giới thiệu' section
    experience_years INT DEFAULT 0,
    price_per_session DECIMAL(18, 2) DEFAULT 0,
    currency NVARCHAR(10) DEFAULT 'VND',
    rating DECIMAL(3, 1) DEFAULT 0, -- Cached average rating (4.8)
    rating_count INT DEFAULT 0,    -- Cached count (132 đánh giá)
    consultation_count INT DEFAULT 0, -- (396 buổi)
    is_verified BIT DEFAULT 0,
    avatar_url NVARCHAR(500) NULL,
    contact_info NVARCHAR(255),
	user_id INT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
	CONSTRAINT FK_Experts_Users
	FOREIGN KEY (user_id) REFERENCES dbo.Users(user_id)
);
GO

-- Bảng Consultations
CREATE TABLE Consultations (
    consultation_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    expert_id INT NOT NULL,
    consultation_time DATETIME NOT NULL,
    status NVARCHAR(50) NOT NULL,
    notes NVARCHAR(MAX),
    consultation_duration INT CHECK (consultation_duration IN (15, 30, 45)),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (expert_id) REFERENCES Experts(expert_id)
);
GO

-- Bảng ExpertReviews
CREATE TABLE ExpertReviews (
    review_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    expert_id INT NOT NULL,
    user_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment NVARCHAR(MAX) NULL,
    created_at DATETIME2(0) DEFAULT GETDATE(),
    updated_at DATETIME2(0) DEFAULT GETDATE(),
    FOREIGN KEY (expert_id) REFERENCES Experts(expert_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);
GO

-- Bảng ExpertAvailability
CREATE TABLE ExpertAvailability (
    availability_id INT IDENTITY(1,1) PRIMARY KEY,
    expert_id INT NOT NULL,
    start_time DATETIME2(0) NOT NULL,
    end_time DATETIME2(0) NOT NULL,
    is_booked BIT DEFAULT 0,
    consultation_id INT NULL,
    created_at DATETIME2(0) DEFAULT GETDATE(),
    FOREIGN KEY (expert_id) REFERENCES Experts(expert_id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES Consultations(consultation_id)
);
GO

-- Bảng Messages
CREATE TABLE Messages (
    message_id INT PRIMARY KEY IDENTITY(1,1),
    consultation_id INT NOT NULL,
    sender_id INT NOT NULL,
    message_content NVARCHAR(MAX) NOT NULL,
    sent_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (consultation_id) REFERENCES Consultations(consultation_id)
);
GO

-- Bảng Notifications
CREATE TABLE Notifications (
    notification_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    message NVARCHAR(MAX) NOT NULL,
    sent_at DATETIME DEFAULT GETDATE(),
    status NVARCHAR(50) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
GO

-- Bảng: question_sets – Bộ câu hỏi
CREATE TABLE question_sets (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX) NULL,
    is_active BIT NOT NULL DEFAULT 1,
	is_locked BIT NOT NULL DEFAULT 0,
	isScore BIT NOT NULL DEFAULT 0,
	max_score DECIMAL(5,2) NOT NULL DEFAULT 10,
    created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO

-- Bảng: Questions – Câu hỏi
CREATE TABLE Questions (
    id INT IDENTITY(1,1) PRIMARY KEY,
    question_set_id INT NOT NULL,
    [text] NVARCHAR(MAX) NOT NULL,
    [type] NVARCHAR(20) NOT NULL CHECK ([type] IN (N'single', N'multiple', N'text')),
    order_in_set INT NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
	is_locked BIT NOT NULL DEFAULT 0,
	skipped BIT NOT NULL CONSTRAINT DF_Questions_skipped DEFAULT (0),
	max_points DECIMAL(5,2) NULL,
    created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (question_set_id) REFERENCES question_sets(id)
);
GO

-- Bảng: Answers – Danh sách đáp án
CREATE TABLE Answers (
    id INT IDENTITY(1,1) PRIMARY KEY,
    question_id INT NOT NULL,
    label NCHAR(1) NOT NULL,
    [text] NVARCHAR(MAX) NOT NULL,
    hint NVARCHAR(MAX) NULL,
    order_in_question INT NULL,
	is_exclusive BIT NOT NULL DEFAULT 0, -- Nếu chọn câu này thì không thể chọn câu khác được
	is_active BIT NOT NULL DEFAULT 1,
	points DECIMAL(5,2) NOT NULL DEFAULT 0,
    created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (question_id) REFERENCES Questions(id)
);
GO

-- Bảng: answer_combinations – Rẽ nhánh theo tổ hợp đáp án
CREATE TABLE answer_combinations (
    id INT IDENTITY(1,1) PRIMARY KEY,
    question_id INT NOT NULL,
    combination NVARCHAR(255) NOT NULL,
    next_question_set_id INT NULL,
    created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (question_id) REFERENCES Questions(id),
    FOREIGN KEY (next_question_set_id) REFERENCES question_sets(id)
);
GO

-- Bảng: UserAnswers – Lưu câu trả lời người dùng
CREATE TABLE UserAnswers (
    user_answer_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    question_id INT NOT NULL,
    answer_id INT NOT NULL,
    cycle_id INT NULL,
    created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES Questions(id),
    FOREIGN KEY (answer_id) REFERENCES Answers(id),
    FOREIGN KEY (cycle_id) REFERENCES MenstrualCycles(cycle_id) ON DELETE SET NULL
);
GO

CREATE TABLE dbo.ContentCategories (
  category_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(120) NOT NULL,
  slug NVARCHAR(160) NOT NULL UNIQUE,
  description NVARCHAR(MAX) NULL,
  is_active BIT NOT NULL DEFAULT 1,
  created_at DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.Tags (
  tag_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(80) NOT NULL,
  slug NVARCHAR(120) NOT NULL UNIQUE,
  created_at DATETIME2(0) NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.ExpertSpecialties (
    expert_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (expert_id, tag_id),
    FOREIGN KEY (expert_id) REFERENCES dbo.Experts(expert_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES dbo.Tags(tag_id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Videos (
  video_id INT IDENTITY(1,1) PRIMARY KEY,
  expert_id INT NULL, -- nếu video thuộc chuyên gia
  title NVARCHAR(255) NOT NULL,
  description NVARCHAR(MAX) NULL,

  thumbnail_url NVARCHAR(500) NULL,
  video_url NVARCHAR(500) NOT NULL,

  duration_seconds INT NOT NULL DEFAULT 0,
  is_short BIT NOT NULL DEFAULT 0,
  is_premium BIT NOT NULL DEFAULT 0,

  status NVARCHAR(20) NOT NULL DEFAULT N'draft'
    CHECK (status IN (N'draft', N'published', N'hidden')),

  published_at DATETIME2(0) NULL,
  created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  updated_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),

  FOREIGN KEY (expert_id) REFERENCES dbo.Experts(expert_id)
);
GO

CREATE TABLE dbo.VideoCategories (
  video_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (video_id, category_id),
  FOREIGN KEY (video_id) REFERENCES dbo.Videos(video_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES dbo.ContentCategories(category_id)
);
GO

CREATE TABLE dbo.VideoTags (
  video_id INT NOT NULL,
  tag_id INT NOT NULL,
  PRIMARY KEY (video_id, tag_id),
  FOREIGN KEY (video_id) REFERENCES dbo.Videos(video_id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES dbo.Tags(tag_id)
);
GO

CREATE TABLE dbo.VideoStats (
  video_id INT PRIMARY KEY,
  view_count BIGINT NOT NULL DEFAULT 0,
  like_count BIGINT NOT NULL DEFAULT 0,
  updated_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  FOREIGN KEY (video_id) REFERENCES dbo.Videos(video_id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.VideoLikes (
  user_id INT NOT NULL,
  video_id INT NOT NULL,
  created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  PRIMARY KEY (user_id, video_id),
  FOREIGN KEY (user_id) REFERENCES dbo.Users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (video_id) REFERENCES dbo.Videos(video_id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.VideoViews (
  view_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NULL,              -- cho phép guest
  video_id INT NOT NULL,
  viewed_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  ip_hash NVARCHAR(80) NULL,
  FOREIGN KEY (user_id) REFERENCES dbo.Users(user_id) ON DELETE SET NULL,
  FOREIGN KEY (video_id) REFERENCES dbo.Videos(video_id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Posts (
  post_id INT IDENTITY(1,1) PRIMARY KEY,
  expert_id INT NULL,

  title NVARCHAR(255) NOT NULL,
  summary NVARCHAR(500) NULL,
  content NVARCHAR(MAX) NOT NULL,     -- HTML/Markdown
  thumbnail_url NVARCHAR(500) NULL,

  is_premium BIT NOT NULL DEFAULT 0,
  status NVARCHAR(20) NOT NULL DEFAULT N'draft'
    CHECK (status IN (N'draft', N'published', N'hidden')),

  published_at DATETIME2(0) NULL,
  created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  updated_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),

  FOREIGN KEY (expert_id) REFERENCES dbo.Experts(expert_id)
);
GO

CREATE TABLE dbo.PostCategories (
  post_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (post_id, category_id),
  FOREIGN KEY (post_id) REFERENCES dbo.Posts(post_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES dbo.ContentCategories(category_id)
);
GO

CREATE TABLE dbo.PostTags (
  post_id INT NOT NULL,
  tag_id INT NOT NULL,
  PRIMARY KEY (post_id, tag_id),
  FOREIGN KEY (post_id) REFERENCES dbo.Posts(post_id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES dbo.Tags(tag_id)
);
GO

CREATE TABLE dbo.PostStats (
  post_id INT PRIMARY KEY,
  view_count BIGINT NOT NULL DEFAULT 0,
  like_count BIGINT NOT NULL DEFAULT 0,
  updated_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  FOREIGN KEY (post_id) REFERENCES dbo.Posts(post_id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.PostLikes (
  user_id INT NOT NULL,
  post_id INT NOT NULL,
  created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  PRIMARY KEY (user_id, post_id),
  FOREIGN KEY (user_id) REFERENCES dbo.Users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (post_id) REFERENCES dbo.Posts(post_id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.PostViews (
  view_id BIGINT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NULL,
  post_id INT NOT NULL,
  viewed_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  ip_hash NVARCHAR(80) NULL,
  FOREIGN KEY (user_id) REFERENCES dbo.Users(user_id) ON DELETE SET NULL,
  FOREIGN KEY (post_id) REFERENCES dbo.Posts(post_id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.ExpertFollows (
  user_id INT NOT NULL,
  expert_id INT NOT NULL,
  created_at DATETIME2(0) NOT NULL DEFAULT GETDATE(),
  PRIMARY KEY (user_id, expert_id),
  FOREIGN KEY (user_id) REFERENCES dbo.Users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (expert_id) REFERENCES dbo.Experts(expert_id) ON DELETE CASCADE
);
GO

CREATE INDEX IX_Videos_Status_PublishedAt ON dbo.Videos(status, published_at DESC);
CREATE INDEX IX_Posts_Status_PublishedAt  ON dbo.Posts(status, published_at DESC);

CREATE INDEX IX_VideoViews_VideoId_Time ON dbo.VideoViews(video_id, viewed_at DESC);
CREATE INDEX IX_PostViews_PostId_Time   ON dbo.PostViews(post_id, viewed_at DESC);
GO

BEGIN TRAN;
SET NOCOUNT ON;

-- Tài khoản user
INSERT INTO Users (email, password_hashed, name, phone, active, role, created_at)
VALUES (
    'user@example.com',
    '$2a$12$Im82Gf3XxevaL9zDrC09KOZ2Bmvmj24/ernQCje7syRd/AHoWqREi',
    'user',
    '0123456789',
    1,
    'user',
    GETDATE()
);

-- Tài khoản admin
INSERT INTO Users (email, password_hashed, name, phone, active, role, created_at)
VALUES (
    'admin@example.com',
    '$2a$12$xm8xq15XZH7beCMdg02W7uCAC64yO2ctY9QOVCerrlroW3jjS3kk.',
    'admin',
    '0987654321',
    1,
    'admin',
    GETDATE()
);
GO


-- === question_sets (keep CSV IDs) ===
SET IDENTITY_INSERT dbo.question_sets ON;
INSERT INTO dbo.question_sets (id, name, description, is_active, created_at, updated_at) VALUES (1, N'Bộ câu hỏi sàng lọc', N'Sàng lọc ban đầu', 1, '2025-08-21 10:00:00', '2025-08-21 10:00:00');
INSERT INTO dbo.question_sets (id, name, description, is_active, created_at, updated_at) VALUES (2, N'Theo dõi chu kỳ', N'Theo dõi chu kỳ kinh nguyệt', 1, '2025-08-21 10:00:00', '2025-08-21 10:00:00');
INSERT INTO dbo.question_sets (id, name, description, is_active, created_at, updated_at) VALUES (3, N'Tư vấn sau sinh / mang thai', N'Dùng cho thai kỳ hoặc sau sinh', 1, '2025-08-21 10:00:00', '2025-08-21 10:00:00');
SET IDENTITY_INSERT dbo.question_sets OFF;

-- === Questions ===
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Chu kỳ kinh nguyệt của bạn thường kéo dài bao nhiêu ngày?', N'single', 1, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Tình trạng thai kỳ hiện tại của bạn là gì?', N'single', 2, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có đang sử dụng biện pháp tránh thai nào không?', N'single', 3, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Ngày đầu tiên của kỳ kinh gần nhất là khi nào?', N'single', 4, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn thường bị đau bụng kinh không?', N'single', 5, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Màu sắc máu kinh nguyệt của bạn thường là gì?', N'single', 6, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Lượng máu kinh của bạn như thế nào?', N'single', 7, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn thường có những triệu chứng nào trước hoặc trong kỳ kinh?', N'single', 8, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn đã từng bị rong kinh chưa?', N'single', 9, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có từng được chẩn đoán mắc các bệnh phụ khoa nào sau đây?', N'single', 10, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có bị rối loạn kinh nguyệt không?', N'single', 11, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn thường bị chuột rút trong kỳ kinh không?', N'single', 12, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có từng bị trễ kinh quá 7 ngày không?', N'single', 13, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Tâm trạng của bạn thường thay đổi như thế nào quanh kỳ kinh?', N'single', 14, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có nhu cầu theo dõi những gì trong chu kỳ?', N'single', 15, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có theo dõi chu kỳ kinh nguyệt hằng tháng không?', N'single', 16, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Chu kỳ của bạn thường kéo dài bao nhiêu ngày?', N'single', 17, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có hay bị rối loạn kinh nguyệt không?', N'single', 18, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có thường gặp triệu chứng tiền kinh nguyệt (PMS) không?', N'single', 19, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có ghi chú lại ngày rụng trứng không?', N'single', 20, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có dùng app hoặc sổ để theo dõi chu kỳ không?', N'single', 21, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có từng bỏ lỡ kỳ kinh nào trong 6 tháng gần đây không?', N'single', 22, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có gặp vấn đề về chu kỳ sau khi thay đổi chế độ ăn không?', N'single', 23, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có bị đau bụng hoặc khó chịu trong chu kỳ không?', N'single', 24, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (1, N'Bạn có muốn dự đoán ngày rụng trứng để mang thai hoặc tránh thai không?', N'single', 25, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn đã từng khám sức khỏe tổng quát trong năm nay chưa?', N'single', 1, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn có tiền sử bệnh mãn tính nào không?', N'single', 2, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn có hút thuốc hoặc uống rượu thường xuyên không?', N'single', 3, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn có bị dị ứng với loại thuốc hoặc thực phẩm nào không?', N'single', 4, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Gia đình bạn có ai mắc bệnh di truyền không?', N'single', 5, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn có thường xuyên tập thể dục không?', N'single', 6, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn có gặp vấn đề về giấc ngủ trong thời gian dài không?', N'single', 7, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn có đang sử dụng thuốc theo toa không?', N'single', 8, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn có từng phẫu thuật trong vòng 5 năm qua không?', N'single', 9, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (2, N'Bạn có cảm thấy căng thẳng hoặc áp lực kéo dài không?', N'single', 10, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có gặp khó khăn khi cho con bú không?', N'single', 1, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có đang cảm thấy mệt mỏi sau sinh không?', N'single', 2, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có nhận được sự hỗ trợ từ gia đình sau sinh không?', N'single', 3, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có đang gặp các triệu chứng trầm cảm sau sinh không?', N'single', 4, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có gặp khó khăn trong việc cân bằng chăm sóc con và bản thân không?', N'single', 5, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có muốn được tư vấn về chế độ dinh dưỡng sau sinh không?', N'single', 6, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có gặp vấn đề về giấc ngủ do chăm con không?', N'single', 7, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có đang sử dụng biện pháp tránh thai sau sinh không?', N'single', 8, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có muốn tư vấn về việc phục hồi sức khỏe sau sinh không?', N'single', 9, 1);
INSERT INTO dbo.Questions (question_set_id, [text], [type], order_in_set, is_active) VALUES (3, N'Bạn có câu hỏi nào liên quan đến việc mang thai lần sau không?', N'single', 10, 1);

-- === Answers ===
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (1, N'A', N'Dưới 21 ngày', N'Chu kỳ ngắn', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (1, N'B', N'21-25 ngày', N'Chu kỳ ngắn', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (1, N'C', N'26-30 ngày', N'Chu kỳ dài', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (1, N'D', N'Trên 30 ngày', N'Chu kỳ dài', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (2, N'A', N'Không có thai', N'Liên quan đến tình trạng mang thai', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (2, N'B', N'Đang mang thai', N'Liên quan đến tình trạng mang thai', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (2, N'C', N'Đang cho con bú', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (2, N'D', N'Đang cố gắng có thai', N'Liên quan đến tình trạng mang thai', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (3, N'A', N'Không sử dụng', N'Không áp dụng hoặc không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (3, N'B', N'Bao cao su', N'Biện pháp tránh thai - bao cao su', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (3, N'C', N'Thuốc tránh thai', N'Liên quan đến tình trạng mang thai', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (3, N'D', N'Vòng tránh thai', N'Liên quan đến tình trạng mang thai', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (3, N'E', N'Khác', N'Khác/không có', 5);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (4, N'A', N'Dưới 7 ngày trước', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (4, N'B', N'7-14 ngày trước', N'Khác/không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (4, N'C', N'15-21 ngày trước', N'Chu kỳ ngắn', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (4, N'D', N'Hơn 21 ngày trước', N'Chu kỳ ngắn', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (5, N'A', N'Không đau', N'Không áp dụng hoặc không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (5, N'B', N'Đau nhẹ', N'Khác/không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (5, N'C', N'Đau vừa', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (5, N'D', N'Đau dữ dội', N'Khác/không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (6, N'A', N'Đỏ tươi', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (6, N'B', N'Đỏ sẫm', N'Khác/không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (6, N'C', N'Nâu', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (6, N'D', N'Đen', N'Khác/không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (7, N'A', N'Ít', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (7, N'B', N'Trung bình', N'Khác/không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (7, N'C', N'Nhiều', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (7, N'D', N'Rất nhiều', N'Khác/không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (8, N'A', N'Đau bụng', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (8, N'B', N'Đau lưng', N'Khác/không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (8, N'C', N'Mệt mỏi', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (8, N'D', N'Tâm trạng thay đổi', N'Khác/không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (8, N'E', N'Mụn', N'Khác/không có', 5);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (8, N'F', N'Không có triệu chứng', N'Khác/không có', 6);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (9, N'A', N'Chưa từng', N'Không áp dụng hoặc không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (9, N'B', N'Thỉnh thoảng', N'Khác/không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (9, N'C', N'Thường xuyên', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (10, N'A', N'Không có', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (10, N'B', N'U xơ tử cung', N'Không áp dụng hoặc không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (10, N'C', N'Lạc nội mạc tử cung', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (10, N'D', N'Viêm âm đạo', N'Khác/không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (10, N'E', N'Khác', N'Khác/không có', 5);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (11, N'A', N'Không', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (11, N'B', N'Thỉnh thoảng', N'Không áp dụng hoặc không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (11, N'C', N'Thường xuyên', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (12, N'A', N'Không', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (12, N'B', N'Ít khi', N'Không áp dụng hoặc không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (12, N'C', N'Thường xuyên', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (12, N'D', N'Rất thường xuyên', N'Khác/không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (13, N'A', N'Chưa từng', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (13, N'B', N'Thỉnh thoảng', N'Khác/không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (13, N'C', N'Thường xuyên', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (14, N'A', N'Không thay đổi', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (14, N'B', N'Tăng lo âu', N'Không áp dụng hoặc không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (14, N'C', N'Buồn bã', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (14, N'D', N'Cáu gắt', N'Khác/không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (14, N'E', N'Thay đổi thất thường', N'Khác/không có', 5);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (15, N'A', N'Ngày bắt đầu & kết thúc', N'Khác/không có', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (15, N'B', N'Tâm trạng', N'Khác/không có', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (15, N'C', N'Triệu chứng', N'Khác/không có', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (15, N'D', N'Lượng máu', N'Khác/không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (15, N'E', N'Tất cả các mục trên', N'Khác/không có', 5);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (16, N'A', N'Luôn luôn', N'Theo dõi đều đặn', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (16, N'B', N'Thỉnh thoảng', N'Không đều', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (16, N'C', N'Hiếm khi', N'Ít theo dõi', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (16, N'D', N'Không bao giờ', N'Không theo dõi', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (17, N'A', N'Dưới 21 ngày', N'Chu kỳ ngắn', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (17, N'B', N'21–25 ngày', N'Chu kỳ ngắn', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (17, N'C', N'26–30 ngày', N'Chu kỳ điển hình', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (17, N'D', N'Trên 30 ngày', N'Chu kỳ dài', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (18, N'A', N'Không bao giờ', N'Ổn định', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (18, N'B', N'1–2 lần', N'Thỉnh thoảng', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (18, N'C', N'3–4 lần', N'Tương đối thường', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (18, N'D', N'Trên 4 lần', N'Thường xuyên', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (19, N'A', N'Nặng', N'Ảnh hưởng sinh hoạt', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (19, N'B', N'Vừa', N'Gây khó chịu', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (19, N'C', N'Nhẹ', N'Ảnh hưởng ít', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (19, N'D', N'Không có', N'Không triệu chứng', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (20, N'A', N'Luôn luôn', N'Theo dõi đều đặn', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (20, N'B', N'Thỉnh thoảng', N'Không đều', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (20, N'C', N'Hiếm khi', N'Ít theo dõi', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (20, N'D', N'Không bao giờ', N'Không theo dõi', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (21, N'A', N'Luôn luôn', N'Theo dõi đều đặn', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (21, N'B', N'Thỉnh thoảng', N'Không đều', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (21, N'C', N'Hiếm khi', N'Ít theo dõi', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (21, N'D', N'Không bao giờ', N'Không theo dõi', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (22, N'A', N'Không bao giờ', N'Ổn định', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (22, N'B', N'1–2 lần', N'Thỉnh thoảng', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (22, N'C', N'3–4 lần', N'Tương đối thường', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (22, N'D', N'Trên 4 lần', N'Thường xuyên', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (23, N'A', N'Có', N'Trả lời khẳng định', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (23, N'B', N'Không', N'Trả lời phủ định', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (23, N'C', N'Đôi khi', N'Không thường xuyên', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (23, N'D', N'Không rõ', N'Chưa chắc chắn', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (24, N'A', N'Nặng', N'Cần tư vấn thêm', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (24, N'B', N'Vừa', N'Theo dõi thêm', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (24, N'C', N'Nhẹ', N'Tự chăm sóc', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (24, N'D', N'Không có', N'Bình thường', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (25, N'A', N'Muốn dự đoán để mang thai', N'Lập kế hoạch có thai', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (25, N'B', N'Muốn dự đoán để tránh thai', N'Kế hoạch tránh thai', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (25, N'C', N'Chỉ để theo dõi sức khỏe', N'Theo dõi thông tin', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (25, N'D', N'Chưa có nhu cầu', N'Không áp dụng', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (26, N'A', N'Có, trong 6 tháng gần đây', N'Gần đây', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (26, N'B', N'Có, trong 1 năm', N'Trong năm', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (26, N'C', N'Có, trên 1 năm', N'Đã lâu', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (26, N'D', N'Chưa từng/Không', N'Không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (33, N'A', N'Có, trong 6 tháng gần đây', N'Gần đây', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (33, N'B', N'Có, trong 1 năm', N'Trong năm', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (33, N'C', N'Có, trên 1 năm', N'Đã lâu', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (33, N'D', N'Chưa từng/Không', N'Không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (34, N'A', N'Có, trong 6 tháng gần đây', N'Gần đây', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (34, N'B', N'Có, trong 1 năm', N'Trong năm', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (34, N'C', N'Có, trên 1 năm', N'Đã lâu', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (34, N'D', N'Chưa từng/Không', N'Không có', 4);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (35, N'A', N'Cao', N'Ảnh hưởng sinh hoạt', 1);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (35, N'B', N'Vừa', N'Đáng chú ý', 2);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (35, N'C', N'Nhẹ', N'Ít ảnh hưởng', 3);
INSERT INTO dbo.Answers (question_id, label, [text], hint, order_in_question) VALUES (35, N'D', N'Không', N'Ổn định', 4);

-- === answer_combinations ===
INSERT INTO dbo.answer_combinations (question_id, combination, next_question_set_id) VALUES (1, N'A', 2);
INSERT INTO dbo.answer_combinations (question_id, combination, next_question_set_id) VALUES (1, N'D', 2);
INSERT INTO dbo.answer_combinations (question_id, combination, next_question_set_id) VALUES (1, N'B', 3);
INSERT INTO dbo.answer_combinations (question_id, combination, next_question_set_id) VALUES (1, N'C', 3);
INSERT INTO dbo.answer_combinations (question_id, combination, next_question_set_id) VALUES (1, N'E', 3);
INSERT INTO dbo.answer_combinations (question_id, combination, next_question_set_id) VALUES (2, N'A', 2);
INSERT INTO dbo.answer_combinations (question_id, combination, next_question_set_id) VALUES (2, N'B,C,D,E', 2);

COMMIT;


/* ===== Questions(question_set_id) -> question_sets(id) ===== */
DECLARE @fkQ sysname;

SELECT TOP 1 @fkQ = fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c  ON c.object_id  = fk.parent_object_id     AND c.column_id  = fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fk.referenced_object_id  AND rc.column_id = fkc.referenced_column_id
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id)    = 'dbo'
  AND OBJECT_NAME(fk.parent_object_id)           = 'Questions'
  AND OBJECT_SCHEMA_NAME(fk.referenced_object_id)= 'dbo'
  AND OBJECT_NAME(fk.referenced_object_id)       = 'question_sets'
  AND c.name  = 'question_set_id'
  AND rc.name = 'id';

IF @fkQ IS NOT NULL
BEGIN
    PRINT 'Dropping FK: ' + @fkQ;
    EXEC('ALTER TABLE dbo.Questions DROP CONSTRAINT [' + @fkQ + ']');
END
ELSE
BEGIN
    PRINT 'No FK found for Questions(question_set_id) -> question_sets(id)';
END;

-- Tạo lại với CASCADE
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = 'FK_Questions_QuestionSets' AND parent_object_id = OBJECT_ID('dbo.Questions')
)
BEGIN
    ALTER TABLE dbo.Questions
    ADD CONSTRAINT FK_Questions_QuestionSets
    FOREIGN KEY (question_set_id)
        REFERENCES dbo.question_sets(id)
        ON DELETE CASCADE;
    PRINT 'Created FK_Questions_QuestionSets with ON DELETE CASCADE';
END
ELSE
BEGIN
    PRINT 'FK_Questions_QuestionSets already exists';
END;

/* ===== Answers(question_id) -> Questions(id) ===== */
DECLARE @fkA sysname;

SELECT TOP 1 @fkA = fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c  ON c.object_id  = fk.parent_object_id     AND c.column_id  = fkc.parent_column_id
JOIN sys.columns rc ON rc.object_id = fk.referenced_object_id  AND rc.column_id = fkc.referenced_column_id
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id)    = 'dbo'
  AND OBJECT_NAME(fk.parent_object_id)           = 'Answers'
  AND OBJECT_SCHEMA_NAME(fk.referenced_object_id)= 'dbo'
  AND OBJECT_NAME(fk.referenced_object_id)       = 'Questions'
  AND c.name  = 'question_id'
  AND rc.name = 'id';

IF @fkA IS NOT NULL
BEGIN
    PRINT 'Dropping FK: ' + @fkA;
    EXEC('ALTER TABLE dbo.Answers DROP CONSTRAINT [' + @fkA + ']');
END
ELSE
BEGIN
    PRINT 'No FK found for Answers(question_id) -> Questions(id)';
END;

-- Tạo lại với CASCADE
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = 'FK_Answers_Questions' AND parent_object_id = OBJECT_ID('dbo.Answers')
)
BEGIN
    ALTER TABLE dbo.Answers
    ADD CONSTRAINT FK_Answers_Questions
    FOREIGN KEY (question_id)
        REFERENCES dbo.Questions(id)
        ON DELETE CASCADE;
    PRINT 'Created FK_Answers_Questions with ON DELETE CASCADE';
END
ELSE
BEGIN
    PRINT 'FK_Answers_Questions already exists';
END;


BEGIN TRAN;
SET NOCOUNT ON;

INSERT INTO dbo.Experts(full_name, specialization, contact_info)
VALUES (N'ThS. Nguyễn Mai Linh', N'Tâm lý học', N'mail@example.com');

SELECT SCOPE_IDENTITY() AS new_expert_id;

------------------------------------------------------------
-- A) ENSURE CATEGORIES EXIST (by slug)
------------------------------------------------------------
DECLARE @CatStressId INT, @CatMeditId INT;

IF NOT EXISTS (SELECT 1 FROM dbo.ContentCategories WHERE slug = N'quan-ly-stress')
BEGIN
  INSERT INTO dbo.ContentCategories(name, slug, description, is_active)
  VALUES (N'Quản lý stress', N'quan-ly-stress', N'Danh mục về stress', 1);
END
SELECT @CatStressId = category_id FROM dbo.ContentCategories WHERE slug = N'quan-ly-stress';

IF NOT EXISTS (SELECT 1 FROM dbo.ContentCategories WHERE slug = N'thien-dinh')
BEGIN
  INSERT INTO dbo.ContentCategories(name, slug, description, is_active)
  VALUES (N'Thiền định', N'thien-dinh', N'Danh mục về thiền', 1);
END
SELECT @CatMeditId = category_id FROM dbo.ContentCategories WHERE slug = N'thien-dinh';

------------------------------------------------------------
-- B) ENSURE TAGS EXIST (by slug)
------------------------------------------------------------
DECLARE @TagStressId INT, @TagMeditId INT, @TagBreathId INT;

IF NOT EXISTS (SELECT 1 FROM dbo.Tags WHERE slug = N'stress')
BEGIN
  INSERT INTO dbo.Tags(name, slug) VALUES (N'stress', N'stress');
END
SELECT @TagStressId = tag_id FROM dbo.Tags WHERE slug = N'stress';

IF NOT EXISTS (SELECT 1 FROM dbo.Tags WHERE slug = N'meditation')
BEGIN
  INSERT INTO dbo.Tags(name, slug) VALUES (N'meditation', N'meditation');
END
SELECT @TagMeditId = tag_id FROM dbo.Tags WHERE slug = N'meditation';

IF NOT EXISTS (SELECT 1 FROM dbo.Tags WHERE slug = N'breathing')
BEGIN
  INSERT INTO dbo.Tags(name, slug) VALUES (N'breathing', N'breathing');
END
SELECT @TagBreathId = tag_id FROM dbo.Tags WHERE slug = N'breathing';

------------------------------------------------------------
-- C) PICK UP TO 3 EXISTING USERS (for likes/views)
------------------------------------------------------------
DECLARE @U1 INT = NULL, @U2 INT = NULL, @U3 INT = NULL;

;WITH u AS (
  SELECT TOP 3 user_id, ROW_NUMBER() OVER (ORDER BY user_id) rn
  FROM dbo.Users
  ORDER BY user_id
)
SELECT
  @U1 = MAX(CASE WHEN rn=1 THEN user_id END),
  @U2 = MAX(CASE WHEN rn=2 THEN user_id END),
  @U3 = MAX(CASE WHEN rn=3 THEN user_id END)
FROM u;

------------------------------------------------------------
-- D) INSERT VIDEO #1 (expert_id = NULL cho chắc)
------------------------------------------------------------
INSERT INTO dbo.Videos (
  expert_id, title, description, thumbnail_url, video_url,
  duration_seconds, is_short, is_premium, status, published_at
)
VALUES (
  NULL,
  N'Kỹ thuật thở giảm stress trong 2 phút',
  N'Video ngắn hướng dẫn kỹ thuật thở giúp giảm căng thẳng nhanh.',
  N'https://cdn.example.com/thumbs/breathing.jpg',
  N'https://cdn.example.com/videos/breathing.mp4',
  120, 1, 1, N'published', '2025-01-12'
);

DECLARE @VideoId1 INT = SCOPE_IDENTITY();
IF @VideoId1 IS NULL
BEGIN
  ROLLBACK;
  THROW 50001, 'Insert Videos #1 failed => @VideoId1 is NULL', 1;
END

-- Categories
INSERT INTO dbo.VideoCategories(video_id, category_id)
VALUES (@VideoId1, @CatStressId), (@VideoId1, @CatMeditId);

-- Tags
INSERT INTO dbo.VideoTags(video_id, tag_id)
VALUES (@VideoId1, @TagStressId), (@VideoId1, @TagBreathId);

-- Stats (đặt số mẫu)
INSERT INTO dbo.VideoStats(video_id, view_count, like_count)
VALUES (@VideoId1, 0, 0);

-- Likes (chỉ insert nếu có user)
IF @U1 IS NOT NULL INSERT INTO dbo.VideoLikes(user_id, video_id) VALUES (@U1, @VideoId1);
IF @U2 IS NOT NULL INSERT INTO dbo.VideoLikes(user_id, video_id) VALUES (@U2, @VideoId1);
IF @U3 IS NOT NULL INSERT INTO dbo.VideoLikes(user_id, video_id) VALUES (@U3, @VideoId1);

-- Views (user + guest)
IF @U1 IS NOT NULL INSERT INTO dbo.VideoViews(user_id, video_id, ip_hash) VALUES (@U1, @VideoId1, N'ip_u1_v1');
IF @U2 IS NOT NULL INSERT INTO dbo.VideoViews(user_id, video_id, ip_hash) VALUES (@U2, @VideoId1, N'ip_u2_v1');
IF @U3 IS NOT NULL INSERT INTO dbo.VideoViews(user_id, video_id, ip_hash) VALUES (@U3, @VideoId1, N'ip_u3_v1');

INSERT INTO dbo.VideoViews(user_id, video_id, ip_hash)
VALUES (NULL, @VideoId1, N'ip_guest_1'), (NULL, @VideoId1, N'ip_guest_2');

------------------------------------------------------------
-- E) INSERT VIDEO #2
------------------------------------------------------------
INSERT INTO dbo.Videos (
  expert_id, title, description, thumbnail_url, video_url,
  duration_seconds, is_short, is_premium, status, published_at
)
VALUES (
  NULL,
  N'Thiền định căn bản cho người mới bắt đầu',
  N'Bài hướng dẫn thiền định căn bản giúp ngủ ngon và giảm lo âu.',
  N'https://cdn.example.com/thumbs/meditation.jpg',
  N'https://cdn.example.com/videos/meditation.mp4',
  900, 0, 0, N'published', '2025-01-15'
);

DECLARE @VideoId2 INT = SCOPE_IDENTITY();
IF @VideoId2 IS NULL
BEGIN
  ROLLBACK;
  THROW 50002, 'Insert Videos #2 failed => @VideoId2 is NULL', 1;
END

-- Categories
INSERT INTO dbo.VideoCategories(video_id, category_id)
VALUES (@VideoId2, @CatMeditId);

-- Tags
INSERT INTO dbo.VideoTags(video_id, tag_id)
VALUES (@VideoId2, @TagMeditId);

-- Stats
INSERT INTO dbo.VideoStats(video_id, view_count, like_count)
VALUES (@VideoId2, 0, 0);

-- Likes
IF @U1 IS NOT NULL INSERT INTO dbo.VideoLikes(user_id, video_id) VALUES (@U1, @VideoId2);
IF @U2 IS NOT NULL INSERT INTO dbo.VideoLikes(user_id, video_id) VALUES (@U2, @VideoId2);

-- Views
IF @U1 IS NOT NULL INSERT INTO dbo.VideoViews(user_id, video_id, ip_hash) VALUES (@U1, @VideoId2, N'ip_u1_v2');
IF @U2 IS NOT NULL INSERT INTO dbo.VideoViews(user_id, video_id, ip_hash) VALUES (@U2, @VideoId2, N'ip_u2_v2');

INSERT INTO dbo.VideoViews(user_id, video_id, ip_hash)
VALUES (NULL, @VideoId2, N'ip_guest_3'), (NULL, @VideoId2, N'ip_guest_4');

------------------------------------------------------------
-- F) SYNC STATS = COUNT(VIEWS/LIKES) (khớp tuyệt đối)
------------------------------------------------------------
UPDATE s
SET
  s.view_count = v.cnt,
  s.like_count = l.cnt,
  s.updated_at = SYSUTCDATETIME()
FROM dbo.VideoStats s
OUTER APPLY (SELECT COUNT(*) cnt FROM dbo.VideoViews vv WHERE vv.video_id = s.video_id) v
OUTER APPLY (SELECT COUNT(*) cnt FROM dbo.VideoLikes vl WHERE vl.video_id = s.video_id) l
WHERE s.video_id IN (@VideoId1, @VideoId2);

COMMIT;

-- Xem kết quả Videos
SELECT v.video_id, v.title, v.status, s.view_count, s.like_count
FROM dbo.Videos v
LEFT JOIN dbo.VideoStats s ON s.video_id = v.video_id
WHERE v.video_id IN (@VideoId1, @VideoId2);


-- ============================================================
-- INSERT DATA CHO BÀI VIẾT (POSTS) - 3 BÀI VIẾT MẪU
-- ============================================================

BEGIN TRAN;
SET NOCOUNT ON;

------------------------------------------------------------
-- BÀI VIẾT #1: Hướng dẫn quản lý stress
------------------------------------------------------------
INSERT INTO dbo.Posts (
  expert_id, title, summary, content, thumbnail_url,
  is_premium, status, published_at
)
VALUES (
  NULL,
  N'10 Cách Quản Lý Stress Hiệu Quả Cho Phụ Nữ Bận Rộn',
  N'Khám phá những phương pháp đơn giản giúp bạn giảm căng thẳng và cân bằng cuộc sống.',
  N'<h2>Giới thiệu</h2>
<p>Stress là một phần không thể tránh khỏi trong cuộc sống hiện đại. Đặc biệt với phụ nữ, việc cân bằng giữa công việc, gia đình và bản thân có thể gây ra nhiều áp lực.</p>

<h2>1. Thực hành kỹ thuật thở sâu</h2>
<p>Hít vào trong 4 giây, giữ 4 giây, thở ra trong 6 giây. Lặp lại 5-10 lần mỗi khi cảm thấy căng thẳng.</p>

<h2>2. Dành thời gian cho bản thân</h2>
<p>Mỗi ngày hãy dành ít nhất 15 phút để làm điều bạn yêu thích.</p>

<h2>3. Tập thể dục đều đặn</h2>
<p>Vận động giúp giải phóng endorphin - hormone hạnh phúc tự nhiên của cơ thể.</p>

<h2>4. Ngủ đủ giấc</h2>
<p>Đảm bảo ngủ 7-8 tiếng mỗi đêm để cơ thể phục hồi.</p>

<h2>5. Hạn chế caffeine</h2>
<p>Caffeine có thể làm tăng cảm giác lo âu và căng thẳng.</p>',
  N'https://picsum.photos/400/300?random=101',
  0,
  N'published',
  '2025-01-10'
);

DECLARE @PostId1 INT = SCOPE_IDENTITY();

-- PostCategories
INSERT INTO dbo.PostCategories(post_id, category_id)
SELECT @PostId1, category_id FROM dbo.ContentCategories WHERE slug = N'quan-ly-stress';

-- PostTags
INSERT INTO dbo.PostTags(post_id, tag_id)
SELECT @PostId1, tag_id FROM dbo.Tags WHERE slug IN (N'stress', N'breathing');

-- PostStats
INSERT INTO dbo.PostStats(post_id, view_count, like_count)
VALUES (@PostId1, 0, 0);

-- PostLikes (từ user hiện có)
INSERT INTO dbo.PostLikes(user_id, post_id)
SELECT TOP 2 user_id, @PostId1 FROM dbo.Users ORDER BY user_id;

-- PostViews
INSERT INTO dbo.PostViews(user_id, post_id, ip_hash)
SELECT TOP 2 user_id, @PostId1, CONCAT(N'ip_u', user_id, N'_p1') FROM dbo.Users ORDER BY user_id;
INSERT INTO dbo.PostViews(user_id, post_id, ip_hash) VALUES (NULL, @PostId1, N'ip_guest_p1');

------------------------------------------------------------
-- BÀI VIẾT #2: Hướng dẫn thiền định
------------------------------------------------------------
INSERT INTO dbo.Posts (
  expert_id, title, summary, content, thumbnail_url,
  is_premium, status, published_at
)
VALUES (
  NULL,
  N'Thiền Định Cho Người Mới Bắt Đầu: Hướng Dẫn Từng Bước',
  N'Bài viết chi tiết về cách thiền định hiệu quả dành cho người chưa có kinh nghiệm.',
  N'<h2>Thiền định là gì?</h2>
<p>Thiền định là thực hành tập trung tâm trí để đạt được sự bình an và nhận thức rõ ràng hơn.</p>

<h2>Lợi ích của thiền định</h2>
<ul>
  <li>Giảm căng thẳng và lo âu</li>
  <li>Cải thiện tập trung</li>
  <li>Tăng cường sức khỏe tinh thần</li>
  <li>Hỗ trợ điều hòa kinh nguyệt</li>
</ul>

<h2>Cách thực hành</h2>
<h3>Bước 1: Chọn không gian yên tĩnh</h3>
<p>Tìm một nơi yên tĩnh, thoải mái nơi bạn không bị làm phiền.</p>

<h3>Bước 2: Ngồi thoải mái</h3>
<p>Có thể ngồi trên ghế hoặc trên sàn với tư thế thoải mái.</p>

<h3>Bước 3: Tập trung vào hơi thở</h3>
<p>Nhắm mắt và chú ý đến hơi thở tự nhiên của bạn. Không cần thay đổi gì, chỉ quan sát.</p>

<h3>Bước 4: Duy trì 5-10 phút</h3>
<p>Bắt đầu với 5 phút mỗi ngày, sau đó tăng dần thời gian.</p>',
  N'https://picsum.photos/400/300?random=102',
  0,
  N'published',
  '2025-01-11'
);

DECLARE @PostId2 INT = SCOPE_IDENTITY();

-- PostCategories
INSERT INTO dbo.PostCategories(post_id, category_id)
SELECT @PostId2, category_id FROM dbo.ContentCategories WHERE slug = N'thien-dinh';

-- PostTags
INSERT INTO dbo.PostTags(post_id, tag_id)
SELECT @PostId2, tag_id FROM dbo.Tags WHERE slug IN (N'meditation', N'breathing');

-- PostStats
INSERT INTO dbo.PostStats(post_id, view_count, like_count)
VALUES (@PostId2, 0, 0);

-- PostLikes
INSERT INTO dbo.PostLikes(user_id, post_id)
SELECT TOP 2 user_id, @PostId2 FROM dbo.Users ORDER BY user_id;

-- PostViews
INSERT INTO dbo.PostViews(user_id, post_id, ip_hash)
SELECT TOP 3 user_id, @PostId2, CONCAT(N'ip_u', user_id, N'_p2') FROM dbo.Users ORDER BY user_id;
INSERT INTO dbo.PostViews(user_id, post_id, ip_hash) VALUES (NULL, @PostId2, N'ip_guest_p2');

------------------------------------------------------------
-- BÀI VIẾT #3: Dinh dưỡng và chu kỳ kinh nguyệt (Premium)
------------------------------------------------------------
INSERT INTO dbo.Posts (
  expert_id, title, summary, content, thumbnail_url,
  is_premium, status, published_at
)
VALUES (
  NULL,
  N'Dinh Dưỡng Theo Chu Kỳ Kinh Nguyệt: Ăn Gì Mỗi Giai Đoạn?',
  N'Hướng dẫn chi tiết về chế độ ăn phù hợp với từng giai đoạn trong chu kỳ kinh nguyệt.',
  N'<h2>Tại sao dinh dưỡng quan trọng với chu kỳ?</h2>
<p>Hormone thay đổi theo chu kỳ kinh nguyệt, và chế độ ăn phù hợp có thể giúp giảm các triệu chứng khó chịu.</p>

<h2>Giai đoạn 1: Ngày hành kinh (ngày 1-5)</h2>
<p><strong>Nên ăn:</strong> Thực phẩm giàu sắt (thịt đỏ, rau xanh đậm), omega-3 (cá hồi, hạt chia)</p>
<p><strong>Hạn chế:</strong> Caffeine, muối, đồ chiên rán</p>

<h2>Giai đoạn 2: Sau hành kinh (ngày 6-14)</h2>
<p><strong>Nên ăn:</strong> Protein nạc, rau củ tươi, ngũ cốc nguyên hạt</p>
<p>Đây là thời điểm năng lượng cao, phù hợp để tập luyện cường độ cao.</p>

<h2>Giai đoạn 3: Rụng trứng (ngày 14-17)</h2>
<p><strong>Nên ăn:</strong> Rau cruciferous (bông cải, cải xoăn), trái cây tươi</p>
<p>Estrogen đạt đỉnh, cơ thể cần chất xơ để chuyển hóa hormone.</p>

<h2>Giai đoạn 4: Trước hành kinh (ngày 18-28)</h2>
<p><strong>Nên ăn:</strong> Carbs phức hợp (khoai lang, yến mạch), magie (sô cô la đen, hạnh nhân)</p>
<p><strong>Hạn chế:</strong> Đường, rượu bia để giảm triệu chứng PMS.</p>',
  N'https://picsum.photos/400/300?random=103',
  1, -- Premium content
  N'published',
  '2025-01-12'
);

DECLARE @PostId3 INT = SCOPE_IDENTITY();

-- PostCategories (cả 2 category)
INSERT INTO dbo.PostCategories(post_id, category_id)
SELECT @PostId3, category_id FROM dbo.ContentCategories WHERE slug IN (N'quan-ly-stress', N'thien-dinh');

-- PostTags
INSERT INTO dbo.PostTags(post_id, tag_id)
SELECT @PostId3, tag_id FROM dbo.Tags WHERE slug = N'stress';

-- PostStats
INSERT INTO dbo.PostStats(post_id, view_count, like_count)
VALUES (@PostId3, 0, 0);

-- PostLikes
INSERT INTO dbo.PostLikes(user_id, post_id)
SELECT TOP 3 user_id, @PostId3 FROM dbo.Users ORDER BY user_id;

-- PostViews
INSERT INTO dbo.PostViews(user_id, post_id, ip_hash)
SELECT TOP 3 user_id, @PostId3, CONCAT(N'ip_u', user_id, N'_p3') FROM dbo.Users ORDER BY user_id;
INSERT INTO dbo.PostViews(user_id, post_id, ip_hash) VALUES (NULL, @PostId3, N'ip_guest_p3_1');
INSERT INTO dbo.PostViews(user_id, post_id, ip_hash) VALUES (NULL, @PostId3, N'ip_guest_p3_2');

------------------------------------------------------------
-- SYNC STATS = COUNT(VIEWS/LIKES) cho Posts
------------------------------------------------------------
UPDATE s
SET
  s.view_count = v.cnt,
  s.like_count = l.cnt,
  s.updated_at = SYSUTCDATETIME()
FROM dbo.PostStats s
OUTER APPLY (SELECT COUNT(*) cnt FROM dbo.PostViews pv WHERE pv.post_id = s.post_id) v
OUTER APPLY (SELECT COUNT(*) cnt FROM dbo.PostLikes pl WHERE pl.post_id = s.post_id) l
WHERE s.post_id IN (@PostId1, @PostId2, @PostId3);

------------------------------------------------------------
-- UPDATE THUMBNAIL URLs TO PICSUM cho Videos
------------------------------------------------------------
UPDATE dbo.Videos
SET thumbnail_url = CONCAT('https://picsum.photos/400/300?random=', video_id);

COMMIT;

-- Xem kết quả Posts
SELECT p.post_id, p.title, p.status, p.is_premium, s.view_count, s.like_count
FROM dbo.Posts p
LEFT JOIN dbo.PostStats s ON s.post_id = p.post_id
WHERE p.post_id IN (@PostId1, @PostId2, @PostId3);
