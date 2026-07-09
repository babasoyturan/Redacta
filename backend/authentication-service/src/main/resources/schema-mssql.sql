IF OBJECT_ID(N'dbo.users', N'U') IS NULL
  EXEC(N'CREATE TABLE dbo.users (
    id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    username NVARCHAR(255) NOT NULL,
    email NVARCHAR(320) NOT NULL,
    created_at DATETIME2 NOT NULL CONSTRAINT df_users_created_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT uq_users_username UNIQUE(username),
    CONSTRAINT uq_users_email UNIQUE(email)
  )');
