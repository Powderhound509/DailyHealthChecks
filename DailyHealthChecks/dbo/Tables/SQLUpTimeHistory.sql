CREATE TABLE [dbo].[SQLUpTimeHistory](
	[recordId] [int] NOT NULL,
	[serverName] [sysname] NOT NULL,
	[serverStartTime] [datetime2](7) NULL,
	[SysStartTime] [datetime2](7) NOT NULL,
	[SysEndTime] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO

