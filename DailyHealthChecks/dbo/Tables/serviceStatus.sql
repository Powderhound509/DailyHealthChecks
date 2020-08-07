CREATE TABLE [dbo].[serviceStatus](
	[recordId] int identity (1,1) NOT NULL,
	[server_name] [nvarchar](128) NULL,
	[service_name] [nvarchar](256) NOT NULL,
	[startup_type_desc] [nvarchar](256) NULL,
	[status_desc] [nvarchar](256) NOT NULL,
	SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime),
	PRIMARY KEY NONCLUSTERED ([recordId] ASC)
) ON [PRIMARY]
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.serviceStatusHistory));