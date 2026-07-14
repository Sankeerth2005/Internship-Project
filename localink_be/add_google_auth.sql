IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[users]') AND name = N'google_id'
)
BEGIN
    ALTER TABLE [users] ADD [google_id] nvarchar(450) NULL;
END
GO

ALTER TABLE [users] ALTER COLUMN [password_hash] nvarchar(max) NULL;
GO
