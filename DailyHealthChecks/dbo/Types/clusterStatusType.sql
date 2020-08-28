CREATE TYPE clusterStatusType AS TABLE
(
	[cluster_node_name] [nvarchar](128) NULL,
	[cluster_node_status] [nvarchar](25) NOT NULL
)