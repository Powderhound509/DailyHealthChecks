CREATE TABLE [dbo].[clusterStatus](
	[recordId] int identity (1,1) NOT NULL,
	[cluster_node_name] [nvarchar](128) NULL,
	[cluster_node_status] [nvarchar](25) NOT NULL,
	SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime),
	PRIMARY KEY NONCLUSTERED ([recordID] ASC)
) ON [PRIMARY]
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.clusterStatusHistory));
