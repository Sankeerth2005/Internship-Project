-- Run on the SAME SQL database the manager API uses
-- (check C:\VocalForSanatan\manager\.env → DB_CONNECTION_STRING / ConnectionStrings).
-- Fixes: Invalid column name 'is_flagged'
-- Safe to re-run.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT 'Database in use: ' + DB_NAME();
PRINT 'Columns on business_reviews before:';
SELECT name FROM sys.columns
WHERE object_id = OBJECT_ID(N'dbo.business_reviews')
  AND name IN (N'IsFlagged', N'is_flagged', N'ModerationReason', N'moderation_reason')
ORDER BY name;
GO

-- Rename PascalCase → snake_case (what the published API queries)
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews') AND name = N'IsFlagged'
)
AND NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews') AND name = N'is_flagged'
)
    EXEC sp_rename N'dbo.business_reviews.IsFlagged', N'is_flagged', N'COLUMN';
GO

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews') AND name = N'ModerationReason'
)
AND NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews') AND name = N'moderation_reason'
)
    EXEC sp_rename N'dbo.business_reviews.ModerationReason', N'moderation_reason', N'COLUMN';
GO

-- If neither casing exists, add snake_case
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews') AND name = N'is_flagged'
)
BEGIN
    ALTER TABLE dbo.business_reviews
        ADD is_flagged BIT NOT NULL
            CONSTRAINT DF_business_reviews_is_flagged DEFAULT (0);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews') AND name = N'moderation_reason'
)
BEGIN
    ALTER TABLE dbo.business_reviews
        ADD moderation_reason NVARCHAR(500) NULL;
END
GO

PRINT 'Columns on business_reviews after:';
SELECT name FROM sys.columns
WHERE object_id = OBJECT_ID(N'dbo.business_reviews')
  AND name IN (N'IsFlagged', N'is_flagged', N'ModerationReason', N'moderation_reason')
ORDER BY name;
GO
