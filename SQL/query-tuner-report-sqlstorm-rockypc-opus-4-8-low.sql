-- Script 1 + 5 — Rewrite query: pre-aggregate comment indicator, remove Eager Spool (Recs 1 & 5)
USE [SQLStorm];
GO
WITH RankedPosts AS (
    SELECT
        p.Id            AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id)     AS CommentCount,
        MAX(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) AS HasUserComment,
        SUM(v.BountyAmount) AS TotalBounty
    FROM dbo.Posts p
    LEFT JOIN dbo.Comments c ON p.Id = c.PostId
    LEFT JOIN dbo.Votes    v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS datetime))
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id)        AS PostCount,
        SUM(ISNULL(b.Class, 0))     AS TotalBadges
    FROM dbo.Users u
    LEFT JOIN dbo.Posts  p ON u.Id = p.OwnerUserId
    LEFT JOIN dbo.Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
ActiveUsers AS (
    SELECT UserId, Reputation, PostCount, TotalBadges
    FROM UserReputation
    WHERE PostCount > 5
)
SELECT
    rp.PostId, rp.Title, rp.CreationDate,
    ua.UserId, ua.Reputation,
    rp.CommentCount, rp.TotalBounty,
    ua.PostCount, ua.TotalBadges
FROM RankedPosts rp
JOIN ActiveUsers ua ON rp.OwnerUserId = ua.UserId
WHERE rp.TotalBounty > 0
   OR rp.HasUserComment = 1     -- replaces correlated EXISTS / Eager Spool
ORDER BY ua.Reputation DESC, rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
GO

-- Script 2 — Comments supporting index (Rec 2)
USE [SQLStorm];
GO
CREATE NONCLUSTERED INDEX IX_Comments_PostId_inclUserId
    ON dbo.Comments (PostId)
    INCLUDE (UserId)
    WITH (DATA_COMPRESSION = PAGE, ONLINE = ON);
GO

-- Script 3 — Votes filtered index for VoteTypeId = 8 (Rec 3)
USE [SQLStorm];
GO
-- NOTE: sessions performing DML on dbo.Votes must have ARITHABORT ON
-- (and the other required SET options) for filtered-index maintenance.
CREATE NONCLUSTERED INDEX IX_Votes_Bounty8_PostId
    ON dbo.Votes (PostId)
    INCLUDE (BountyAmount)
    WHERE VoteTypeId = 8
    WITH (DATA_COMPRESSION = PAGE, ONLINE = ON);
GO

-- Script 4 — Posts OwnerUserId index (Rec 4, start with key-only)
USE [SQLStorm];
GO
CREATE NONCLUSTERED INDEX IX_Posts_OwnerUserId
    ON dbo.Posts (OwnerUserId)
    WITH (DATA_COMPRESSION = PAGE, ONLINE = ON);
GO

-- Optional covering variant for the RankedPosts branch (evaluate storage first):
-- CREATE NONCLUSTERED INDEX IX_Posts_OwnerUserId_cover
--     ON dbo.Posts (OwnerUserId)
--     INCLUDE (CreationDate, Title)
--     WITH (DATA_COMPRESSION = PAGE, ONLINE = ON);
-- GO

-- Script 6 — Optional Badges UserId index (Rec 6)
USE [SQLStorm];
GO
CREATE NONCLUSTERED INDEX IX_Badges_UserId_inclClass
    ON dbo.Badges (UserId)
    INCLUDE (Class)
    WITH (DATA_COMPRESSION = PAGE, ONLINE = ON);
GO

-- Script 7 — Validation harness (run before and after)
USE [SQLStorm];
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
-- Execute the rewritten query from Script 1 here, capture reads/time, compare.
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

