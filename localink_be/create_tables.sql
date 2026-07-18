CREATE TABLE [addresses] (
    [address_id] bigint NOT NULL IDENTITY,
    [user_id] bigint NOT NULL,
    [country] nvarchar(100) NOT NULL,
    [state] nvarchar(100) NOT NULL,
    [city] nvarchar(100) NOT NULL,
    [street_address] nvarchar(200) NOT NULL,
    [pincode] nvarchar(10) NOT NULL,
    CONSTRAINT [PK_addresses] PRIMARY KEY ([address_id])
);
GO


CREATE TABLE [business_hours] (
    [business_hour_id] bigint NOT NULL IDENTITY,
    [business_id] bigint NOT NULL,
    [day_of_week] nvarchar(max) NOT NULL,
    [mode] nvarchar(max) NOT NULL,
    [created_at] datetime2 NOT NULL,
    [updated_at] datetime2 NOT NULL,
    CONSTRAINT [PK_business_hours] PRIMARY KEY ([business_hour_id])
);
GO


CREATE TABLE [category] (
    [category_id] int NOT NULL IDENTITY,
    [category_name] nvarchar(max) NOT NULL,
    [icon_url] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_category] PRIMARY KEY ([category_id])
);
GO


CREATE TABLE [Feedbacks] (
    [Id] int NOT NULL IDENTITY,
    [Message] nvarchar(max) NOT NULL,
    [UserId] int NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Feedbacks] PRIMARY KEY ([Id])
);
GO


CREATE TABLE [users] (
    [user_id] bigint NOT NULL IDENTITY,
    [account_type] nvarchar(max) NOT NULL,
    [full_name] nvarchar(max) NOT NULL,
    [email] nvarchar(max) NOT NULL,
    [phone_number] nvarchar(450) NULL,
    [country_code] nvarchar(max) NOT NULL,
    [password_hash] nvarchar(max) NULL,
    [google_id] nvarchar(450) NULL,
    [otp_attempts] int NULL,
    [password_reset_otp] nvarchar(max) NULL,
    [otp_expiry] datetime2 NULL,
    CONSTRAINT [PK_users] PRIMARY KEY ([user_id])
);
GO


CREATE TABLE [business_hour_slots] (
    [slot_id] bigint NOT NULL IDENTITY,
    [business_hour_id] bigint NOT NULL,
    [open_time] time NOT NULL,
    [close_time] time NOT NULL,
    [created_at] datetime2 NOT NULL,
    CONSTRAINT [PK_business_hour_slots] PRIMARY KEY ([slot_id]),
    CONSTRAINT [FK_business_hour_slots_business_hours_business_hour_id] FOREIGN KEY ([business_hour_id]) REFERENCES [business_hours] ([business_hour_id]) ON DELETE CASCADE
);
GO


CREATE TABLE [subcategory] (
    [subcategory_id] int NOT NULL IDENTITY,
    [subcategory_name] nvarchar(max) NOT NULL,
    [icon_url] nvarchar(max) NULL,
    [category_id] int NOT NULL,
    CONSTRAINT [PK_subcategory] PRIMARY KEY ([subcategory_id]),
    CONSTRAINT [FK_subcategory_category_category_id] FOREIGN KEY ([category_id]) REFERENCES [category] ([category_id]) ON DELETE CASCADE
);
GO


