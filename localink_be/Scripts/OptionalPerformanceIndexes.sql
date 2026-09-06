-- OPTIONAL performance indexes for Localink / Vocal for Sanatan
-- =============================================================================
-- IMPORTANT:
--   Running this script CHANGES the database you are connected to.
--   If SSMS is connected to your manager's SQL Server, those indexes are created THERE.
--   Review the connection (server name / database) before executing.
--
-- This is NOT an EF migration. Run manually only when you and your manager agree.
-- Safe to re-run: each statement uses IF NOT EXISTS.
-- =============================================================================

USE [VocalForSanatan];  -- <-- change database name if yours differs
GO

-- Admin approval filter (discovery / listings)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_admin_dashboard_Status'
      AND object_id = OBJECT_ID(N'dbo.admin_dashboard')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_admin_dashboard_Status
        ON dbo.admin_dashboard (Status)
        INCLUDE (BusinessId);
END
GO

-- Temporary closure visibility filter
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_business_temporary_closure'
      AND object_id = OBJECT_ID(N'dbo.business')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_business_temporary_closure
        ON dbo.business (temporary_closure_status, temporary_closure_reopen_date);
END
GO

-- Chat message paging
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_messages_ConversationId_Timestamp'
      AND object_id = OBJECT_ID(N'dbo.messages')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_messages_ConversationId_Timestamp
        ON dbo.messages (ConversationId, Timestamp);
END
GO

-- Spatial index for near-me search (requires geo_location to be NOT NULL for indexed rows)
-- If this fails on your SQL edition or table, skip it and keep the other indexes.
IF NOT EXISTS (
    SELECT 1 FROM sys.spatial_indexes
    WHERE name = N'SIX_business_contact_geo_location'
      AND object_id = OBJECT_ID(N'dbo.business_contact')
)
BEGIN
    BEGIN TRY
        CREATE SPATIAL INDEX SIX_business_contact_geo_location
            ON dbo.business_contact (geo_location)
            USING GEOGRAPHY_AUTO_GRID;
    END TRY
    BEGIN CATCH
        PRINT 'Spatial index skipped: ' + ERROR_MESSAGE();
    END CATCH
END
GO

PRINT 'Optional Localink indexes script finished.';
GO
