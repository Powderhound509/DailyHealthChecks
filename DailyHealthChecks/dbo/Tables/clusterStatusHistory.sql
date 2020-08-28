CREATE TABLE [dbo].[clusterStatusHistory](
	[recordId] int NOT NULL,
	[cluster_node_name] [nvarchar](128) NULL,
	[cluster_node_status] [nvarchar](25) NOT NULL,
	SysStartTime DATETIME2 NOT NULL,
	SysEndTime DATETIME2 NOT NULL
) ON [PRIMARY]