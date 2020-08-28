CREATE TABLE [dbo].[diskSpace](
	[recordId] [int] IDENTITY(1,1) NOT NULL,
	[server_name] [nvarchar](128) NOT NULL,
	[volume_mount_point] [nvarchar](256) NULL,
	[logical_volume_name] [nvarchar](256) NULL,
	[total_size_gb] [decimal](18, 2) NULL,
	[available_size_gb] [decimal](18, 2) NULL,
	[free_space_pct] [decimal](18, 2) NULL,
	[SysStartTime] [datetime2](7) GENERATED ALWAYS AS ROW START NOT NULL,
	[SysEndTime] [datetime2](7) GENERATED ALWAYS AS ROW END NOT NULL,
PRIMARY KEY NONCLUSTERED 
(
	[recordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	PERIOD FOR SYSTEM_TIME ([SysStartTime], [SysEndTime])
) ON [PRIMARY]
WITH
(
SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [dbo].[diskSpaceHistory] )
)