CREATE TABLE [dbo].[jobStatusHistory](
	[recordId] INT NOT NULL,
	[server_name] [nvarchar](128) NOT NULL,
	[job_name] [sysname] NOT NULL,
	[current_run_status] [varchar](11) NULL,
	[last_start_date] [datetime2] NULL,
	[last_stop_date] [datetime2] NULL,
	[last_run_status] [varchar](9) NULL,
	[job_output] [nvarchar](4000) NULL,
	SysStartTime DATETIME2 NOT NULL,
	SysEndTime DATETIME2 NOT NULL
) ON [PRIMARY]