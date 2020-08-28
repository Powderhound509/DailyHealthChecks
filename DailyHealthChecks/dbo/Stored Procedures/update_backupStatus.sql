create procedure update_backupStatus (@backupStatus backupStatusType READONLY)
as begin
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