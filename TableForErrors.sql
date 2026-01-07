CREATE TABLE dw.ETL_ErrorLog(
    ErrorID        INT IDENTITY(1,1) PRIMARY KEY,
    PackageName    NVARCHAR(128),
    TaskName       NVARCHAR(128),
    ErrorCode      INT,
    ErrorColumn    INT,
    ErrorDesc      NVARCHAR(4000),
    SourceRowKey   NVARCHAR(200),
    CreatedAt      DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME()
);
