-- Implement consistent Accounts-then-Orders ordering in DeadlockDemo procedures
USE [DeadlockDemo];
GO

CREATE OR ALTER PROCEDURE [dbo].[usp_PayOrder]
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRAN;

    UPDATE dbo.Accounts
    SET Balance = Balance - 1
    WHERE AccountId = @id;

    UPDATE dbo.Orders
    SET Amount = Amount + 1
    WHERE OrderId = @id;

    COMMIT;
END;
GO

CREATE OR ALTER PROCEDURE [dbo].[usp_Refund.Order]
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRAN;

    UPDATE dbo.Accounts
    SET Balance = Balance + 1
    WHERE AccountId = @id;

    UPDATE dbo.Orders
    SET Amount = Amount - 1
    WHERE OrderId = @id;

    COMMIT;
END;
GO

-- Replace the DeadlockDemo ad hoc Orders-first transaction in the issuing application
USE [DeadlockDemo];
GO

BEGIN TRAN;

UPDATE dbo.Accounts
SET Balance = Balance + 5
WHERE AccountId = 2;

UPDATE dbo.Orders
SET Amount = Amount - 5
WHERE OrderId = 2;

COMMIT;
GO

-- Replace the WideWorldImporters state-first batch with country-first ordering
USE [WideWorldImporters];
GO

BEGIN TRAN;

UPDATE Application.Countries
SET LatestRecordedPopulation = LatestRecordedPopulation + 1,
    ValidFrom = SYSUTCDATETIME()
WHERE IsoNumericCode = 840;

UPDATE Application.StateProvinces
SET LatestRecordedPopulation = LatestRecordedPopulation + 1,
    ValidFrom = SYSUTCDATETIME()
WHERE StateProvinceCode = N'VA';

COMMIT;
GO

-- Replace the WideWorldImporters country-first batch with the standardized order
USE [WideWorldImporters];
GO

BEGIN TRAN;

UPDATE Application.Countries
SET LatestRecordedPopulation = LatestRecordedPopulation + 1,
    ValidFrom = SYSUTCDATETIME()
WHERE IsoNumericCode = 840;

UPDATE Application.StateProvinces
SET LatestRecordedPopulation = LatestRecordedPopulation + 1,
    ValidFrom = SYSUTCDATETIME()
WHERE StateProvinceCode = N'VA';

COMMIT;
GO

-- Replace the tempdb dl_a/dl_b test batches with one consistent order
USE [tempdb];
GO

BEGIN TRAN;

UPDATE dbo.dl_a
SET v = 1;

UPDATE dbo.dl_b
SET v = 1;

COMMIT;
GO

-- Use the same dl_a-then-dl_b order for the second tempdb test variant
USE [tempdb];
GO

BEGIN TRAN;

UPDATE dbo.dl_a
SET v = 2;

UPDATE dbo.dl_b
SET v = 2;

COMMIT;
GO

