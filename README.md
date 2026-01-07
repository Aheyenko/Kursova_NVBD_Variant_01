
	Проектування та реалізація інформаційної системи управління навчальним процесом університету. Система має автоматизувати процес збору даних, їх перетворення та візуалізації у вигляді інтерактивних звітів.

Об’єкт дослідження
	Процеси обліку студентів та моніторинг їхньої успішності в закладі вищої освіти.

Предмет дослідження
	Методи та засоби побудови аналітичних систем на основі стеку технологій Microsoft SQL Server (SSIS, SSAS, SSRS).


	Концептуальна модель бази даних відображає основні об’єкти (сутності) предметної області та зв’язки між ними без прив’язки до конкретної СУБД.
	Опис основних сутностей та їх атрибутів:
Студенти (Student):
Опис: містить персональну та анкетовану інформацію про осіб, що навчаються.
Атрибути:
StudentID
LastName
FirstName
MiddleName
StudentCardNo
BirthYear
BirthPlace
Address
Gender
MaritalStatus
ScholarshipAmount
DormRoomNum
IsActive
		Групи (Group):
Опис: колектив студентів, об’єднаний за роком вступу та напрямом навчання.
Атрибути:
GroupID
GroupCode
CreationYear
LeaderStudentID
		Предмети (Subject):
Опис: навчальні дисципліни, які входять до програми навчання.
Атрибути:
SubjectID
SubjectName
Credits
		Викладачі (Teacher):
Опис: співробітники університету, що забезпечують навчальний процес.
Атрибути:
TeacherID
LastName
FirstName
MiddleName
Department
Email
		Оцінки (StudentGrade):
Опис: результати контролю знань студентів.
Атрибути: 
StudentGradeID
 StudentID
TeacherSubjectID
AcademicYear
Semester
GradeDate
AttemptNo
Points
StateGrade
		Хобі (Hobby):
Опис: довідник можливих захоплень студентів.
Атрибути:
HobbyID
HobbyName





Розділ 2. Проектування бази даних

Загальна характеристика бази даних
	База даних UniversityDB призначена для зберігання, обробки та аналізу інформації про освітній процес у вищому навчальному закладі. Вона охоплює дані про студентів, навчальні групи, викладачів, дисципліни, оцінювання, рейтинги та стипендіальне забезпечення.
	Проектування бази даних виконано з урахуванням таких вимог:
підтримка великої кількості записів;
забезпечення логічної та референтної цілісності;
можливість історичного зберігання даних;

Логічна структура бази даних
	Логічна модель бази даних включає такі групи таблиць:
Довідкові таблиці
Hobby, Subject, Teacher, Group
Операційні таблиці 
Student, StudentGrade
Аналітичні таблиці
StudentRating, ScholarshipPeriod
	Таке розділення дозволяє спростити підтримку структури та масштабування системи.

Приклад створення довідникової таблиці Hobby:
CREATE TABLE [dbo].[Hobby](
    [HobbyID] [int] IDENTITY(1,1) NOT NULL,
     NOT NULL,
 CONSTRAINT [PK_Hobby] PRIMARY KEY CLUSTERED ([HobbyID] ASC),
 CONSTRAINT [UQ_Hobby_HobbyName] UNIQUE NONCLUSTERED ([HobbyName] ASC)
);
Наявність унікального обмеження на поле HobbyName запобігає дублюванню довідникових значень під час генерації великих обсягів даних.
Забезпечення унікальності та цілісності
Для забезпечення цілісності даних у базі активно використовуються обмеження UNIQUE та CHECK.
Приклад унікального обмеження для таблиці навчальних груп:
CONSTRAINT [UQ_Group_GroupCode] UNIQUE NONCLUSTERED ([GroupCode] ASC)

