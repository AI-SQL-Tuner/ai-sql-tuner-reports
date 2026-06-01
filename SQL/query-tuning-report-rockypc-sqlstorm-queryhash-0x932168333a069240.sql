-- Script 1 — P1: Create NC index on Comments(PostId) INCLUDE (UserId)
USE [SQLStorm];
GO
-- P1: Eliminates the 15.07-cost Eager Spool and full Comments scans.
-- Plan-reported impact: 40.00%
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Comments')
      AND name = N'IX_Comments_PostId_INC_UserId'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Comments_PostId_INC_UserId
        ON dbo.Comments (PostId)
        INCLUDE (UserId)
        WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 100);
END;
GO
set statistics time on;
go
exec dbo.sp01116;
go
set statistics time off;

-- Script 2 — P2: Create NC index on Votes — filtered for VoteTypeId = 8
USE [SQLStorm];
GO
-- P2: Filtered index for bounty votes. Only ~1,478 of 926,084 rows match.
-- Plan-reported impact: 11.91%
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Votes')
      AND name = N'IX_Votes_PostId_INC_Bounty_FILT_VoteType8'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Votes_PostId_INC_Bounty_FILT_VoteType8
        ON dbo.Votes (PostId)
        INCLUDE (BountyAmount)
        WHERE VoteTypeId = 8
        WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 100);
END;
GO
-- NOTE: Sessions using this index must have:
--   SET QUOTED_IDENTIFIER ON;  SET ANSI_NULLS ON;
-- (These are default for SSMS, .NET SqlClient, ODBC modern drivers.)

-- Script 3a — P2: Create NC index on Posts(OwnerUserId) INCLUDE (CreationDate, Title) — full version
USE [SQLStorm];
GO
-- P2: Eliminates Posts CI scans on the OwnerUserId join path.
-- Plan-reported impact: 12.68%; DMV avg user impact up to 28.81%.
-- This version covers OwnerUserId + outputs needed (CreationDate, Title).
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Posts')
      AND name = N'IX_Posts_OwnerUserId_INC_CreationDate_Title'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Posts_OwnerUserId_INC_CreationDate_Title
        ON dbo.Posts (OwnerUserId)
        INCLUDE (CreationDate, Title)
        WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 100);
END;
GO

-- Script 3b — P2 (alternative narrow): Posts(OwnerUserId) INCLUDE (CreationDate) only
USE [SQLStorm];
GO
-- P2 ALTERNATIVE: Choose this OR Script 3a, not both.
-- Narrower index (no Title) -- smaller storage, lower write overhead,
-- but query will still need a key lookup for Title.
-- Use this version if write workload on Posts is heavy or storage is tight.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Posts')
      AND name = N'IX_Posts_OwnerUserId_INC_CreationDate'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Posts_OwnerUserId_INC_CreationDate
        ON dbo.Posts (OwnerUserId)
        INCLUDE (CreationDate)
        WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 100);
END;
GO

-- Script 4 — P2: Create NC index on Badges(UserId) INCLUDE (Class)
USE [SQLStorm];
GO
-- P2: Eliminates Badges CI scan; addresses high-impact DMV finding (76% impact).
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Badges')
      AND name = N'IX_Badges_UserId_INC_Class'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Badges_UserId_INC_Class
        ON dbo.Badges (UserId)
        INCLUDE (Class)
        WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 100);
END;
GO

-- Script 5 — Baseline / validation harness
USE [SQLStorm];
GO
-- Use this to capture before/after metrics. Run it BEFORE creating indexes,
-- then again AFTER each change, saving the messages tab output.
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SET NOCOUNT ON;
GO

-- Clear cache ONLY in a non-production / dev environment for clean comparison.
-- DBCC FREEPROCCACHE;  -- DEV ONLY
-- DBCC DROPCLEANBUFFERS; -- DEV ONLY

-- === ORIGINAL QUERY ===
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId, p.Title, p.CreationDate, p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM dbo.Posts p
    LEFT JOIN dbo.Comments c ON p.Id = c.PostId
    LEFT JOIN dbo.Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS datetime))
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(ISNULL(b.Class, 0)) AS TotalBadges
    FROM dbo.Users u
    LEFT JOIN dbo.Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN dbo.Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
ActiveUsers AS (
    SELECT ur.UserId, ur.Reputation, ur.PostCount, ur.TotalBadges,
           ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM UserReputation ur WHERE ur.PostCount > 5
)
SELECT rp.PostId, rp.Title, rp.CreationDate, ua.UserId, ua.Reputation,
       rp.CommentCount, rp.TotalBounty, ua.PostCount, ua.TotalBadges
