CREATE TYPE jobStatusType AS TABLE
(
	[server_name] [nvarchar](128) NOT NULL,
	[job_name] [sysname] NOT NULL,
	[current_run_status] [varchar](11) NULL,
	[last_start_date] [datetime] NULL,
	[last_stop_date] [datetime] NULL,
	[last_run_status] [varchar](9) NULL,
	[job_output] [nvarchar](4000) NULL
)