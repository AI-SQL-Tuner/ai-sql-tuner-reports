-- Create the primary recommended index on dbo.Votes for PostId/VoteTypeId aggregation and bounty coverage (Recommendation 1)
USE [SQLStorm];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[dbo].[Votes]')
      AND name = N'IX_Votes_PostId_VoteTypeId_INC_BountyAmount'
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Votes_PostId_VoteTypeId_INC_BountyAmount]
    ON [dbo].[Votes] ([PostId], [VoteTypeId])
    INCLUDE ([BountyAmount])
    WITH
    (
        DATA_COMPRESSION = PAGE,
        FILLFACTOR = 100,
        SORT_IN_TEMPDB = ON,
        ONLINE = ON
    );
END
GO

-- Create an optional filtered bounty index for VoteTypeId 8 and 9 by PostId if bounty-only queries remain hot after Recommendation 1 (Recommendation 2)
USE [SQLStorm];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[dbo].[Votes]')
      AND name = N'IX_Votes_PostId_BountyAmount_VT_8_9'
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Votes_PostId_BountyAmount_VT_8_9]
    ON [dbo].[Votes] ([PostId])
    INCLUDE ([BountyAmount])
    WHERE [VoteTypeId] IN (8, 9)
    WITH
    (
        DATA_COMPRESSION = PAGE,
        FILLFACTOR = 100,
        SORT_IN_TEMPDB = ON,
        ONLINE = ON
    );
END
GO

-- Validate whether the new Votes indexes are being used and whether either index should be retained or removed after observation window (supports Recommendations 1 and 2)
USE [SQLStorm];
GO

SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName,
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc,
    us.user_seeks,
    us.user_scans,
    us.user_lookups,
    us.user_updates,
    us.last_user_seek,
    us.last_user_scan,
    us.last_user_update
FROM sys.indexes AS i
LEFT JOIN sys.dm_db_index_usage_stats AS us
    ON us.database_id = DB_ID()
   AND us.object_id = i.object_id
   AND us.index_id = i.index_id
WHERE i.object_id = OBJECT_ID(N'[dbo].[Votes]')
ORDER BY i.index_id;
GO

-- Drop the optional filtered bounty index if it proves redundant after monitoring (rollback for Recommendation 2)
USE [SQLStorm];
GO

IF EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[dbo].[Votes]')
      AND name = N'IX_Votes_PostId_BountyAmount_VT_8_9'
)
BEGIN
    DROP INDEX [IX_Votes_PostId_BountyAmount_VT_8_9]
    ON [dbo].[Votes];
END
GO

-- Drop the primary recommended PostId/VoteTypeId index if rollback is required (rollback for Recommendation 1)
USE [SQLStorm];
GO

IF EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[dbo].[Votes]')
      AND name = N'IX_Votes_PostId_VoteTypeId_INC_BountyAmount'
)
BEGIN
    DROP INDEX [IX_Votes_PostId_VoteTypeId_INC_BountyAmount]
    ON [dbo].[Votes];
END
GO

