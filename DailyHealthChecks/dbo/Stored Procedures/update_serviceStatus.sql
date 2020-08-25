create procedure update_serviceStatus (@serviceStatus serviceStatusType READONLY)
as BEGIN
	-- merge service status into table
	MERGE dbo.serviceStatus as [target]
	USING
		(
		SELECT 
			[server_name],
			[service_name],
			[startup_type_desc],
			[status_desc]
		FROM @serviceStatus
		) AS [source](
						[server_name],
						[service_name],
						[startup_type_desc],
						[status_desc]
					 )
		ON ([target].server_name = [source].server_name and
			[target].[service_name] = [source].[service_name])
		WHEN MATCHED
			THEN UPDATE SET
				[target].[startup_type_desc] = [source].[startup_type_desc],
				[target].[status_desc] = [source].[status_desc]
		WHEN NOT MATCHED THEN
			INSERT(
					[server_name],
					[service_name],
					[startup_type_desc],
					[status_desc]
				  )
			VALUES(
					[source].[server_name],
					[source].[service_name],
					[source].[startup_type_desc],
					[source].[status_desc]
				  );
	END