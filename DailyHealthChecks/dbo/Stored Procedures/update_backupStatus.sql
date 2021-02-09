create procedure update_backupStatus (@backupStatus backupStatusType READONLY)
as begin
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
	-- merge status into table
	MERGE dbo.backupStatus AS [target]
	USING 
		(--select all records from the incoming tableVar
		select
		 [server_name]
		,[database_name]
		,[recovery_model_desc]
		,[last_full_backup]
		,[last_differential_backup]
		,[last_tlog_backup]
		,[backup_status]
		,[status_desc]
		FROM @backupStatus 
		) AS [source](--repeating column names from select for consistency
					  [server_name]
					 ,[database_name]
					 ,[recovery_model_desc]
					 ,[last_full_backup]
					 ,[last_differential_backup]
					 ,[last_tlog_backup]
					 ,[backup_status]
					 ,[status_desc]
					 )
		-- Join Criteria varies from table to table
		ON ([target].server_name = [source].server_name and
			[target].[database_name] = [source].[database_name])
		WHEN MATCHED -- We may want to consider additional logic to deal with records that haven't changed from one check to the next (stale backups for example)
			THEN UPDATE SET
						[target].[recovery_model_desc]=[source].[recovery_model_desc],
						[target].[last_full_backup]=[source].[last_full_backup],
						[target].[last_differential_backup]=[source].[last_differential_backup],
						[target].[last_tlog_backup]=[source].[last_tlog_backup],
						[target].[backup_status]=[source].[backup_status],
						[target].[status_desc]=[source].[status_desc]
		WHEN NOT MATCHED THEN
			INSERT	( -- If there weren't any matches, then this is a new server/item combo and we need to add it.
					 [server_name]
					,[database_name]
					,[recovery_model_desc]
					,[last_full_backup]
					,[last_differential_backup]
					,[last_tlog_backup]
					,[backup_status]
					,[status_desc]
					)
			VALUES	(
					 [source].[server_name]
					,[source].[database_name]
					,[source].[recovery_model_desc]
					,[source].[last_full_backup]
					,[source].[last_differential_backup]
					,[source].[last_tlog_backup]
					,[source].[backup_status]
					,[source].[status_desc]
					);
end