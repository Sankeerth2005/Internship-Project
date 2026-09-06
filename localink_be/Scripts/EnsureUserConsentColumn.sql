-- Idempotent: persist mandatory User Agreement consent on the account (users table).
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.users')
      AND name = N'consent_accepted'
)
BEGIN
    ALTER TABLE dbo.users
        ADD consent_accepted BIT NOT NULL
            CONSTRAINT DF_users_consent_accepted DEFAULT (0);
END
GO
