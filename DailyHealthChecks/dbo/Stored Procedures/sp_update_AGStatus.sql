CREATE PROCEDURE dbo.sp_update_AGStatus @AGStatus AGStatusType READONLY
AS
BEGIN
	SET NOCOUNT ON
	-- Merge results into table
	MERGE dbo.AGStatus AS [target]
	USING 
		(
		SELECT	[ag_name],
				[replica_server_name],
				[role],
				[availability_mode_desc],
				[failover_mode_desc],
				[database_name],
				[synchronization_state],
				[synchronization_health],
				[lastUpdate]
		FROM @AGStatus 
		) AS [source](	[ag_name],
						[replica_server_name],
						[role],
						[availability_mode_desc],
						[failover_mode_desc],
						[database_name],
						[synchronization_state],
						[synchronization_health],
						[lastUpdate])
		ON ([target].ag_name = [source].ag_name and
			[target].replica_server_name = [source].replica_server_name and
			[target].[database_name] = [source].[database_name])
		WHEN MATCHED
			THEN UPDATE SET
						[target].[role]=[source].[role],
						[target].[availability_mode_desc]=[source].[availability_mode_desc],
						[target].[failover_mode_desc]=[source].[failover_mode_desc],
						[target].[synchronization_state]=[source].[synchronization_state],
						[target].[synchronization_health]=[source].[synchronization_health],
						[target].[lastUpdate]=[source].[lastUpdate]
		WHEN NOT MATCHED THEN
			INSERT	(
					[ag_name],
					[replica_server_name],
					[role],
					[availability_mode_desc],
					[failover_mode_desc],
					[database_name],
					[synchronization_state],
					[synchronization_health],
					[lastUpdate]
					)
			VALUES	(
					[source].[ag_name],
					[source].[replica_server_name],
					[source].[role],
					[source].[availability_mode_desc],
					[source].[failover_mode_desc],
					[source].[database_name],
					[source].[synchronization_state],
					[source].[synchronization_health],
					[source].[lastUpdate]
					);
END
