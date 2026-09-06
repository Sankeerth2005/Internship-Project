-- Run on the MANAGER SQL Server (the DB the API actually uses).
-- Reports columns the current backend code expects but may be missing.
-- Safe: SELECT-only. No schema changes.

SET NOCOUNT ON;

DECLARE @Expected TABLE (
    table_name SYSNAME NOT NULL,
    column_name SYSNAME NOT NULL,
    why NVARCHAR(200) NOT NULL
);

INSERT INTO @Expected (table_name, column_name, why) VALUES
-- Review moderation (AI chat search / discovery / admin)
(N'business_reviews', N'is_flagged',          N'AI discovery + review moderation filter'),
(N'business_reviews', N'moderation_reason',   N'Review moderation reason storage'),

(N'users', N'consent_accepted', N'Mandatory User Agreement consent flag'),

-- Users / auth
(N'users', N'auth_provider', N'Google / provider auth'),
(N'users', N'provider_id',   N'Google / provider subject id'),
(N'users', N'created_at',    N'User registration timestamp'),
(N'users', N'updated_at',    N'User profile updates'),
(N'users', N'ProfilePicture',N'Profile image URL (PascalCase column in current schema)'),

-- Photos
(N'business_photos', N'display_order', N'Photo ordering'),
(N'business_photos', N'updated_at',    N'Photo updates'),

-- Geo (contact save path; discovery currently uses lat/lng)
(N'business_contact', N'geo_location', N'Geography point for spatial features'),
(N'business_contact', N'latitude',     N'Distance / map'),
(N'business_contact', N'longitude',    N'Distance / map'),

-- Temporary closure (discovery visibility filter)
(N'business', N'temporary_closure_status',      N'Discovery hide-while-closed filter'),
(N'business', N'temporary_closure_reopen_date', N'Discovery hide-while-closed filter'),

-- Metrics (popular sort)
(N'business_metric', N'views',           N'Most popular sort'),
(N'business_metric', N'favorites_count', N'Most popular sort'),
(N'business_metric', N'contact_clicks',  N'Most popular sort'),

-- Auth tokens
(N'refresh_tokens', N'token_hash', N'Refresh token auth');

PRINT '=== MISSING (code expects these; fix before release) ===';
SELECT
    e.table_name,
    e.column_name,
    e.why
FROM @Expected e
WHERE OBJECT_ID(N'dbo.' + QUOTENAME(e.table_name)) IS NULL
   OR NOT EXISTS (
        SELECT 1
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID(N'dbo.' + QUOTENAME(e.table_name))
          AND c.name = e.column_name COLLATE Latin1_General_BIN
   )
ORDER BY e.table_name, e.column_name;

-- Also surface wrong-casing matches (present under different case)
PRINT '=== WRONG CASING (exists but not exact name code uses) ===';
SELECT
    e.table_name,
    e.column_name AS expected_name,
    c.name AS actual_name,
    e.why
FROM @Expected e
INNER JOIN sys.columns c
    ON c.object_id = OBJECT_ID(N'dbo.' + QUOTENAME(e.table_name))
   AND LOWER(c.name) = LOWER(e.column_name)
   AND c.name <> e.column_name COLLATE Latin1_General_BIN
ORDER BY e.table_name, e.column_name;

PRINT '=== PRESENT (ok) ===';
SELECT
    e.table_name,
    e.column_name
FROM @Expected e
WHERE OBJECT_ID(N'dbo.' + QUOTENAME(e.table_name)) IS NOT NULL
  AND COL_LENGTH(N'dbo.' + e.table_name, e.column_name) IS NOT NULL
ORDER BY e.table_name, e.column_name;

PRINT '=== LEGACY / DUPLICATE CHECK (informational) ===';
SELECT
    c.name AS column_name,
    'business_reviews has both PascalCase and snake_case moderation columns'
        AS note
FROM sys.columns c
WHERE c.object_id = OBJECT_ID(N'dbo.business_reviews')
  AND c.name IN (N'IsFlagged', N'ModerationReason', N'is_flagged', N'moderation_reason')
ORDER BY c.name;

SELECT
    c.name AS column_name,
    'users: legacy google_id vs newer provider_id'
        AS note
FROM sys.columns c
WHERE c.object_id = OBJECT_ID(N'dbo.users')
  AND c.name IN (N'google_id', N'provider_id', N'auth_provider')
ORDER BY c.name;
