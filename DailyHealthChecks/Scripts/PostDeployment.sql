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
USE DailyHealthChecks
go

CREATE CLUSTERED COLUMNSTORE INDEX IX_backupStatusHistory
    ON backupStatusHistory;
CREATE NONCLUSTERED INDEX IX_backupStatusHistory_ID_PERIOD_COLUMNS
    ON backupStatusHistory (SysEndTime, SysStartTime, recordId);
GO

--diskSpaceHistory Columnstore Index
USE DailyHealthChecks
go

CREATE CLUSTERED COLUMNSTORE INDEX IX_diskSpaceHistory
    ON diskSpaceHistory;
CREATE NONCLUSTERED INDEX IX_diskSpaceHistory_ID_PERIOD_COLUMNS
    ON diskSpaceHistory (SysEndTime, SysStartTime, recordId);
GO

--jobStatusHistory Columnstore Index
USE DailyHealthChecks
go

CREATE CLUSTERED COLUMNSTORE INDEX IX_jobStatusHistory
    ON jobStatusHistory;
CREATE NONCLUSTERED INDEX IX_jobStatusHistory_ID_PERIOD_COLUMNS
    ON jobStatusHistory (SysEndTime, SysStartTime, recordId);
GO

--serviceStatusHistory Columnstore Index
USE DailyHealthChecks
go

CREATE CLUSTERED COLUMNSTORE INDEX IX_serviceStatusHistory
    ON serviceStatusHistory;
CREATE NONCLUSTERED INDEX IX_serviceStatusHistory_ID_PERIOD_COLUMNS
    ON serviceStatusHistory (SysEndTime, SysStartTime, recordId);
GO

--clusterStatusHistory Columnstore Index
USE DailyHealthChecks
go

CREATE CLUSTERED COLUMNSTORE INDEX IX_clusterStatusHistory
    ON clusterStatusHistory;
CREATE NONCLUSTERED INDEX IX_clusterStatusHistory_ID_PERIOD_COLUMNS
    ON clusterStatusHistory (SysEndTime, SysStartTime, recordId);
GO
-- SERVER UPTIME Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX IX_SQLUpTimeHistory
    ON SQLUpTimeHistory;
CREATE NONCLUSTERED INDEX IX_SQLUpTimeHistory_ID_PERIOD_COLUMNS
    ON SQLUpTimeHistory (SysEndTime, SysStartTime, recordId);
GO

-- DATABASE STATUS Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX IX_DatabaseStatusHistory
    ON DatabaseStatusHistory;
CREATE NONCLUSTERED INDEX IX_DatabaseStatusHistory_ID_PERIOD_COLUMNS
    ON DatabaseStatusHistory (SysEndTime, SysStartTime, recordId);
GO

-- AGStatus Columnstore Index
CREATE CLUSTERED COLUMNSTORE INDEX IX_AGStatusHistory
    ON AGStatusHistory;
CREATE NONCLUSTERED INDEX IX_AGStatusHistory_ID_PERIOD_COLUMNS
    ON AGStatusHistory (SysEndTime, SysStartTime, recordId);
GO