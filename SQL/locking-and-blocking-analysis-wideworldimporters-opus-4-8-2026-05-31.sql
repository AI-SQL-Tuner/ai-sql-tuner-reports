-- 1. Diagnose the current blocking chain and idle open transactions (Recommendation #1)
USE [WideWorldImporters];
GO
-- Show waiting/blocking sessions and the lead blocker
SELECT  r.session_id, r.blocking_session_id, r.wait_type,
        r.wait_time AS wait_ms, r.command, s.status,
        DB_NAME(r.database_id) AS db_name,
        t.text AS sql_text
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id <> 0;
GO
-- Find idle sessions holding open transactions (no active request)
SELECT  s.session_id, s.status, s.last_request_end_time,
        at.transaction_begin_time,
        DATEDIFF(SECOND, at.transaction_begin_time, SYSDATETIME()) AS open_secs
FROM sys.dm_tran_session_transactions st
JOIN sys.dm_tran_active_transactions at ON at.transaction_id = st.transaction_id
JOIN sys.dm_exec_sessions s ON s.session_id = st.session_id
LEFT JOIN sys.dm_exec_requests r ON r.session_id = s.session_id
WHERE r.session_id IS NULL          -- no active request = idle in transaction
ORDER BY at.transaction_begin_time;
GO

-- 2. Release the orphaned lead blocker (Recommendation #1)
USE [WideWorldImporters];
GO
-- REVIEW the diagnostic output above FIRST.
-- SPID 62 is the idle lead blocker holding the X KEY lock on StateProvinces.
-- Killing it rolls back its single-row update automatically (no committed data lost).
KILL 62;
GO
-- If SPID 66 (the open SELECT transaction) remains and still blocks writers, release it too:
KILL 66;
GO

-- 3. Stored procedure enforcing consistent lock-acquisition order (Recommendation #2)
USE [WideWorldImporters];
GO
CREATE OR ALTER PROCEDURE Application.usp_BumpPopulation
    @CountryIso       SMALLINT,
    @StateProvinceCode NVARCHAR(5)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;   -- ensure full rollback on error

    BEGIN TRY
        BEGIN TRAN;
            -- FIXED ORDER: parent (Countries) first, then child (StateProvinces)
            UPDATE Application.Countries
                SET LatestRecordedPopulation = LatestRecordedPopulation + 1,
                    ValidFrom = SYSUTCDATETIME()
            WHERE IsoNumericCode = @CountryIso;

            UPDATE Application.StateProvinces
                SET LatestRecordedPopulation = LatestRecordedPopulation + 1,
                    ValidFrom = SYSUTCDATETIME()
            WHERE StateProvinceCode = @StateProvinceCode;
        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- 4. Enable Read Committed Snapshot Isolation (Recommendation #3)
USE [master];
GO
-- Requires a brief exclusive lock on the database; run during a quiet window.
ALTER DATABASE [WideWorldImporters]
    SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK AFTER 5 SECONDS;
GO
-- Verify
SELECT name, is_read_committed_snapshot_on
FROM sys.databases
WHERE name = N'WideWorldImporters';
GO
-- Rollback if needed:
-- ALTER DATABASE [WideWorldImporters] SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK AFTER 5 SECONDS;

-- 5. Create covering index on Application.Cities (Recommendation #4)
USE [WideWorldImporters];
GO
-- Online build available on this Enterprise engine.
CREATE NONCLUSTERED INDEX IX_Cities_StateProvinceID_inc_CityName
    ON Application.Cities (StateProvinceID)
    INCLUDE (CityName)
    WITH (ONLINE = ON, DATA_COMPRESSION = PAGE);
GO
-- Rollback:
-- DROP INDEX IX_Cities_StateProvinceID_inc_CityName ON Application.Cities;

-- 6. Session-level safety setting for ad-hoc / app sessions (Recommendation #5)
-- Run at the start of ad-hoc batches so stuck waiters fail fast instead of blocking forever.
SET LOCK_TIMEOUT 5000;  -- milliseconds
GO

