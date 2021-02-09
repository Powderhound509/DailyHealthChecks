CREATE procedure [dbo].[update_diskSpace] (@diskSpace diskSpaceType READONLY)
as begin
	-- merge disk info into table
	MERGE dbo.diskSpace as [target]
	USING
		(
		SELECT 
			[server_name],
			[volume_mount_point],
			[logical_volume_name],
			[total_size_gb],
			[available_size_gb],
			[free_space_pct]
		FROM @diskSpace
		) AS [source](
						[server_name],
						[volume_mount_point],
						[logical_volume_name],
						[total_size_gb],
						[available_size_gb],
						[free_space_pct]
					 )
		ON ([target].server_name = [source].server_name and
			[target].[volume_mount_point] = [source].[volume_mount_point] and
			[target].[logical_volume_name] = [source].[logical_volume_name])and
			([target].[available_size_gb]<> [source].[available_size_gb] or
			[target].[free_space_pct] <> [source].[free_space_pct])
		WHEN MATCHED
			THEN UPDATE SET
				[target].[total_size_gb] = [source].[total_size_gb],
				[target].[available_size_gb] = [source].[available_size_gb],
				[target].[free_space_pct] = [source].[free_space_pct]
		WHEN NOT MATCHED THEN
			INSERT(
						[server_name],
						[volume_mount_point],
						[logical_volume_name],
						[total_size_gb],
						[available_size_gb],
						[free_space_pct]
				  )
			VALUES(
					[source].[server_name],
					[source].[volume_mount_point],
					[source].[logical_volume_name],
					[source].[total_size_gb],
					[source].[available_size_gb],
					[source].[free_space_pct]
				  );
end