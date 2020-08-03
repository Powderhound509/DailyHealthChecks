CREATE TYPE dbo.AGStatusType AS TABLE(
	[ag_name] [sysname] NOT NULL,
	[replica_server_name] [nvarchar](256) NOT NULL,
	[role] [nvarchar](60) NOT NULL,
	[availability_mode_desc] [nvarchar](60) NOT NULL,
	[failover_mode_desc] [nvarchar](60) NOT NULL,
	[database_name] [sysname] NOT NULL,
	[synchronization_state] [nvarchar](60) NOT NULL,
	[synchronization_health] [nvarchar](60) NOT NULL,
	[lastUpdate] [datetime2](7) NOT NULL
	)