/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
--backupHistory Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX IX_backupStatusHistory
    ON backupStatusHistory;
GO
CREATE NONCLUSTERED INDEX IX_backupStatusHistory_ID_PERIOD_COLUMNS
    ON backupStatusHistory (SysEndTime, SysStartTime, recordId);
GO
--diskSpaceHistory Columnstore Index

CREATE CLUSTERED COLUMNSTORE INDEX IX_diskSpaceHistory
    ON diskSpaceHistory;
GO
CREATE NONCLUSTERED INDEX IX_diskSpaceHistory_ID_PERIOD_COLUMNS
    ON diskSpaceHistory (SysEndTime, SysStartTime, recordId);
GO
--jobStatusHistory Columnstore Index

CREATE CLUSTERED COLUMNSTORE INDEX IX_jobStatusHistory
    ON jobStatusHistory;
GO
CREATE NONCLUSTERED INDEX IX_jobStatusHistory_ID_PERIOD_COLUMNS
    ON jobStatusHistory (SysEndTime, SysStartTime, recordId);
GO
--serviceStatusHistory Columnstore Index

CREATE CLUSTERED COLUMNSTORE INDEX IX_serviceStatusHistory
    ON serviceStatusHistory;
GO
CREATE NONCLUSTERED INDEX IX_serviceStatusHistory_ID_PERIOD_COLUMNS
    ON serviceStatusHistory (SysEndTime, SysStartTime, recordId);
GO
--clusterStatusHistory Columnstore Index

CREATE CLUSTERED COLUMNSTORE INDEX IX_clusterStatusHistory
    ON clusterStatusHistory;
GO
CREATE NONCLUSTERED INDEX IX_clusterStatusHistory_ID_PERIOD_COLUMNS
    ON clusterStatusHistory (SysEndTime, SysStartTime, recordId);
GO
-- SERVER UPTIME Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX IX_SQLUpTimeHistory
    ON SQLUpTimeHistory;
GO
CREATE NONCLUSTERED INDEX IX_SQLUpTimeHistory_ID_PERIOD_COLUMNS
    ON SQLUpTimeHistory (SysEndTime, SysStartTime, recordId);
GO
-- DATABASE STATUS Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX IX_DatabaseStatusHistory
    ON DatabaseStatusHistory;
GO
CREATE NONCLUSTERED INDEX IX_DatabaseStatusHistory_ID_PERIOD_COLUMNS
    ON DatabaseStatusHistory (SysEndTime, SysStartTime, recordId);
GO
-- AGStatus Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX IX_AGStatusHistory
    ON AGStatusHistory;
GO
CREATE NONCLUSTERED INDEX IX_AGStatusHistory_ID_PERIOD_COLUMNS
    ON AGStatusHistory (SysEndTime, SysStartTime, recordId);
GO