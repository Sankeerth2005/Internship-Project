-- Idempotent business share schema for VocalForSanatan.
-- Additive only — safe for production.

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF OBJECT_ID(N'dbo.business_shares', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.business_shares (
        share_id           BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_business_shares PRIMARY KEY,
        public_token       NVARCHAR(32) NOT NULL,
        share_kind         NVARCHAR(16) NOT NULL
            CONSTRAINT DF_business_shares_kind DEFAULT (N'collection'),
        created_by_user_id BIGINT NOT NULL,
        title              NVARCHAR(120) NULL,
        note               NVARCHAR(500) NULL,
        created_at         DATETIME2 NOT NULL
            CONSTRAINT DF_business_shares_created_at DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_business_shares_created_by
            FOREIGN KEY (created_by_user_id) REFERENCES dbo.users (user_id)
    );
END
GO

IF OBJECT_ID(N'dbo.business_shares', N'U') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_business_shares_public_token'
          AND object_id = OBJECT_ID(N'dbo.business_shares')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_business_shares_public_token
        ON dbo.business_shares (public_token);
END
GO

IF OBJECT_ID(N'dbo.business_shares', N'U') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_business_shares_created_by_user_id'
          AND object_id = OBJECT_ID(N'dbo.business_shares')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_business_shares_created_by_user_id
        ON dbo.business_shares (created_by_user_id, created_at DESC);
END
GO

IF OBJECT_ID(N'dbo.business_share_items', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.business_share_items (
        id          BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_business_share_items PRIMARY KEY,
        share_id    BIGINT NOT NULL,
        business_id BIGINT NOT NULL,
        position    INT NOT NULL,
        CONSTRAINT FK_business_share_items_share
            FOREIGN KEY (share_id) REFERENCES dbo.business_shares (share_id)
            ON DELETE CASCADE,
        CONSTRAINT FK_business_share_items_business
            FOREIGN KEY (business_id) REFERENCES dbo.business (business_id),
        CONSTRAINT UQ_business_share_items_share_business
            UNIQUE (share_id, business_id)
    );
END
GO

IF OBJECT_ID(N'dbo.business_share_items', N'U') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_business_share_items_share_position'
          AND object_id = OBJECT_ID(N'dbo.business_share_items')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_business_share_items_share_position
        ON dbo.business_share_items (share_id, position);
END
GO
