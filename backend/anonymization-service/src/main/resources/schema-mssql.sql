IF OBJECT_ID(N'dbo.anonymization', N'U') IS NULL
  EXEC(N'CREATE TABLE dbo.anonymization (
    id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    document_id UNIQUEIDENTIFIER NOT NULL,
    user_id UNIQUEIDENTIFIER NOT NULL,
    original_text NVARCHAR(MAX) NOT NULL,
    anonymized_text NVARCHAR(MAX) NOT NULL,
    anonymization_level NVARCHAR(50) NOT NULL,
    changed_terms NVARCHAR(MAX) NOT NULL,
    created DATETIMEOFFSET NOT NULL CONSTRAINT df_anonymization_created DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT ck_anonymization_changed_terms_json CHECK (ISJSON(changed_terms) > 0)
  )');
