-- Create nonclustered index on dbo.PostHistory for post and recent-history access (Recommendation P1)
USE [SQLStorm];
GO
CREATE NONCLUSTERED INDEX [IX_PostHistory_PostId_CreationDate]
ON [dbo].[PostHistory] ([PostId] ASC, [CreationDate] ASC)
INCLUDE ([PostHistoryTypeId])
WITH (
    ONLINE = ON,
    DATA_COMPRESSION = PAGE,
    SORT_IN_TEMPDB = ON,
    FILLFACTOR = 100
);
GO

-- Create filtered nonclustered index on dbo.Votes for common per-post analytical vote types (Recommendation P1)
USE [SQLStorm];
GO
CREATE NONCLUSTERED INDEX [IX_Votes_PostId_VoteTypeId_Analytics]
ON [dbo].[Votes] ([PostId] ASC, [VoteTypeId] ASC)
INCLUDE ([BountyAmount])
WHERE [VoteTypeId] IN (2, 3, 8, 9)
WITH (
    ONLINE = ON,
    DATA_COMPRESSION = PAGE,
    SORT_IN_TEMPDB = ON,
    FILLFACTOR = 100
);
GO

-- Create nonclustered index on dbo.Comments for post comment counting and recent comment access (Recommendation P1)
USE [SQLStorm];
GO
CREATE NONCLUSTERED INDEX [IX_Comments_PostId_CreationDate]
ON [dbo].[Comments] ([PostId] ASC, [CreationDate] ASC)
WITH (
    ONLINE = ON,
    DATA_COMPRESSION = PAGE,
    SORT_IN_TEMPDB = ON,
    FILLFACTOR = 100
);
GO

-- Create nonclustered index on dbo.Badges for user badge aggregation and lookup coverage (Recommendation P2)
USE [SQLStorm];
GO
CREATE NONCLUSTERED INDEX [IX_Badges_UserId]
ON [dbo].[Badges] ([UserId] ASC)
INCLUDE ([Class], [Name], [Date])
WITH (
    ONLINE = ON,
    DATA_COMPRESSION = PAGE,
    SORT_IN_TEMPDB = ON,
    FILLFACTOR = 100
);
GO

-- Create optional filtered nonclustered index on dbo.Votes for user-centric vote and bounty rollups (Recommendation P3)
USE [SQLStorm];
GO
CREATE NONCLUSTERED INDEX [IX_Votes_UserId_NotNull]
ON [dbo].[Votes] ([UserId] ASC)
INCLUDE ([VoteTypeId], [BountyAmount], [PostId])
WHERE [UserId] IS NOT NULL
WITH (
    ONLINE = ON,
    DATA_COMPRESSION = PAGE,
    SORT_IN_TEMPDB = ON,
    FILLFACTOR = 100
);
GO

-- Refresh statistics on affected tables after index deployment (Recommendation P3)
USE [SQLStorm];
GO
UPDATE STATISTICS [dbo].[PostHistory] WITH FULLSCAN;
UPDATE STATISTICS [dbo].[Votes] WITH FULLSCAN;
UPDATE STATISTICS [dbo].[Comments] WITH FULLSCAN;
UPDATE STATISTICS [dbo].[Badges] WITH FULLSCAN;
UPDATE STATISTICS [dbo].[Users] WITH FULLSCAN;
GO

-- Validation query to measure usage of newly created indexes after deployment
USE [SQLStorm];
GO
SELECT
    OBJECT_SCHEMA_NAME(i.[object_id], DB_ID()) AS [schema_name],
    OBJECT_NAME(i.[object_id], DB_ID()) AS [table_name],
    i.[name] AS [index_name],
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan,
    ius.last_user_update
FROM sys.indexes AS i
LEFT JOIN sys.dm_db_index_usage_stats AS ius
    ON i.[object_id] = ius.[object_id]
   AND i.[index_id] = ius.[index_id]
   AND ius.[database_id] = DB_ID()
WHERE i.[name] IN (
    N'IX_PostHistory_PostId_CreationDate',
    N'IX_Votes_PostId_VoteTypeId_Analytics',
    N'IX_Comments_PostId_CreationDate',
    N'IX_Badges_UserId',
    N'IX_Votes_UserId_NotNull'
)
ORDER BY [table_name], [index_name];
GO

-- Rollback script to remove only the recommended nonclustered indexes if needed
USE [SQLStorm];
GO
IF EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_PostHistory_PostId_CreationDate' AND [object_id] = OBJECT_ID(N'dbo.PostHistory'))
    DROP INDEX [IX_PostHistory_PostId_CreationDate] ON [dbo].[PostHistory];
IF EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Votes_PostId_VoteTypeId_Analytics' AND [object_id] = OBJECT_ID(N'dbo.Votes'))
    DROP INDEX [IX_Votes_PostId_VoteTypeId_Analytics] ON [dbo].[Votes];
IF EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Comments_PostId_CreationDate' AND [object_id] = OBJECT_ID(N'dbo.Comments'))
    DROP INDEX [IX_Comments_PostId_CreationDate] ON [dbo].[Comments];
IF EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Badges_UserId' AND [object_id] = OBJECT_ID(N'dbo.Badges'))
    DROP INDEX [IX_Badges_UserId] ON [dbo].[Badges];
IF EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = N'IX_Votes_UserId_NotNull' AND [object_id] = OBJECT_ID(N'dbo.Votes'))
    DROP INDEX [IX_Votes_UserId_NotNull] ON [dbo].[Votes];
GO

