CREATE TABLE [dbo].[backupStatusHistory](
	[recordId] int NOT NULL,
	[server_name] [sysname] NOT NULL,
	[database_name] [sysname] NOT NULL,
	[recovery_model_desc] [nvarchar](60) NULL,
	[last_full_backup] [datetime2] NULL,
	[last_differential_backup] [datetime2] NULL,
	[last_tlog_backup] [datetime2] NULL,
	[backup_status] [varchar](8) NOT NULL,
	[status_desc] [varchar](225) NOT NULL,
	SysStartTime DATETIME2 NOT NULL,
	SysEndTime DATETIME2 NOT NULL
) ON [PRIMARY]