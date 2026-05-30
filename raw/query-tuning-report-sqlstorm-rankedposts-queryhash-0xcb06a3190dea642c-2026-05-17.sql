-- Script 1 — Baseline measurement (run before changes)
USE [SQLStorm];
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SET NOCOUNT ON;
GO
-- Run the original query here and capture STATISTICS IO/TIME output and the actual plan.
-- (Paste the original query in this batch when executing the baseline.)
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Script 2 — Create supporting indexes (Recommendation #4)
USE [SQLStorm];
GO
-- Posts: support OwnerUserId joins, PostTypeId filter, and latest-post lookup.
CREATE NONCLUSTERED INDEX [IX_Posts_OwnerUserId_PostTypeId_INC_CreationDate_Title]
ON [dbo].[Posts] ([OwnerUserId], [PostTypeId])
INCLUDE ([CreationDate], [Title])
WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 90, SORT_IN_TEMPDB = ON);
GO

-- Votes: support PostId join with VoteTypeId aggregation.
CREATE NONCLUSTERED INDEX [IX_Votes_PostId_INC_VoteTypeId]
ON [dbo].[Votes] ([PostId])
INCLUDE ([VoteTypeId])
WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 95, SORT_IN_TEMPDB = ON);
GO

-- Badges: support UserId aggregation.
CREATE NONCLUSTERED INDEX [IX_Badges_UserId]
ON [dbo].[Badges] ([UserId])
WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 95, SORT_IN_TEMPDB = ON);
GO

-- Optional: Posts secondary covering index for PostTypeId-only scans (keep only if Option A LIKE rewrite is retained).
-- CREATE NONCLUSTERED INDEX [IX_Posts_PostTypeId_INC_OwnerUserId_CreationDate_Title]
-- ON [dbo].[Posts] ([PostTypeId])
-- INCLUDE ([OwnerUserId], [CreationDate], [Title])
-- WITH (ONLINE = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 90, SORT_IN_TEMPDB = ON);
-- GO

-- Script 3 — Rewritten query (Recommendations #1, #2, #3, #5)
USE [SQLStorm];
GO
-- Rewritten version: pre-aggregates, removes LIKE join, fixes UserId/PostId mismatch by
-- joining latest post per user via OwnerUserId. Adjust if the original intent was latest-per-tag.
WITH UserLatestPost AS (
    SELECT  p.OwnerUserId,
            p.Id            AS PostId,
            p.Title,
            p.CreationDate,
            ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId
                               ORDER BY p.CreationDate DESC) AS rn
    FROM    dbo.Posts p
    WHERE   p.PostTypeId  = 1
      AND   p.OwnerUserId IS NOT NULL
),
PostAgg AS (
    SELECT  p.OwnerUserId, COUNT(*) AS TotalPosts
    FROM    dbo.Posts p
    WHERE   p.OwnerUserId IS NOT NULL
    GROUP BY p.OwnerUserId
),
VoteAgg AS (
    SELECT  p.OwnerUserId,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM    dbo.Posts p
    JOIN    dbo.Votes v ON v.PostId = p.Id
    GROUP BY p.OwnerUserId
),
BadgeAgg AS (
    SELECT  b.UserId, COUNT(*) AS BadgeCount
    FROM    dbo.Badges b
    GROUP BY b.UserId
),
TopUsers AS (
    SELECT  u.Id          AS UserId,
            u.DisplayName,
            pa.TotalPosts,
            ISNULL(va.UpVotes,   0) AS UpVotes,
            ISNULL(va.DownVotes, 0) AS DownVotes,
            ISNULL(ba.BadgeCount,0) AS BadgeCount,
            DENSE_RANK() OVER (ORDER BY pa.TotalPosts DESC,
                                       ISNULL(va.UpVotes,0) - ISNULL(va.DownVotes,0) DESC) AS UserRank
    FROM    dbo.Users u
    JOIN    PostAgg   pa ON pa.OwnerUserId = u.Id
    LEFT JOIN VoteAgg  va ON va.OwnerUserId = u.Id
    LEFT JOIN BadgeAgg ba ON ba.UserId      = u.Id
    WHERE   pa.TotalPosts > 10
)
SELECT  tp.UserRank,
        tp.DisplayName,
        tp.TotalPosts,
        tp.UpVotes,
        tp.DownVotes,
        tp.BadgeCount,
        rp.Title        AS LatestPostTitle,
        rp.CreationDate AS LatestPostDate,
        CASE WHEN rp.rn = 1 THEN 'Latest' ELSE 'Older' END AS PostStatus
FROM    TopUsers tp
LEFT JOIN UserLatestPost rp
       ON rp.OwnerUserId = tp.UserId
      AND rp.rn = 1
ORDER BY tp.UserRank;
GO

-- Script 4 — Alternative rewrite preserving Tags semantics via STRING_SPLIT (Recommendation #1, Option A)
USE [SQLStorm];
GO
-- Use this variant only if the original "latest post per Tag" semantics are required.
-- Replaces the non-sargable LIKE join with STRING_SPLIT against the Tags column.
WITH RankedPosts AS (
    SELECT  p.Id           AS PostId,
            p.Title,
            p.CreationDate,
            t.Id            AS TagId,
            t.TagName,
            ROW_NUMBER() OVER (PARTITION BY t.Id ORDER BY p.CreationDate DESC) AS rn
    FROM    dbo.Posts p
    CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(p.Tags, '>', ''), '<', '|'), '|') s
    JOIN    dbo.Tags t ON t.TagName = s.value
    WHERE   p.PostTypeId = 1
      AND   s.value <> ''
)
SELECT TagId, TagName, PostId, Title, CreationDate
FROM   RankedPosts
WHERE  rn = 1
ORDER BY TagName;
GO

-- Script 5 — Optional: enable async auto-update stats (Recommendation #6)
USE [master];
GO
ALTER DATABASE [SQLStorm] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT;
GO

-- Script 6 — Post-change validation
USE [SQLStorm];
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SET NOCOUNT ON;
GO
-- Re-run the rewritten query (Script 3) here and capture STATISTICS IO/TIME + actual plan.
-- Compare logical reads on Posts/Votes/Badges and elapsed time against the baseline (Script 1).
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Script 7 — Rollback (drop new indexes if needed)
USE [SQLStorm];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Posts_OwnerUserId_PostTypeId_INC_CreationDate_Title' AND object_id = OBJECT_ID('dbo.Posts'))
    DROP INDEX [IX_Posts_OwnerUserId_PostTypeId_INC_CreationDate_Title] ON [dbo].[Posts];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Votes_PostId_INC_VoteTypeId' AND object_id = OBJECT_ID('dbo.Votes'))
    DROP INDEX [IX_Votes_PostId_INC_VoteTypeId] ON [dbo].[Votes];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Badges_UserId' AND object_id = OBJECT_ID('dbo.Badges'))
    DROP INDEX [IX_Badges_UserId] ON [dbo].[Badges];
GO

