CREATE TABLE [dbo].[jobStatus](
	[recordId] INT IDENTITY(1,1) NOT NULL,
	[server_name] [nvarchar](128) NOT NULL,
	[job_name] [sysname] NOT NULL,
	[current_run_status] [varchar](11) NULL,
	[last_start_date] [datetime2] NULL,
	[last_stop_date] [datetime2] NULL,
	[last_run_status] [varchar](9) NULL,
	[job_output] [nvarchar](4000) NULL,
	SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime),
	PRIMARY KEY NONCLUSTERED ([recordID] ASC)
) ON [PRIMARY]
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.jobStatusHistory));