CREATE TABLE [business_reviews] (
    [review_id] bigint NOT NULL IDENTITY,
    [business_id] bigint NOT NULL,
    [user_id] bigint NOT NULL,
    [rating] int NOT NULL,
    [comment] nvarchar(max) NULL,
    [created_at] datetime2 NOT NULL,
    [updated_at] datetime2 NULL,
    [image_url] nvarchar(max) NULL,
    CONSTRAINT [PK_business_reviews] PRIMARY KEY ([review_id]),
    CONSTRAINT [FK_business_reviews_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([user_id])
);
GO


CREATE TABLE [business] (
    [business_id] bigint NOT NULL IDENTITY,
    [business_name] nvarchar(max) NOT NULL,
    [description] nvarchar(max) NOT NULL,
    [user_id] bigint NOT NULL,
    [category_id] int NOT NULL,
    [subcategory_id] int NOT NULL,
    [created_at] datetime2 NOT NULL,
    [updated_at] datetime2 NOT NULL,
    [temporary_closure_reason] nvarchar(max) NULL,
    [temporary_closure_days] int NULL,
    [temporary_closure_status] nvarchar(max) NULL,
    [temporary_closure_reopen_date] datetime2 NULL,
    CONSTRAINT [PK_business] PRIMARY KEY ([business_id]),
    CONSTRAINT [FK_business_category_category_id] FOREIGN KEY ([category_id]) REFERENCES [category] ([category_id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_business_subcategory_subcategory_id] FOREIGN KEY ([subcategory_id]) REFERENCES [subcategory] ([subcategory_id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_business_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([user_id]) ON DELETE CASCADE
);
GO


CREATE TABLE [admin_dashboard] (
    [id] bigint NOT NULL IDENTITY,
    [business_id] bigint NOT NULL,
    [Status] int NOT NULL,
    [rejection_reason] nvarchar(max) NULL,
    [action_by] bigint NULL,
    [created_at] datetime2 NOT NULL,
    [updated_at] datetime2 NULL,
    CONSTRAINT [PK_admin_dashboard] PRIMARY KEY ([id]),
    CONSTRAINT [FK_admin_dashboard_business_business_id] FOREIGN KEY ([business_id]) REFERENCES [business] ([business_id]) ON DELETE CASCADE
);
GO


CREATE TABLE [business_contact] (
    [contact_id] bigint NOT NULL IDENTITY,
    [business_id] bigint NOT NULL,
    [phone_code] nvarchar(max) NOT NULL,
    [phone_number] nvarchar(max) NOT NULL,
    [email] nvarchar(max) NOT NULL,
    [website] nvarchar(max) NOT NULL,
    [street_address] nvarchar(200) NOT NULL,
    [city] nvarchar(max) NOT NULL,
    [state] nvarchar(max) NOT NULL,
    [country] nvarchar(max) NOT NULL,
    [pincode] nvarchar(max) NOT NULL,
    [created_at] datetime2 NOT NULL,
    [updated_at] datetime2 NOT NULL,
    [latitude] float NULL,
    [longitude] float NULL,
    CONSTRAINT [PK_business_contact] PRIMARY KEY ([contact_id]),
    CONSTRAINT [FK_business_contact_business_business_id] FOREIGN KEY ([business_id]) REFERENCES [business] ([business_id]) ON DELETE CASCADE,
    CONSTRAINT [CK_business_contact_coordinates] CHECK (
        ([latitude] IS NULL AND [longitude] IS NULL) OR
        ([latitude] BETWEEN -90.0 AND 90.0 AND [longitude] BETWEEN -180.0 AND 180.0 AND ([latitude] <> 0.0 OR [longitude] <> 0.0))
    )
);
GO


CREATE TABLE [business_photos] (
    [photo_id] bigint NOT NULL IDENTITY,
    [business_id] bigint NOT NULL,
    [image_url] nvarchar(max) NOT NULL,
    [is_primary] bit NOT NULL,
    [created_at] datetime2 NOT NULL,
    CONSTRAINT [PK_business_photos] PRIMARY KEY ([photo_id]),
    CONSTRAINT [FK_business_photos_business_business_id] FOREIGN KEY ([business_id]) REFERENCES [business] ([business_id]) ON DELETE CASCADE
);
GO


CREATE TABLE [Favorites] (
    [id] bigint NOT NULL IDENTITY,
    [user_id] bigint NOT NULL,
    [business_id] bigint NOT NULL,
    [created_at] datetime2 NOT NULL,
    CONSTRAINT [PK_Favorites] PRIMARY KEY ([id]),
    CONSTRAINT [FK_Favorites_business_business_id] FOREIGN KEY ([business_id]) REFERENCES [business] ([business_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Favorites_users_user_id] FOREIGN KEY ([user_id]) REFERENCES [users] ([user_id]) ON DELETE CASCADE
);
GO


CREATE UNIQUE INDEX [IX_admin_dashboard_business_id] ON [admin_dashboard] ([business_id]);
GO


CREATE INDEX [IX_business_category_id] ON [business] ([category_id]);
GO


CREATE INDEX [IX_business_subcategory_id] ON [business] ([subcategory_id]);
GO


CREATE INDEX [IX_business_user_id] ON [business] ([user_id]);
GO


CREATE INDEX [IX_business_contact_business_id] ON [business_contact] ([business_id]);
GO


CREATE INDEX [IX_business_hour_slots_business_hour_id] ON [business_hour_slots] ([business_hour_id]);
GO


CREATE INDEX [IX_business_photos_business_id] ON [business_photos] ([business_id]);
GO


CREATE INDEX [IX_business_reviews_user_id] ON [business_reviews] ([user_id]);
GO


CREATE INDEX [IX_Favorites_business_id] ON [Favorites] ([business_id]);
GO


CREATE UNIQUE INDEX [IX_Favorites_user_id_business_id] ON [Favorites] ([user_id], [business_id]);
GO


CREATE INDEX [IX_subcategory_category_id] ON [subcategory] ([category_id]);
GO


CREATE UNIQUE INDEX [IX_users_phone_number] ON [users] ([phone_number]) WHERE [phone_number] IS NOT NULL;
GO

CREATE TABLE [business_metric] (
    [id] bigint NOT NULL IDENTITY,
    [business_id] bigint NOT NULL,
    [views] int NOT NULL DEFAULT 0,
    [favorites_count] int NOT NULL DEFAULT 0,
    [contact_clicks] int NOT NULL DEFAULT 0,
    [updated_at] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_business_metric] PRIMARY KEY ([id]),
    CONSTRAINT [FK_business_metric_business_business_id] FOREIGN KEY ([business_id]) REFERENCES [business] ([business_id]) ON DELETE CASCADE
);
GO

CREATE TABLE [search_query_log] (
    [id] bigint NOT NULL IDENTITY,
    [query] nvarchar(max) NOT NULL,
    [latitude] float NOT NULL,
    [longitude] float NOT NULL,
    [timestamp] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_search_query_log] PRIMARY KEY ([id])
);
GO