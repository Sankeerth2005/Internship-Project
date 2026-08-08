IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'refresh_tokens')
BEGIN
    CREATE TABLE refresh_tokens (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_refresh_tokens PRIMARY KEY,
        user_id BIGINT NOT NULL,
        token_hash NVARCHAR(128) NOT NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_refresh_tokens_created_at DEFAULT (SYSUTCDATETIME()),
        expires_at DATETIME2 NOT NULL,
        revoked_at DATETIME2 NULL,
        replaced_by_token_hash NVARCHAR(128) NULL,
        device_info NVARCHAR(64) NULL,
        CONSTRAINT FK_refresh_tokens_users FOREIGN KEY (user_id) REFERENCES users(user_id)
    );

    CREATE UNIQUE INDEX IX_refresh_tokens_token_hash ON refresh_tokens(token_hash);
    CREATE INDEX IX_refresh_tokens_user_id ON refresh_tokens(user_id);
END
GO
