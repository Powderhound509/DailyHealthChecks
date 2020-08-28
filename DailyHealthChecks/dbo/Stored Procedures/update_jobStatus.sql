create procedure update_jobStatus (@jobStatus jobStatusType READONLY)
as begin
	-- merge jobStatus into table
	MERGE dbo.jobStatus as [target]
	USING
		(
		SELECT 
			 [server_name]
			,[job_name]
			,[current_run_status]
			,[last_start_date]
			,[last_stop_date]
			,[last_run_status]
			,[job_output]
		FROM @jobStatus
		) AS [source](
					 [server_name]
					,[job_name]
					,[current_run_status]
					,[last_start_date]
					,[last_stop_date]
					,[last_run_status]
					,[job_output]
					 )
		ON ([target].server_name = [source].server_name and
			[target].[job_name] = [source].[job_name])
		WHEN MATCHED
			THEN UPDATE SET
						 [target].[current_run_status]=[source].[current_run_status]
						,[target].[last_start_date]=[source].[last_start_date]   
						,[target].[last_stop_date]=[source].[last_stop_date]    
						,[target].[last_run_status]=[source].[last_run_status]   
						,[target].[job_output]=[source].[job_output]	
		WHEN NOT MATCHED THEN
			INSERT(
					[server_name]
					,[job_name]
					,[current_run_status]
					,[last_start_date]
					,[last_stop_date]
					,[last_run_status]
					,[job_output]
				  )
			VALUES(
					 [source].[server_name]
					,[source].[job_name]
					,[source].[current_run_status]
					,[source].[last_start_date]
					,[source].[last_stop_date]
					,[source].[last_run_status]
					,[source].[job_output]
				  );
end