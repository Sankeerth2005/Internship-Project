-- 1. Clean existing coordinates where both lat/lng are 0 (invalid default value)
UPDATE [business_contact]
SET [latitude] = NULL, [longitude] = NULL
WHERE [latitude] = 0.0 AND [longitude] = 0.0;

-- 2. Add CHECK constraint to enforce coordinate integrity
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'business_contact')
BEGIN
    -- Remove constraint if it already exists to avoid errors
    IF EXISTS (SELECT * FROM sys.objects WHERE parent_object_id = OBJECT_ID('business_contact') AND name = 'CK_business_contact_coordinates')
    BEGIN
        ALTER TABLE [business_contact] DROP CONSTRAINT [CK_business_contact_coordinates];
    END

    ALTER TABLE [business_contact]
    ADD CONSTRAINT [CK_business_contact_coordinates] CHECK (
        ([latitude] IS NULL AND [longitude] IS NULL) OR
        (
            [latitude] BETWEEN -90.0 AND 90.0 AND 
            [longitude] BETWEEN -180.0 AND 180.0 AND 
            ([latitude] <> 0.0 OR [longitude] <> 0.0)
        )
    );
END
GO
