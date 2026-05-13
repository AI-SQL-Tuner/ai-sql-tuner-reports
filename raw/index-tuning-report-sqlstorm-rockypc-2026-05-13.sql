-- Script 1 — Create NCI on dbo.PostHistory(PostId) [Recommendation #1]
USE [SQLStorm];
GO

-- Recommendation #1: Nonclustered index on PostHistory(PostId)
-- Addresses missing index with avg cost 29,307, 99.6% improvement
-- Covers join patterns and PostHistoryTypeId filter used in multiple high-CPU queries
-- PAGE compression matches existing clustered index; ONLINE = ON avoids blocking
CREATE NONCLUSTERED INDEX [IX_PostHistory_PostId_Covering]
ON [dbo].[PostHistory] ([PostId])
INCLUDE ([PostHistoryTypeId], [UserId], [CreationDate], [Comment])
WITH (
    DATA_COMPRESSION = PAGE,
    FILLFACTOR = 90,
    ONLINE = ON,
    SORT_IN_TEMPDB = ON
);
GO

-- Script 2 — Create NCI on dbo.Votes(PostId) [Recommendation #2]
USE [SQLStorm];
GO

-- Recommendation #2: Nonclustered index on Votes(PostId)
-- Addresses 315 full clustered index scans, covers conditional aggregation on VoteTypeId
-- Includes UserId and BountyAmount to cover all observed query projections
-- PAGE compression matches existing clustered index
CREATE NONCLUSTERED INDEX [IX_Votes_PostId_Covering]
ON [dbo].[Votes] ([PostId])
INCLUDE ([VoteTypeId], [UserId], [BountyAmount], [CreationDate])
WITH (
    DATA_COMPRESSION = PAGE,
    FILLFACTOR = 90,
    ONLINE = ON,
    SORT_IN_TEMPDB = ON
);
GO

-- Script 3 — Create Filtered NCI on dbo.Votes(UserId) [Recommendation #3]
USE [SQLStorm];
GO

-- Recommendation #3: Filtered nonclustered index on Votes(UserId)
-- Addresses missing index recommendation (avg cost 3,255, 99.4% impact)
-- Filtered on UserId IS NOT NULL: excludes anonymous votes (~90%+ of rows)
-- making the index significantly smaller and more selective
-- Covers LEFT JOIN Votes v ON u.Id = v.UserId patterns in UserActivity/UserScore queries
CREATE NONCLUSTERED INDEX [IX_Votes_UserId_Filtered_Covering]
ON [dbo].[Votes] ([UserId])
INCLUDE ([VoteTypeId], [BountyAmount], [PostId], [CreationDate])
WHERE [UserId] IS NOT NULL
WITH (
    DATA_COMPRESSION = PAGE,
    FILLFACTOR = 90,
    ONLINE = ON,
    SORT_IN_TEMPDB = ON
);
GO

-- Script 4 — Create NCI on dbo.Posts(CreationDate) [Recommendation #4]
USE [SQLStorm];
GO

-- Recommendation #4: Nonclustered index on Posts(CreationDate)
-- Supports date-range filters present in ~12 distinct queries in the workload
-- e.g. WHERE p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
-- Wide INCLUDE covers most projected columns to avoid key lookups to the clustered index
CREATE NONCLUSTERED INDEX [IX_Posts_CreationDate_Covering]
ON [dbo].[Posts] ([CreationDate])
INCLUDE (
    [Id],
    [OwnerUserId],
    [PostTypeId],
    [Score],
    [ViewCount],
    [Title],
    [AnswerCount],
    [AcceptedAnswerId],
    [CommentCount],
    [ParentId]
)
WITH (
    DATA_COMPRESSION = PAGE,
    FILLFACTOR = 90,
    ONLINE = ON,
    SORT_IN_TEMPDB = ON
);
GO

-- Script 5 — Create NCI on dbo.Comments(PostId) [Recommendation #5]
USE [SQLStorm];
GO

-- Recommendation #5: Nonclustered index on Comments(PostId)
-- Eliminates 196 full clustered index scans on Comments (351K rows, 78MB)
-- Covers COUNT(*) subqueries and LEFT JOIN Comments c ON p.Id = c.PostId patterns
-- Includes columns needed for aggregation without clustered index lookups
CREATE NONCLUSTERED INDEX [IX_Comments_PostId_Covering]
ON [dbo].[Comments] ([PostId])
INCLUDE ([Id], [UserId], [CreationDate], [Score])
WITH (
    DATA_COMPRESSION = PAGE,
    FILLFACTOR = 90,
    ONLINE = ON,
    SORT_IN_TEMPDB = ON
);
GO

-- Script 6 — Create NCI on dbo.Badges(UserId) [Recommendation #6]
USE [SQLStorm];
GO

-- Recommendation #6: Nonclustered index on Badges(UserId)
-- Eliminates 164 full clustered index scans on Badges (439K rows, 8MB)
-- Covers LEFT JOIN Badges B ON U.Id = B.UserId with Class aggregation patterns
CREATE NONCLUSTERED INDEX [IX_Badges_UserId_Covering]
ON [dbo].[Badges] ([UserId])
INCLUDE ([Class], [Date], [Name], [Id])
WITH (
    DATA_COMPRESSION = PAGE,
    FILLFACTOR = 90,
    ONLINE = ON,
    SORT_IN_TEMPDB = ON
);
GO

-- Script 7 — Enable Auto Update Statistics Asynchronously [Recommendation #10]
USE [master];
GO

-- Recommendation #10: Enable async statistics updates for SQLStorm
-- Prevents query compilation stalls when auto-update is triggered on large tables
-- Queries will compile using slightly stale statistics while update runs in background
ALTER DATABASE [SQLStorm]
SET AUTO_UPDATE_STATISTICS_ASYNC ON
WITH NO_WAIT;
GO

-- Verify the setting
SELECT name, is_auto_update_stats_async_on
FROM sys.databases
WHERE name = 'SQLStorm';
GO

-- Script 8 — Update Statistics with FULLSCAN After Index Creation [Recommendation #6 / General]
USE [SQLStorm];
GO

-- Run after deploying new indexes (Scripts 1-6)
-- FULLSCAN ensures accurate cardinality estimates for large tables
-- where sampled auto-update may produce imprecise histograms

UPDATE STATISTICS [dbo].[Votes] WITH FULLSCAN;
GO

UPDATE STATISTICS [dbo].[PostHistory] WITH FULLSCAN;
GO

UPDATE STATISTICS [dbo].[Posts] WITH FULLSCAN;
GO

UPDATE STATISTICS [dbo].[Comments] WITH FULLSCAN;
GO

UPDATE STATISTICS [dbo].[Badges] WITH FULLSCAN;
GO

-- Script 9 — Rewrite Correlated Subquery Pattern [Recommendation #7]
USE [SQLStorm];
GO

-- Recommendation #7: Example rewrite of correlated subquery pattern
-- Original pattern (query hash F50DF27C41C97904 / EE4BAB640222BBF0):
--   SELECT ... COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0)
--            , COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0)
--            , COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0)
--   FROM Posts p WHERE p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')
--
-- REWRITTEN using pre-aggregated CTEs (eliminates O(n) correlated subquery fan-out):

WITH FilteredPosts AS (
    SELECT
        p.Id       AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId
    FROM dbo.Posts AS p
    WHERE p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')
),
CommentAgg AS (
    SELECT c.PostId, COUNT(*) AS CommentCount
    FROM dbo.Comments AS c
    WHERE EXISTS (
        SELECT 1 FROM FilteredPosts fp WHERE fp.PostId = c.PostId
    )
    GROUP BY c.PostId
),
VoteAgg AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM dbo.Votes AS v
    WHERE v.VoteTypeId IN (2, 3)
      AND EXISTS (
          SELECT 1 FROM FilteredPosts fp WHERE fp.PostId = v.PostId
      )
    GROUP BY v.PostId
)
SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    COALESCE(ca.CommentCount, 0) AS CommentCount,
    COALESCE(va.UpVotes,       0) AS UpVotes,
    COALESCE(va.DownVotes,     0) AS DownVotes
FROM FilteredPosts AS fp
LEFT JOIN CommentAgg AS ca ON fp.PostId = ca.PostId
LEFT JOIN VoteAgg    AS va ON fp.PostId = va.PostId
ORDER BY fp.Score DESC;
GO

-- Script 10 — Fix Logic Bug: Duplicate Badge Class Count [Recommendation #7 / Code Correction]
USE [SQLStorm];
GO

-- Recommendation #7 (Code fix): Query hash 6DA5B718F2D3A8A5
-- Original (INCORRECT - all three columns return identical counts because
--           COUNT(b.Id) ignores the JOIN filter by class):
--
--   FROM Users u LEFT JOIN Badges b ON u.Id = b.UserId AND b.Class = 1
--   SELECT COUNT(b.Id) AS GoldBadges,
--          COUNT(b.Id) AS SilverBadges,   -- WRONG: same as GoldBadges
--          COUNT(b.Id) AS BronzeBadges    -- WRONG: same as GoldBadges
--
-- CORRECTED version using conditional aggregation (no join filter by class):

WITH UserBadges AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(b.Id)                                   AS TotalBadges
    FROM dbo.Users AS u
    LEFT JOIN dbo.Badges AS b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT
    ub.UserId,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ub.TotalBadges
FROM UserBadges AS ub
ORDER BY ub.GoldBadges DESC;
GO

-- Script 11 — Verify New Indexes Are Being Used (Post-Deployment Check)
USE [SQLStorm];
GO

-- Run after workload executes against new indexes
-- Check that new indexes are accumulating seeks (not being ignored by optimizer)
SELECT
    OBJECT_NAME(ix.object_id)     AS TableName,
    ix.name                       AS IndexName,
    ix.type_desc                  AS IndexType,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan
FROM sys.indexes AS ix
INNER JOIN sys.dm_db_index_usage_stats AS ius
    ON ix.object_id = ius.object_id
    AND ix.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE OBJECT_NAME(ix.object_id) IN (
    'PostHistory', 'Votes', 'Posts', 'Comments', 'Badges'
)
  AND ix.name IN (
    'IX_PostHistory_PostId_Covering',
    'IX_Votes_PostId_Covering',
    'IX_Votes_UserId_Filtered_Covering',
    'IX_Posts_CreationDate_Covering',
    'IX_Comments_PostId_Covering',
    'IX_Badges_UserId_Covering'
  )
ORDER BY TableName, IndexName;
GO

