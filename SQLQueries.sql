-- Create Queries:

CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Month INT,
    Day INT,
    DayOfWeek INT,
    MonthName NVARCHAR(10),
    Quarter INT
);

CREATE TABLE DimCountry (
    CountryKey INT IDENTITY(1,1) PRIMARY KEY,
    CountryName NVARCHAR(100)
);

CREATE TABLE DimCategory (
    CategoryKey INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50)
);

CREATE TABLE DimChannel (
    ChannelKey INT IDENTITY(1,1) PRIMARY KEY,
    ChannelID NVARCHAR(50),
    ChannelPublishedDate DATETIME,
    ChannelCountry NVARCHAR(100),
    HaveHiddenSubscribers BIT,
    LastModifiedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE DimVideo (
    VideoKey INT IDENTITY(1,1) PRIMARY KEY,
    VideoID NVARCHAR(20),
    VideoDuration DECIMAL(10,2),
    VideoDimension NVARCHAR(10),
    VideoDefinition NVARCHAR(10),
    VideoLicensedContent BIT,
    LastModifiedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE FactVideoStats (
    VideoStatsKey INT IDENTITY(1,1) PRIMARY KEY,
    VideoKey INT FOREIGN KEY REFERENCES DimVideo(VideoKey),
    ChannelKey INT FOREIGN KEY REFERENCES DimChannel(ChannelKey),
    DateKey INT FOREIGN KEY REFERENCES DimDate(DateKey),
    CountryKey INT FOREIGN KEY REFERENCES DimCountry(CountryKey),
    CategoryKey INT FOREIGN KEY REFERENCES DimCategory(CategoryKey),
    ViewCount BIGINT,
    LikeCount BIGINT,
    CommentCount INT,
    ChannelViewCount BIGINT,
    ChannelSubscriberCount INT,
    ChannelVideoCount INT,
    TrendingDate DATE,
    LastModifiedDate DATETIME DEFAULT GETDATE()
);

-- Create indexes for better performance
CREATE NONCLUSTERED INDEX IX_FactVideoStats_DateKey ON FactVideoStats(DateKey);
CREATE NONCLUSTERED INDEX IX_FactVideoStats_VideoKey ON FactVideoStats(VideoKey);
CREATE NONCLUSTERED INDEX IX_FactVideoStats_ChannelKey ON FactVideoStats(ChannelKey);
CREATE NONCLUSTERED INDEX IX_FactVideoStats_CountryKey ON FactVideoStats(CountryKey);
CREATE NONCLUSTERED INDEX IX_FactVideoStats_CategoryKey ON FactVideoStats(CategoryKey);


-- Insert Queries:

INSERT INTO DimDate (DateKey, FullDate, Year, Month, Day, DayOfWeek, MonthName, Quarter)
SELECT DISTINCT
    CONVERT(INT, CONVERT(VARCHAR, video_published_at, 112)),
    CAST(video_published_at AS DATE),
    YEAR(video_published_at),
    MONTH(video_published_at),
    DAY(video_published_at),
    DATEPART(WEEKDAY, video_published_at),
    DATENAME(MONTH, video_published_at),
    DATEPART(QUARTER, video_published_at)
FROM cleaned_youtube_trending_videos;

INSERT INTO DimCountry (CountryName)
SELECT DISTINCT video_trending_country
FROM cleaned_youtube_trending_videos
WHERE video_trending_country IS NOT NULL
UNION
SELECT DISTINCT channel_country
FROM cleaned_youtube_trending_videos
WHERE channel_country IS NOT NULL;

INSERT INTO DimCategory (CategoryName)
SELECT DISTINCT video_category_id
FROM cleaned_youtube_trending_videos
WHERE video_category_id IS NOT NULL;

INSERT INTO DimChannel (ChannelID, ChannelPublishedDate, ChannelCountry, HaveHiddenSubscribers)
SELECT DISTINCT
    channel_id,
    channel_published_at,
    channel_country,
    channel_have_hidden_subscribers
FROM cleaned_youtube_trending_videos;

INSERT INTO DimVideo (VideoID, VideoDuration, VideoDimension, VideoDefinition, VideoLicensedContent)
SELECT DISTINCT
    video_id,
    video_duration,
    video_dimension,
    video_definition,
    video_licensed_content
FROM cleaned_youtube_trending_videos;

INSERT INTO FactVideoStats (
    VideoKey,
    ChannelKey,
    DateKey,
    CountryKey,
    CategoryKey,
    ViewCount,
    LikeCount,
    CommentCount,
    ChannelViewCount,
    ChannelSubscriberCount,
    ChannelVideoCount,
    TrendingDate
)
SELECT
    v.VideoKey,
    c.ChannelKey,
    d.DateKey,
    co.CountryKey,
    cat.CategoryKey,
    ytv.video_view_count,
    ytv.video_like_count,
    ytv.video_comment_count,
    ytv.channel_view_count,
    ytv.channel_subscriber_count,
    ytv.channel_video_count,
    ytv.video_trending_date
FROM cleaned_youtube_trending_videos ytv
JOIN DimVideo v ON ytv.video_id = v.VideoID
JOIN DimChannel c ON ytv.channel_id = c.ChannelID
JOIN DimDate d ON CONVERT(INT, CONVERT(VARCHAR, ytv.video_published_at, 112)) = d.DateKey
JOIN DimCountry co ON ytv.video_trending_country = co.CountryName
JOIN DimCategory cat ON ytv.video_category_id = cat.CategoryName;
