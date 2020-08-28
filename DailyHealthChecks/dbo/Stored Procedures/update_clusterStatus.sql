create procedure update_clusterStatus (@clusterStatus clusterStatusType READONLY)
as begin
	-- merge clusterStatus into table
	MERGE dbo.clusterStatus as [target]
	USING
		(
		SELECT 
			[cluster_node_name],
			[cluster_node_status]
		FROM @clusterStatus
		) AS [source](
						[cluster_node_name],
						[cluster_node_status]
					 )
		ON ([target].[cluster_node_name] = [source].[cluster_node_name])
		WHEN MATCHED
			THEN UPDATE SET
				[target].[cluster_node_status] = [source].[cluster_node_status]
		WHEN NOT MATCHED THEN
			INSERT(
					[cluster_node_name],
					[cluster_node_status]
				  )
			VALUES(
					[source].[cluster_node_name],
					[source].[cluster_node_status]
				  );
end