IF OBJECT_ID(N'dbo.document', N'U') IS NULL
  EXEC(N'CREATE TABLE dbo.document (
    id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    user_id UNIQUEIDENTIFIER NOT NULL,
    file_name NVARCHAR(512) NOT NULL,
    file_url NVARCHAR(2048) NULL,
    status NVARCHAR(50) NOT NULL CONSTRAINT df_document_status DEFAULT ''UPLOADED'',
    upload_date DATETIMEOFFSET NOT NULL CONSTRAINT df_document_upload_date DEFAULT SYSDATETIMEOFFSET()
  )');

IF OBJECT_ID(N'dbo.document_text', N'U') IS NULL
  EXEC(N'CREATE TABLE dbo.document_text (
    document_id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    text NVARCHAR(MAX) NOT NULL,
    CONSTRAINT fk_document_text_document
      FOREIGN KEY(document_id)
      REFERENCES dbo.document(id)
      ON DELETE CASCADE
  )');
