-- Customer table
IF OBJECT_ID(N'COMP8071.Customer', N'U') IS NOT NULL
    DROP TABLE dbo.Customer;
GO
CREATE TABLE dbo.Customer(
	ID INT NOT NULL IDENTITY PRIMARY KEY,
	Name VARCHAR(128),
	Address VARCHAR(128),
	BirthDate DATE,
	Picture VARBINARY(MAX),
	Gender CHAR(1)
);
-- ROLAP Customer table
IF OBJECT_ID(N'COMP8071.Rolap_Customer_Dim', N'U') IS NOT NULL
    DROP TABLE dbo.Rolap_Customer_Dim;
GO
CREATE TABLE dbo.Rolap_Customer_Dim(
	ID INT NOT NULL PRIMARY KEY,
	Name VARCHAR(128),
	Address VARCHAR(128),
	BirthDate DATE,
	Picture VARBINARY(MAX),
	Gender CHAR(1)
);
GO

-- Employee table
IF OBJECT_ID(N'dbo.Employee', N'U') IS NOT NULL
    DROP TABLE dbo.Employee;
GO
CREATE TABLE Employee(
	ID INT NOT NULL IDENTITY PRIMARY KEY,
	Name VARCHAR(128),
	Address VARCHAR(128),
	ManagerID INT,
	JobTitle VARCHAR(128),
	CertifiedFor VARCHAR(256),
	StartDate DATE,
	Salary MONEY
);
-- Rolap Employee table
IF OBJECT_ID(N'dbo.Rolap_Employee_Dim', N'U') IS NOT NULL
    DROP TABLE dbo.Rolap_Employee_Dim;
GO
CREATE TABLE Rolap_Employee_Dim(
	ID INT NOT NULL IDENTITY PRIMARY KEY,
	Name VARCHAR(128),
	Address VARCHAR(128),
	ManagerID INT,
	JobTitle VARCHAR(128),
	CertifiedFor VARCHAR(256),
	StartDate DATE,
	Salary MONEY
);

-- ServiceType table
IF OBJECT_ID(N'dbo.ServiceType', N'U') IS NOT NULL
    DROP TABLE dbo.ServiceType;
GO
CREATE TABLE ServiceType(
	ID INT NOT NULL IDENTITY PRIMARY KEY,
	Name VARCHAR(128),
	CertificationReqts VARCHAR(256),
	Rate MONEY
);
-- ROLAP ServiceType table
IF OBJECT_ID(N'dbo.Rolap_ServiceType_Dim', N'U') IS NOT NULL
    DROP TABLE dbo.Rolap_ServiceType_Dim;
GO
CREATE TABLE Rolap_ServiceType_Dim(
	ID INT NOT NULL PRIMARY KEY,
	Name VARCHAR(128),
	CertificationReqts VARCHAR(256),
	Rate MONEY
);

-- CustomerService table
IF OBJECT_ID(N'dbo.CustomerService', N'U') IS NOT NULL
    DROP TABLE dbo.CustomerService;
GO
CREATE TABLE CustomerService(
	CustomerID INT NOT NULL,
	ServiceTypeID INT NOT NULL,
	ExpectedDuration DECIMAL, 
	CONSTRAINT PK_CustomerService PRIMARY KEY (CustomerID, ServiceTypeID)
);
-- CustomerService Table
IF OBJECT_ID(N'dbo.CustomerServiceSchedule', N'U') IS NOT NULL
    DROP TABLE dbo.CustomerServiceSchedule;
GO
CREATE TABLE CustomerServiceSchedule(
	CustomerID INT NOT NULL,
	ServiceTypeID INT NOT NULL,
	EmployeeID INT NOT NULL,
	StartDateTime DATETIME,
	ActualDuration DECIMAL,
	Status CHAR(1),
	CONSTRAINT PK_CustomerServiceSchedule PRIMARY KEY (CustomerID, ServiceTypeID, EmployeeID)
);
-- ROLAP CustomerServiceSchedule Facts
IF OBJECT_ID(N'dbo.Rolap_CustomerServiceSchedule_Facts', N'U') IS NOT NULL
    DROP TABLE dbo.Rolap_CustomerServiceSchedule_Facts;
GO
CREATE TABLE Rolap_CustomerServiceSchedule_Facts(
	CustomerID INT NOT NULL,
	ServiceTypeID INT NOT NULL,
	EmployeeID INT NOT NULL,
	StartDateTime DATETIME,
	ActualDuration DECIMAL,
	Status CHAR(1),
	CONSTRAINT PK_CustomerServiceSchedule PRIMARY KEY (CustomerID, ServiceTypeID, EmployeeID)
);


