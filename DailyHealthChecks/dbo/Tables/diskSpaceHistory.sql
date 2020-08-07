CREATE TABLE [dbo].[diskSpaceHistory]
(
[recordId] [int] NOT NULL,
	[server_name] [nvarchar](128) NOT NULL,
	[volume_mount_point] [nvarchar](256) NULL,
	[logical_volume_name] [nvarchar](256) NULL,
	[total_size_gb] [decimal](18, 2) NULL,
	[available_size_gb] [decimal](18, 2) NULL,
	[free_space_pct] [decimal](18, 2) NULL,
	[SysStartTime] [datetime2](7) NOT NULL,
	[SysEndTime] [datetime2](7) NOT NULL
)
