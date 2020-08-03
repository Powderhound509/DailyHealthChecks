CREATE TABLE [dbo].[AGStatus](
	[recordId] int identity(1,1) not null,
	[ag_name] [sysname] NOT NULL,
	[replica_server_name] [nvarchar](256) NOT NULL,
	[role] [nvarchar](60) NOT NULL,
	[availability_mode_desc] [nvarchar](60) NOT NULL,
	[failover_mode_desc] [nvarchar](60) NOT NULL,
	[database_name] [sysname] NOT NULL,
	[synchronization_state] [nvarchar](60) NOT NULL,
	[synchronization_health] [nvarchar](60) NOT NULL,
	[lastUpdate] datetime2 not null default getdate(),
	SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	CONSTRAINT [PK_AGStatus_RID] PRIMARY KEY (recordId),
	PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime)
) ON [PRIMARY]
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.AGStatusHistory));