-- Create Triggers
CREATE TRIGGER Tr_CustomerAdded ON Customer
AFTER INSERT
AS 
BEGIN
	INSERT INTO dbo.Rolap_Customer_Dim SELECT * FROM INSERTED ins;
	PRINT 'Copied a customer'
END
GO

CREATE TRIGGER Tr_EmployeeAdded ON Employee
AFTER INSERT
AS BEGIN
	INSERT INTO dbo.Rolap_Employee_Dim SELECT * FROM INSERTED ins;
	PRINT 'Copied an employee'
END
GO

CREATE TRIGGER Tr_ServiceAdded ON ServiceType
AFTER INSERT
AS BEGIN
	INSERT INTO dbo.Rolap_Service_Dim SELECT * FROM INSERTED ins;
	PRINT 'Copied a service'
END
GO

CREATE TRIGGER Tr_CustomerServiceAdded ON CustomerService
AFTER INSERT
AS BEGIN
	INSERT INTO dbo.Rolap_CustomerServiceSchedule_Facts (CustomerID, ServiceTypeID, ActualDuration)
	SELECT CustomerID, ServiceTypeID, ExpectedDuration FROM INSERTED ins;
END
GO

CREATE TRIGGER Tr_CustomerServiceScheduleAdded ON CustomerServiceSchedule
AFTER INSERT
AS BEGIN
DECLARE 
	@EmployeeID INT,
	@StartDateTime Date,
	@ActualDuration Decimal(18,0),
	@Status Char(1);

	SELECT @EmployeeID = ins.EmployeeID FROM INSERTED ins;
	SELECT @StartDateTime = ins.StartDateTime FROM INSERTED ins;
	SELECT @ActualDuration = ins.ActualDuration FROM INSERTED ins;
	SELECT @Status = ins.Status FROM INSERTED ins;
	
	UPDATE [Rolap_CustomerServiceSchedule_Facts]
	SET EmployeeID = @EmployeeID,
		StartDateTime = @StartDateTime,
		ActualDuration = @ActualDuration,
		Status = @Status
	WHERE EmployeeID = @EmployeeID;
END
GO

-- TODO: - IF STATEMENT PROBABLY DOESN'T WORK ---------------------------------------------------------------------------------------
-- Insert Sample Data
IF ((SELECT COUNT(*) FROM dbo.Customer) = 0)
    -- Insert into Customer
	INSERT INTO Customer VALUES ('Tom Cruise', '123 Anywhere Street', '1970-01-01', NULL, 'M');
	INSERT INTO Customer VALUES ('Bill Paxton', '123 Anywhere Street', '1970-01-01', NULL, 'M');
	INSERT INTO Customer VALUES ('Bill Pullman', '123 Anywhere Street', '1970-01-01', NULL, 'M');
	INSERT INTO Customer VALUES ('Charlie Sheen', '123 Anywhere Street', '1970-01-01', NULL, 'M');
	INSERT INTO Customer VALUES ('Tom Sizemore', '123 Anywhere Street', '1970-01-01', NULL, 'M');
	GO

IF ((SELECT COUNT(*) FROM dbo.Employee) = 0)
	-- Insert into Employee
	INSERT INTO Employee VALUES ('Joe Biden', '1 Pensylvania Avenue', NULL, 'President', 'All',  DATEADD(year, -2, GETDATE()), 200000);
	INSERT INTO Employee VALUES ('Donal Trump', '1 Pensylvania Avenue', 1, 'President', 'All', DATEADD(year, -6, GETDATE()), 100000);
	INSERT INTO Employee VALUES ('Barrack Obama', '1 Pensylvania Avenue', 1, 'President', 'All', DATEADD(year, -14, GETDATE()), 100000);
	INSERT INTO Employee VALUES ('George Bush', '1 Pensylvania Avenue', 1, 'President', 'All', DATEADD(year, -22, GETDATE()), 100000);
	INSERT INTO Employee VALUES ('Bill Clinton', '1 Pensylvania Avenue', 1, 'President', 'All', DATEADD(year, -30, GETDATE()), 100000);
	GO

IF ((SELECT COUNT(*) FROM dbo.ServiceType) = 0)
	-- Insert into ServiceType
	INSERT INTO ServiceType VALUES ('Nursing', 'Nursing', 25);
	INSERT INTO ServiceType VALUES ('Medical', 'Medical', 45);
	INSERT INTO ServiceType VALUES ('Cleaning', 'Custodial', 15);
	INSERT INTO ServiceType VALUES ('Food Prep', 'Foodsafe', 20);
	INSERT INTO ServiceType VALUES ('Administration', NULL, 22);
	GO


;

