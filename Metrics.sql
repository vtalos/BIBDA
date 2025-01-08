USE YouTube;

-- 1. Average Video Duration by Category
SELECT 
    DC.CategoryName,
    AVG(DV.VideoDuration) AS AverageDuration
FROM 
    DimCategory DC
JOIN 
    FactVideoStats FVS ON DC.CategoryKey = FVS.CategoryKey
JOIN 
    DimVideo DV ON FVS.VideoKey = DV.VideoKey
GROUP BY 
    DC.CategoryName
ORDER BY 
    AverageDuration DESC;

-- 2. Top 5 Countries with the Most Comments
SELECT TOP 5
    DC.CountryName,
    SUM(FVS.CommentCount) AS TotalComments
FROM 
    DimCountry DC
JOIN 
    FactVideoStats FVS ON DC.CountryKey = FVS.CountryKey
GROUP BY 
    DC.CountryName
ORDER BY 
    TotalComments DESC

-- 3. Average Number of Days a Video is Trending
WITH TrendingDuration AS (
    SELECT 
        VideoKey,
        COUNT(DISTINCT TrendingDate) AS TrendingDays
    FROM 
        FactVideoStats
    WHERE 
        TrendingDate IS NOT NULL
    GROUP BY 
        VideoKey
)
SELECT 
    AVG(TrendingDays) AS AverageTrendingDays
FROM 
    TrendingDuration;

-- 4. Percentage of Licensed Content Videos
SELECT 
    (CAST(SUM(CASE WHEN DV.VideoLicensedContent = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100 AS LicensedContentPercentage
FROM 
    DimVideo DV;

-- 5. Top Categories with the Most Channel Videos
SELECT 
    DC.CategoryName,
    SUM(FVS.ChannelVideoCount) AS TotalChannelVideos
FROM 
    DimCategory DC
JOIN 
    FactVideoStats FVS ON DC.CategoryKey = FVS.CategoryKey
GROUP BY 
    DC.CategoryName
ORDER BY 
    TotalChannelVideos DESC;

-- 6. Average Likes Per Category
SELECT
    DC.CategoryName,
    AVG(FVS.LikeCount) AS AverageLikes
FROM 
    DimCategory DC
JOIN 
    FactVideoStats FVS ON DC.CategoryKey = FVS.CategoryKey
GROUP BY 
    DC.CategoryName
ORDER BY 
    AverageLikes DESC;

-- 7. Most Active Day of the Week for Trending Videos
SELECT 
    DD.DayOfWeek,
    COUNT(DISTINCT FVS.VideoKey) AS TrendingVideos
FROM 
    DimDate DD
JOIN 
    FactVideoStats FVS ON DD.DateKey = FVS.DateKey
WHERE 
    FVS.TrendingDate IS NOT NULL
GROUP BY 
    DD.DayOfWeek
ORDER BY 
    TrendingVideos DESC;

-- 8. Percentage of Videos in Each Definition Type
SELECT 
    DV.VideoDefinition,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS Percentage
FROM 
    DimVideo DV
GROUP BY 
    DV.VideoDefinition;

-- 9. Maximum Subscriber Count
SELECT
    MAX(FVS.ChannelSubscriberCount) AS MaxSubscribers
FROM 
    FactVideoStats FVS;

-- 10. Maximum Like Count
SELECT 
    MAX(FVS.LikeCount) AS MaxLikes
FROM 
    FactVideoStats FVS;