Це гарантує, що кожна навчальна група має унікальний код, що відповідає реальній організаційній структурі університету.
Перевірка допустимих значень (CHECK)
Для запобігання логічно некоректних даних застосовано перевірки діапазонів значень.
Приклад обмеження для року створення групи:
CONSTRAINT [CK_Group_CreationYear]
CHECK ([CreationYear] >= 1990 AND [CreationYear] <= 2100)
Це обмеження забезпечує генерацію тільки реалістичних значень років.
Генерація великих обсягів даних
Фактографічні таблиці
Основне навантаження припадає на таблиці, що зберігають результати навчання та фінансові операції.
Приклад створення таблиці StudentGrade:
CREATE TABLE [dbo].[StudentGrade](
    [StudentGradeID] [bigint] IDENTITY(1,1) NOT NULL,
    [StudentID] [int] NOT NULL,
    [TeacherSubjectID] [int] NOT NULL,
    [AcademicYear] [smallint] NOT NULL,
    [Semester] [tinyint] NOT NULL,
    [GradeDate] [date] NOT NULL,
    [AttemptNo] [tinyint] NOT NULL,
    [Points] [decimal](5, 2) NOT NULL,
    [StateGrade] [tinyint] NOT NULL,
 CONSTRAINT [PK_StudentGrade] PRIMARY KEY CLUSTERED ([StudentGradeID] ASC)
);
Саме ця таблиця містить найбільшу кількість записів та використовується для розрахунку рейтингів.
Реалізація зовнішніх ключів
Зв’язність між таблицями забезпечується зовнішніми ключами.
Приклад зовнішнього ключа між StudentGrade та Student:
ALTER TABLE [dbo].[StudentGrade]
ADD CONSTRAINT [FK_StudentGrade_Student]
FOREIGN KEY ([StudentID])
REFERENCES [dbo].[Student] ([StudentID]);
Це унеможливлює створення оцінок для неіснуючих студентів.
Налаштування генератора даних
Генерація даних з урахуванням часових періодів
Для зберігання академічних періодів використовується таблиця ScholarshipPeriod.
Приклад її створення:
CREATE TABLE [dbo].[ScholarshipPeriod](
    [PeriodID] [int] IDENTITY(1,1) NOT NULL,
    [AcademicYear] [smallint] NOT NULL,
    [Semester] [tinyint] NOT NULL,
    [DateFrom] [date] NOT NULL,
    [DateTo] [date] NOT NULL,
 CONSTRAINT [PK_ScholarshipPeriod] PRIMARY KEY CLUSTERED ([PeriodID] ASC),
 CONSTRAINT [CK_SP_Dates] CHECK ([DateTo] > [DateFrom])
);
Це дозволяє коректно моделювати навчальні семестри протягом кількох років.
Забезпечення часових даних
Історія перебування студентів у групах реалізована за допомогою таблиці StudentGroup.
Фрагмент реалізації:
CREATE TABLE [dbo].[StudentGroup](
    [StudentGroupID] [int] IDENTITY(1,1) NOT NULL,
    [StudentID] [int] NOT NULL,
    [GroupID] [int] NOT NULL,
    [DateFrom] [date] NOT NULL,
    [DateTo] [date] NULL,
 CONSTRAINT [CK_StudentGroup_Dates]
 CHECK ([DateTo] IS NULL OR [DateTo] > [DateFrom])
);
Денормалізація для оптимізації
Поле ScholarshipAmount зберігається безпосередньо у таблиці Student.
Приклад значення за замовчуванням:
ALTER TABLE [dbo].[Student]
ADD CONSTRAINT [DF_Student_ScholarshipAmount]
DEFAULT ((0)) FOR [ScholarshipAmount];
Це дозволяє швидко отримувати поточний розмір стипендії без складних обчислень.
Фізичне проєктування
Збережені процедури
Для реалізації бізнес-логіки розрахунку стипендій використовується збережена процедура.
Фрагмент процедури usp_CalculateScholarship:
INSERT INTO dbo.StudentRating(PeriodID, StudentID, RatingValue)
SELECT
    @PeriodID,
    sg.StudentID,
    AVG(CAST(sg.Points AS DECIMAL(10,4)))
FROM dbo.StudentGrade sg
JOIN dbo.Student st
  ON st.StudentID = sg.StudentID
 AND st.IsActive = 1
WHERE sg.AcademicYear = @ay
  AND sg.Semester = @sem
