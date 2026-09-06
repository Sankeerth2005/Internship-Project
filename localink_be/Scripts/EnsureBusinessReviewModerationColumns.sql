-- Idempotent: align review moderation columns with backend (snake_case).
-- Handles manager DBs that already have PascalCase IsFlagged / ModerationReason.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- is_flagged: rename PascalCase if present, otherwise add
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews')
      AND name = N'IsFlagged'
)
AND NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews')
      AND name = N'is_flagged'
)
BEGIN
    EXEC sp_rename N'dbo.business_reviews.IsFlagged', N'is_flagged', N'COLUMN';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews')
      AND name = N'is_flagged'
)
BEGIN
    ALTER TABLE dbo.business_reviews
        ADD is_flagged BIT NOT NULL
            CONSTRAINT DF_business_reviews_is_flagged DEFAULT (0);
END
GO

-- moderation_reason: rename PascalCase if present, otherwise add
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews')
      AND name = N'ModerationReason'
)
AND NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews')
      AND name = N'moderation_reason'
)
BEGIN
    EXEC sp_rename N'dbo.business_reviews.ModerationReason', N'moderation_reason', N'COLUMN';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.business_reviews')
      AND name = N'moderation_reason'
)
BEGIN
    ALTER TABLE dbo.business_reviews
        ADD moderation_reason NVARCHAR(500) NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_business_reviews_is_flagged'
      AND object_id = OBJECT_ID(N'dbo.business_reviews')
)
BEGIN
    CREATE INDEX IX_business_reviews_is_flagged
        ON dbo.business_reviews(is_flagged)
        WHERE is_flagged = 1;
END
GO
