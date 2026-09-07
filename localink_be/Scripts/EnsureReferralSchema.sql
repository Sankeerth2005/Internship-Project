-- Idempotent referral schema for VocalForSanatan.
-- Safe for production: additive only — no DROP, no data deletion, no destructive ALTER.
-- Run on the MANAGER SQL Server (the DB the API uses), or rely on Program.cs startup ensure.
--
-- Extends dbo.users and creates dbo.referral_history for audit / one-referrer uniqueness.
-- Referral codes for existing users stay NULL until Phase 3 backfill (app-generated).

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-----------------------------------------------------------------------------
-- 1) users.referral_code — permanent unique share code (nullable until backfill)
-----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.users')
      AND name = N'referral_code'
)
BEGIN
    ALTER TABLE dbo.users
        ADD referral_code NVARCHAR(16) NULL;
END
GO

-----------------------------------------------------------------------------
-- 2) users.referred_by_user_id — immutable once set (enforced in app + unique history)
-----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.users')
      AND name = N'referred_by_user_id'
)
BEGIN
    ALTER TABLE dbo.users
        ADD referred_by_user_id BIGINT NULL;
END
GO

-----------------------------------------------------------------------------
-- 3) users.successful_referral_count — denormalized counter (default 0)
-----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.users')
      AND name = N'successful_referral_count'
)
BEGIN
    ALTER TABLE dbo.users
        ADD successful_referral_count INT NOT NULL
            CONSTRAINT DF_users_successful_referral_count DEFAULT (0);
END
GO

-----------------------------------------------------------------------------
-- 4) Self-referral CHECK (nullable referrer allowed; cannot equal own user_id)
-----------------------------------------------------------------------------
IF COL_LENGTH(N'dbo.users', N'referred_by_user_id') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.check_constraints
        WHERE name = N'CK_users_no_self_referral'
          AND parent_object_id = OBJECT_ID(N'dbo.users')
   )
BEGIN
    ALTER TABLE dbo.users
        ADD CONSTRAINT CK_users_no_self_referral
        CHECK (referred_by_user_id IS NULL OR referred_by_user_id <> user_id);
END
GO

-----------------------------------------------------------------------------
-- 5) Non-negative count CHECK
-----------------------------------------------------------------------------
IF COL_LENGTH(N'dbo.users', N'successful_referral_count') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.check_constraints
        WHERE name = N'CK_users_successful_referral_count_nonneg'
          AND parent_object_id = OBJECT_ID(N'dbo.users')
   )
BEGIN
    ALTER TABLE dbo.users
        ADD CONSTRAINT CK_users_successful_referral_count_nonneg
        CHECK (successful_referral_count >= 0);
END
GO

-----------------------------------------------------------------------------
-- 6) FK: referred_by_user_id → users(user_id) — NO ACTION (avoid cycles/cascade)
-----------------------------------------------------------------------------
IF COL_LENGTH(N'dbo.users', N'referred_by_user_id') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys
        WHERE name = N'FK_users_referred_by_user'
   )
BEGIN
    ALTER TABLE dbo.users
        ADD CONSTRAINT FK_users_referred_by_user
        FOREIGN KEY (referred_by_user_id)
        REFERENCES dbo.users (user_id);
END
GO

-----------------------------------------------------------------------------
-- 7) Filtered unique index on referral_code (multiple NULLs allowed for legacy)
-----------------------------------------------------------------------------
IF COL_LENGTH(N'dbo.users', N'referral_code') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_users_referral_code'
          AND object_id = OBJECT_ID(N'dbo.users')
   )
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_users_referral_code
        ON dbo.users (referral_code)
        WHERE referral_code IS NOT NULL;
END
GO

-----------------------------------------------------------------------------
-- 8) Index on referred_by_user_id (lookups / admin)
-----------------------------------------------------------------------------
IF COL_LENGTH(N'dbo.users', N'referred_by_user_id') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_users_referred_by_user_id'
          AND object_id = OBJECT_ID(N'dbo.users')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_users_referred_by_user_id
        ON dbo.users (referred_by_user_id)
        WHERE referred_by_user_id IS NOT NULL;
END
GO

-----------------------------------------------------------------------------
-- 9) referral_history — source of truth for verified registration attributions
-----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.referral_history', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.referral_history (
        id                BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_referral_history PRIMARY KEY,
        referrer_user_id  BIGINT NOT NULL,
        referred_user_id  BIGINT NOT NULL,
        referral_code     NVARCHAR(16) NOT NULL,
        created_at        DATETIME2 NOT NULL
            CONSTRAINT DF_referral_history_created_at DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT FK_referral_history_referrer
            FOREIGN KEY (referrer_user_id) REFERENCES dbo.users (user_id),
        CONSTRAINT FK_referral_history_referred
            FOREIGN KEY (referred_user_id) REFERENCES dbo.users (user_id),

        -- One user can only ever be referred once (idempotent + anti-abuse)
        CONSTRAINT UQ_referral_history_referred_user
            UNIQUE (referred_user_id),

        CONSTRAINT CK_referral_history_no_self
            CHECK (referrer_user_id <> referred_user_id)
    );
END
GO

-----------------------------------------------------------------------------
-- 10) Index: list successful referrals for a referrer
-----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.referral_history', N'U') IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE name = N'IX_referral_history_referrer_user_id'
          AND object_id = OBJECT_ID(N'dbo.referral_history')
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_referral_history_referrer_user_id
        ON dbo.referral_history (referrer_user_id)
        INCLUDE (referred_user_id, referral_code, created_at);
END
GO

PRINT 'EnsureReferralSchema completed (idempotent).';
GO