GROUP BY sg.StudentID;
Цей фрагмент демонструє розрахунок рейтингу студентів на основі їхніх оцінок.
Забезпечення правил бізнес-логіки
Для складних правил використовуються тригери, які вмикаються спеціальною процедурою.
Приклад процедури увімкнення тригерів:
ENABLE TRIGGER dbo.tr_Student_DormRoomCapacity ON dbo.Student;
ENABLE TRIGGER dbo.tr_Group_LeaderMustBelong ON dbo.[Group];

Дані генерувалися за допомогою Redgate SQL Data Generator
Внизу прикріпляється звіт про генерацію даних

Призначення та загальна характеристика сховища даних
Сховище даних UniversityDW призначене для аналітичної обробки інформації, отриманої з операційної бази даних університету (OLTP). 
Основною метою створення сховища є підтримка формування аналітичних звітів, оцінювання навчальних результатів студентів, аналізу ефективності викладання та розрахунку стипендіального забезпечення.
На відміну від транзакційної бази даних, UniversityDW оптимізоване для читання великих обсягів історичних даних і підтримує багатовимірний аналіз (OLAP). Завантаження даних у сховище передбачається виконувати окремими ETL-процесами, які не входять до даного етапу реалізації.

Архітектура сховища даних
Сховище даних реалізоване відповідно до зіркоподібної схеми (Star Schema), яка складається з:
таблиць вимірів;
таблиць фактів;
Для логічного розділення об’єктів сховища використовується окрема схема dw, що дозволяє чітко відокремити аналітичну модель від OLTP-рівня.

CREATE SCHEMA dw;
Керування версіями та безпечний повторний запуск
Для забезпечення можливості повторного виконання скрипта без помилок використано перевірки на існування об’єктів перед їх видаленням:
IF OBJECT_ID(N'dw.FactStudentGrade', 'U') IS NOT NULL
    DROP TABLE dw.FactStudentGrade;
Такий підхід дозволяє використовувати скрипт як baseline-структуру сховища даних.

Таблиці вимірів
Вимір дати (DimDate)
Таблиця DimDate є центральним календарним виміром, який використовується всіма таблицями фактів.
CREATE TABLE dw.DimDate
(
    DateKey INT NOT NULL PRIMARY KEY,
    [Date] DATE NOT NULL,
    [Year] SMALLINT NOT NULL,
    MonthNumber TINYINT NOT NULL,
    DayNumber TINYINT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL
);
Поле DateKey реалізовано у форматі YYYYMMDD, що дозволяє уникнути обчислень при приєднанні до фактів.
Вимір студентів (DimStudent, SCD Type 1)
Таблиця DimStudent зберігає актуальні атрибути студентів без збереження історії змін (SCD Type 1).
CREATE TABLE dw.DimStudent
(
    StudentKey INT IDENTITY PRIMARY KEY,
    StudentID INT NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    IsActive BIT NOT NULL,
    DormRoomNo INT NULL
);

Поле StudentKey є сурогатним ключем, тоді як StudentID — натуральним ключем з OLTP-системи.
Вимір навчальних груп (DimGroup)
CREATE TABLE dw.DimGroup
(
    GroupKey INT IDENTITY PRIMARY KEY,
    GroupID INT NOT NULL,
    GroupCode NVARCHAR(30) NOT NULL,
    CreationYear SMALLINT NOT NULL
);
Цей вимір використовується для групування студентів у звітах і зрізах за роками набору.
Вимір дисциплін (DimSubject)
CREATE TABLE dw.DimSubject
(
    SubjectKey INT IDENTITY PRIMARY KEY,
    SubjectID INT NOT NULL,
    SubjectName NVARCHAR(120) NOT NULL,
    Credits TINYINT NULL
);

Таблиця забезпечує аналіз успішності за дисциплінами та кредитним навантаженням.
Вимір викладачів (DimTeacher, SCD Type 2)
Таблиця DimTeacher реалізує повну історичність змін (Slowly Changing Dimension Type 2).
CREATE TABLE dw.DimTeacher
(
    TeacherKey INT IDENTITY PRIMARY KEY,
    TeacherID INT NOT NULL,
    Department NVARCHAR(100),
    ValidFrom DATETIME2 NOT NULL,
    ValidTo DATETIME2 NOT NULL,
    IsCurrent BIT NOT NULL
);

