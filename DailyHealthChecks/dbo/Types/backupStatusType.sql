CREATE TYPE backupStatusType AS TABLE
(
	[server_name] [sysname] NOT NULL,
    [database_name] [sysname] NOT NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
	[last_full_backup] [datetime] NULL,
	[last_differential_backup] [datetime] NULL,
	[last_tlog_backup] [datetime] NULL,
	[backup_status] [varchar](8) NOT NULL,
	[status_desc] [varchar](225) NOT NULL
)