FROM RankedPosts rp
JOIN ActiveUsers ua ON rp.OwnerUserId = ua.UserId
WHERE rp.TotalBounty > 0
   OR EXISTS (SELECT 1 FROM dbo.Comments c WHERE c.PostId = rp.PostId AND c.UserId IS NOT NULL)
ORDER BY ua.Reputation DESC, rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Script 6 — P1: Rewritten query (UNION + early filter for ActiveUsers)
USE [SQLStorm];
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SET NOCOUNT ON;
GO

-- === REWRITTEN QUERY ===
-- Changes:
--   (1) OR EXISTS -> two-branch UNION (removes the Eager Spool / Concatenation pattern)
--   (2) ActiveUsers pre-filters PostCount > 5 BEFORE joining Badges
--   (3) Removes unused PostRank / UserRank columns from final projection
WITH ActiveUserIds AS (
    -- Users with > 5 posts -- evaluated FIRST so Badges aggregation
    -- only runs for this much smaller set.
    SELECT p.OwnerUserId AS UserId
    FROM dbo.Posts p
    WHERE p.OwnerUserId IS NOT NULL
    GROUP BY p.OwnerUserId
    HAVING COUNT_BIG(*) > 5
),
ActiveUsers AS (
    SELECT u.Id           AS UserId,
           u.Reputation,
           ( SELECT COUNT_BIG(*) FROM dbo.Posts p2
             WHERE p2.OwnerUserId = u.Id )           AS PostCount,
           ( SELECT SUM(ISNULL(b.Class, 0)) FROM dbo.Badges b
             WHERE b.UserId = u.Id )                 AS TotalBadges
    FROM dbo.Users u
    WHERE u.Id IN (SELECT UserId FROM ActiveUserIds)
),
RankedPosts AS (
    SELECT
        p.Id AS PostId, p.Title, p.CreationDate, p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM dbo.Posts p
    LEFT JOIN dbo.Comments c ON p.Id = c.PostId
    LEFT JOIN dbo.Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS datetime))
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
Candidates AS (
    -- Branch A: posts with TotalBounty > 0
    SELECT rp.PostId, rp.Title, rp.CreationDate, rp.OwnerUserId,
           rp.CommentCount, rp.TotalBounty
    FROM RankedPosts rp
    WHERE rp.TotalBounty > 0

    UNION   -- dedupe by all output columns; PostId is unique within RankedPosts

    -- Branch B: posts that have at least one Comment with non-NULL UserId
    SELECT rp.PostId, rp.Title, rp.CreationDate, rp.OwnerUserId,
           rp.CommentCount, rp.TotalBounty
    FROM RankedPosts rp
    WHERE EXISTS (
        SELECT 1 FROM dbo.Comments c
        WHERE c.PostId = rp.PostId AND c.UserId IS NOT NULL
    )
)
SELECT  c.PostId, c.Title, c.CreationDate,
        ua.UserId, ua.Reputation,
        c.CommentCount, c.TotalBounty,
        ua.PostCount, ua.TotalBadges
FROM Candidates c
JOIN ActiveUsers ua ON c.OwnerUserId = ua.UserId
ORDER BY ua.Reputation DESC, c.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Script 7 — Verify new indexes are being used after deployment
USE [SQLStorm];
GO
-- Run 24-48 hours after deploying the new indexes.
-- 'user_seeks' should be > 0 for the indexes to be earning their keep.
SELECT  OBJECT_SCHEMA_NAME(i.object_id) AS [Schema],
        OBJECT_NAME(i.object_id)        AS [Table],
        i.name                          AS IndexName,
        s.user_seeks, s.user_scans, s.user_lookups, s.user_updates,
        s.last_user_seek, s.last_user_scan, s.last_user_update
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s
       ON s.object_id = i.object_id
      AND s.index_id  = i.index_id
      AND s.database_id = DB_ID()
WHERE i.name IN (
    N'IX_Comments_PostId_INC_UserId',
    N'IX_Votes_PostId_INC_Bounty_FILT_VoteType8',
    N'IX_Posts_OwnerUserId_INC_CreationDate_Title',
    N'IX_Posts_OwnerUserId_INC_CreationDate',
    N'IX_Badges_UserId_INC_Class'
)
ORDER BY [Table], IndexName;
GO

