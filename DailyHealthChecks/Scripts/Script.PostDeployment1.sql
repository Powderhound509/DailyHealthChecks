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
-- Add columnstore index to History Tables
-- SERVER UPTIME
CREATE CLUSTERED COLUMNSTORE INDEX IX_SQLUpTimeHistory
    ON SQLUpTimeHistory;
CREATE NONCLUSTERED INDEX IX_SQLUpTimeHistory_ID_PERIOD_COLUMNS
    ON SQLUpTimeHistory (SysEndTime, SysStartTime, recordId);
GO

-- DATABASE STATUS
CREATE CLUSTERED COLUMNSTORE INDEX IX_DatabaseStatusHistory
    ON DatabaseStatusHistory;
CREATE NONCLUSTERED INDEX IX_DatabaseStatusHistory_ID_PERIOD_COLUMNS
    ON DatabaseStatusHistory (SysEndTime, SysStartTime, recordId);
GO

-- AGStatus
CREATE CLUSTERED COLUMNSTORE INDEX IX_AGStatusHistory
    ON AGStatusHistory;
CREATE NONCLUSTERED INDEX IX_AGStatusHistory_ID_PERIOD_COLUMNS
    ON AGStatusHistory (SysEndTime, SysStartTime, recordId);
GO