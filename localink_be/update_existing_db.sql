-- =========================================================================
-- DATABASE MIGRATION / UPDATE SCRIPT
-- Vocal for Sanatan - Database Updates
-- Use this script to update an existing database instance.
-- =========================================================================

-- 1. Add Google Auth columns to [users] table
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[users]') AND name = N'google_id'
)
BEGIN
    ALTER TABLE [users] ADD [google_id] nvarchar(450) NULL;
    PRINT 'Added [google_id] column to [users] table.';
END
ELSE
BEGIN
    PRINT '[google_id] column already exists in [users] table.';
END
GO

-- Make password_hash nullable for Google passwordless accounts
ALTER TABLE [users] ALTER COLUMN [password_hash] nvarchar(max) NULL;
PRINT 'Altered [password_hash] in [users] to be NULLable.';
GO


-- 2. Add [image_url] column to [business_reviews] table
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[business_reviews]') AND name = N'image_url'
)
BEGIN
    ALTER TABLE [business_reviews] ADD [image_url] nvarchar(max) NULL;
    PRINT 'Added [image_url] column to [business_reviews] table.';
END
ELSE
BEGIN
    PRINT '[image_url] column already exists in [business_reviews] table.';
END
GO


-- 3. Add Temporary Closure columns to [business] table
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[business]') AND name = N'temporary_closure_reason'
)
BEGIN
    ALTER TABLE [business] ADD [temporary_closure_reason] nvarchar(max) NULL;
    PRINT 'Added [temporary_closure_reason] column to [business] table.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[business]') AND name = N'temporary_closure_days'
)
BEGIN
    ALTER TABLE [business] ADD [temporary_closure_days] int NULL;
    PRINT 'Added [temporary_closure_days] column to [business] table.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[business]') AND name = N'temporary_closure_status'
)
BEGIN
    ALTER TABLE [business] ADD [temporary_closure_status] nvarchar(max) NULL;
    PRINT 'Added [temporary_closure_status] column to [business] table.';
END
GO

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[business]') AND name = N'temporary_closure_reopen_date'
)
BEGIN
    ALTER TABLE [business] ADD [temporary_closure_reopen_date] datetime2 NULL;
    PRINT 'Added [temporary_closure_reopen_date] column to [business] table.';
END
GO

PRINT 'Database migration checks completed successfully!';
GO