Завдяки полям ValidFrom, ValidTo та IsCurrent стає можливим аналіз результатів студентів у контексті змін викладацького складу.
Таблиці фактів
Знімок студентів за групами (FactStudentGroupSnapshot)
CREATE TABLE dw.FactStudentGroupSnapshot
(
    SnapshotDateKey INT NOT NULL,
    StudentKey INT NOT NULL,
    GroupKey INT NOT NULL,
    IsActiveStudent BIT NOT NULL
);

Фактова таблиця використовується для звітів типу snapshot, наприклад:
кількість активних студентів у групах на конкретну дату.
Факт оцінювання студентів (FactStudentGrade)
CREATE TABLE dw.FactStudentGrade
(
    GradeDateKey INT NOT NULL,
    StudentKey INT NOT NULL,
    SubjectKey INT NOT NULL,
    TeacherKey INT NOT NULL,
    AcademicYear SMALLINT NOT NULL,
    Semester TINYINT NOT NULL,
    Points DECIMAL(5,2) NOT NULL
);

Це атомарна таблиця фактів, яка зберігає всі оцінки студентів і слугує джерелом для більш агрегованих фактів.
Семестрові показники (FactStudentSemesterPerformance)
CREATE TABLE dw.FactStudentSemesterPerformance
(
    StudentKey INT NOT NULL,
    AcademicYear SMALLINT NOT NULL,
    Semester TINYINT NOT NULL,
    AvgPoints DECIMAL(10,4) NOT NULL,
    SubjectsCount INT NOT NULL
);

Таблиця використовується для:
рейтинг студентів;
формування довідок;
аналітики успішності.
Факт виплат стипендій (FactScholarshipPayment)
CREATE TABLE dw.FactScholarshipPayment
(
    StudentKey INT NOT NULL,
    AcademicYear SMALLINT NOT NULL,
    Semester TINYINT NOT NULL,
    Amount MONEY NOT NULL
);

Дана таблиця дозволяє аналізувати фінансове забезпечення студентів у розрізі семестрів.
Забезпечення цілісності даних
Для всіх таблиць фактів реалізовано зовнішні ключі до відповідних вимірів:
FOREIGN KEY (StudentKey) REFERENCES dw.DimStudent(StudentKey)
Це гарантує повну референтну цілісність сховища.



Додаткові міри
[AverageScore]
[Measures].[AllPoints] / [Measures].[Fact Student Grade Count]

[ScholarshipPercent]
[Measures].[TotalAmount] / ([Measures].[TotalAmount], [Dim Student].[Student Full Name].[All])

[CostPerPoint]
[Measures].[TotalAmount] / [Measures].[AllPoints]

[StudentRank]
RANK([Dim Student].[Student Full Name].CurrentMember, [SortedStudents])

[WeightedAverage]
IIF(
  [Measures].[AllCredits] = 0, 
  NULL, 
  [Measures].[SumWeightedPoints] / [Measures].[AllCredits]
)

[PreviousYear]
([Measures].[TotalAmount], PARALLELPERIOD([Dim Date].[Hierarchy].[Year], 1, [Dim Date].[Hierarchy].CurrentMember))

[3MonthAverageScore]
AVG( LASTPERIODS(3, [Dim Date].[Hierarchy].CurrentMember), [Measures].[AllPoints] / [Measures].[Fact Student Grade Count] )


[ScorePer1000Currency]
IIF(
  [Measures].[TotalAmount] = 0, 
  0, 
  ([Measures].[WeightedAverage] / [Measures].[TotalAmount]) * 1000
)

[YearOverYearGrowth]
IIF(ISEMPTY([Measures].[PreviousYear]) OR [Measures].[PreviousYear] = 0, NULL,
([Measures].[AllPoints] - [Measures].[PreviousYear]) / [Measures].[PreviousYear])
