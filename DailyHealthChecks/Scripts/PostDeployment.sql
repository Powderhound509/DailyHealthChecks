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
/*
-- Copyright (c) Microsoft Corporation.
-- Licensed under the MIT License.

This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object 
code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, 
that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within 
the Premier Customer Services Description.
  
Microsoft, SQL Server, Windows, Window Server are either registered trademarks or trademarks of Microsoft Corporation in 
the United States and/or other countries.

The names of actual companies and products mentioned herein may be the trademarks of their respective owners.

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