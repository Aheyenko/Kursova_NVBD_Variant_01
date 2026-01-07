/* ============================================================
   UniversityDW - Data Warehouse (FIRST RUN, structure only)
   NO ETL here. NO DimDate population here.
   - SCD2 only for dw.DimTeacher
   - Other dimensions: SCD1
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

------------------------------------------------------------
-- 0) Create DW database
------------------------------------------------------------
IF DB_ID(N'UniversityDW') IS NULL
BEGIN
    CREATE DATABASE UniversityDW;
END
GO

USE UniversityDW;
GO

------------------------------------------------------------
-- 1) Schemas
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'dw')
    EXEC('CREATE SCHEMA dw');
GO

------------------------------------------------------------
-- 2) Drop objects (safe rerun)
------------------------------------------------------------
-- Facts
IF OBJECT_ID(N'dw.FactStudentGrade', 'U') IS NOT NULL DROP TABLE dw.FactStudentGrade;
IF OBJECT_ID(N'dw.FactStudentSemesterPerformance', 'U') IS NOT NULL DROP TABLE dw.FactStudentSemesterPerformance;
IF OBJECT_ID(N'dw.FactScholarshipPayment', 'U') IS NOT NULL DROP TABLE dw.FactScholarshipPayment;
IF OBJECT_ID(N'dw.FactStudentGroupSnapshot', 'U') IS NOT NULL DROP TABLE dw.FactStudentGroupSnapshot;

-- Dimensions
IF OBJECT_ID(N'dw.DimStudent', 'U') IS NOT NULL DROP TABLE dw.DimStudent;
IF OBJECT_ID(N'dw.DimGroup', 'U') IS NOT NULL DROP TABLE dw.DimGroup;
IF OBJECT_ID(N'dw.DimSubject', 'U') IS NOT NULL DROP TABLE dw.DimSubject;
IF OBJECT_ID(N'dw.DimTeacher', 'U') IS NOT NULL DROP TABLE dw.DimTeacher;
IF OBJECT_ID(N'dw.DimDate', 'U') IS NOT NULL DROP TABLE dw.DimDate;
GO

------------------------------------------------------------
-- 3) Dimensions
------------------------------------------------------------

-- 3.1 DimDate (structure only; load separately)
CREATE TABLE dw.DimDate
(
    DateKey      INT          NOT NULL CONSTRAINT PK_DimDate PRIMARY KEY, -- YYYYMMDD
    [Date]       DATE         NOT NULL,
    [Year]       SMALLINT     NOT NULL,
    MonthNumber  TINYINT      NOT NULL,
    DayNumber    TINYINT      NOT NULL,
    MonthName    NVARCHAR(20) NOT NULL
);
GO
CREATE UNIQUE INDEX UX_DimDate_Date ON dw.DimDate([Date]);
GO

-- 3.2 DimStudent (SCD1)
CREATE TABLE dw.DimStudent
(
    StudentKey     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimStudent PRIMARY KEY,
    StudentID      INT NOT NULL,          -- OLTP natural key
    StudentCardNo  NVARCHAR(20) NULL,
    LastName       NVARCHAR(50) NOT NULL,
    FirstName      NVARCHAR(50) NOT NULL,
    MiddleName     NVARCHAR(50) NULL,
    Gender         CHAR(1) NULL,
    BirthYear      SMALLINT NULL,
    IsActive       BIT NOT NULL,
    DormRoomNo     INT NULL,
    CONSTRAINT UQ_DimStudent_StudentID UNIQUE (StudentID)
);
GO

-- 3.3 DimGroup (SCD1)
CREATE TABLE dw.DimGroup
(
    GroupKey     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimGroup PRIMARY KEY,
    GroupID      INT NOT NULL,
    GroupCode    NVARCHAR(30) NOT NULL,
    CreationYear SMALLINT NOT NULL,
    CONSTRAINT UQ_DimGroup_GroupID UNIQUE (GroupID)
);
GO

-- 3.4 DimSubject (SCD1)
CREATE TABLE dw.DimSubject
(
    SubjectKey   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimSubject PRIMARY KEY,
    SubjectID    INT NOT NULL,
    SubjectName  NVARCHAR(120) NOT NULL,
    Credits      TINYINT NULL,
    CONSTRAINT UQ_DimSubject_SubjectID UNIQUE (SubjectID)
);
GO

-- 3.5 DimTeacher (SCD2)
CREATE TABLE dw.DimTeacher
(
    TeacherKey    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimTeacher PRIMARY KEY,
    TeacherID     INT NOT NULL, -- OLTP natural key

    LastName      NVARCHAR(50) NOT NULL,
    FirstName     NVARCHAR(50) NOT NULL,
    MiddleName    NVARCHAR(50) NULL,
    Department    NVARCHAR(100) NULL,
    Email         NVARCHAR(120) NULL,

    ValidFrom     DATETIME2(0) NOT NULL,
    ValidTo       DATETIME2(0) NOT NULL,
    IsCurrent     BIT NOT NULL,

    CONSTRAINT CK_DimTeacher_Valid CHECK (ValidTo > ValidFrom)
);
GO
CREATE INDEX IX_DimTeacher_TeacherID_Current ON dw.DimTeacher(TeacherID, IsCurrent);
GO

------------------------------------------------------------
-- 4) Facts (grain aligned to reports)
------------------------------------------------------------

-- 4.1 Snapshot: Students by groups (report #1)
CREATE TABLE dw.FactStudentGroupSnapshot
(
    SnapshotDateKey INT NOT NULL,
    StudentKey      INT NOT NULL,
    GroupKey        INT NOT NULL,
    IsActiveStudent BIT NOT NULL,

    CONSTRAINT PK_FactStudentGroupSnapshot PRIMARY KEY (SnapshotDateKey, StudentKey),
    CONSTRAINT FK_FSGS_Date    FOREIGN KEY (SnapshotDateKey) REFERENCES dw.DimDate(DateKey),
    CONSTRAINT FK_FSGS_Student FOREIGN KEY (StudentKey)      REFERENCES dw.DimStudent(StudentKey),
    CONSTRAINT FK_FSGS_Group   FOREIGN KEY (GroupKey)        REFERENCES dw.DimGroup(GroupKey)
);
GO

-- 4.2 Atomic grades fact: performance by subject & teacher (report #4)
CREATE TABLE dw.FactStudentGrade
(
    GradeDateKey   INT NOT NULL,
    StudentKey     INT NOT NULL,
    SubjectKey     INT NOT NULL,
    TeacherKey     INT NOT NULL,    -- SCD2 surrogate key
    AcademicYear   SMALLINT NOT NULL,
    Semester       TINYINT  NOT NULL,

    Points         DECIMAL(5,2) NOT NULL,
    StateGrade     TINYINT NOT NULL,

    CONSTRAINT FK_FSG_Date    FOREIGN KEY (GradeDateKey) REFERENCES dw.DimDate(DateKey),
    CONSTRAINT FK_FSG_Student FOREIGN KEY (StudentKey)   REFERENCES dw.DimStudent(StudentKey),
    CONSTRAINT FK_FSG_Subject FOREIGN KEY (SubjectKey)   REFERENCES dw.DimSubject(SubjectKey),
    CONSTRAINT FK_FSG_Teacher FOREIGN KEY (TeacherKey)   REFERENCES dw.DimTeacher(TeacherKey)
);
GO
CREATE INDEX IX_FactStudentGrade_Period ON dw.FactStudentGrade(AcademicYear, Semester);
GO

-- 4.3 Semester performance: rating by range (report #2) + certificate base (report #3)
CREATE TABLE dw.FactStudentSemesterPerformance
(
    PeriodStartDateKey INT NOT NULL,   -- start of semester
    StudentKey         INT NOT NULL,
    AcademicYear       SMALLINT NOT NULL,
    Semester           TINYINT NOT NULL,

    AvgPoints          DECIMAL(10,4) NOT NULL,
    AvgStateGrade      DECIMAL(10,4) NOT NULL,
    SubjectsCount      INT NOT NULL,

    CONSTRAINT PK_FSSP PRIMARY KEY (StudentKey, AcademicYear, Semester),
    CONSTRAINT FK_FSSP_Date    FOREIGN KEY (PeriodStartDateKey) REFERENCES dw.DimDate(DateKey),
    CONSTRAINT FK_FSSP_Student FOREIGN KEY (StudentKey)         REFERENCES dw.DimStudent(StudentKey)
);
GO

-- 4.4 Scholarship payments fact: for report #3
CREATE TABLE dw.FactScholarshipPayment
(
    PeriodStartDateKey INT NOT NULL,
    StudentKey         INT NOT NULL,
    AcademicYear       SMALLINT NOT NULL,
    Semester           TINYINT NOT NULL,
    Amount             MONEY NOT NULL,

    CONSTRAINT PK_FSP PRIMARY KEY (StudentKey, AcademicYear, Semester),
    CONSTRAINT FK_FSP_Date    FOREIGN KEY (PeriodStartDateKey) REFERENCES dw.DimDate(DateKey),
    CONSTRAINT FK_FSP_Student FOREIGN KEY (StudentKey)         REFERENCES dw.DimStudent(StudentKey)
);
GO

------------------------------------------------------------
-- 5) Quick sanity: list tables
------------------------------------------------------------
SELECT s.name AS [Schema], t.name AS [Table]
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'dw'
ORDER BY t.name;
GO
