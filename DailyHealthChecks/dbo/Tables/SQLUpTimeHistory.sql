CREATE TABLE [dbo].[SQLUpTimeHistory](
	[recordId] [int] NOT NULL,
	[serverName] VARCHAR(128) NOT NULL,
	[serverStartTime] DATETIME2 NOT NULL,
	[SysStartTime] DATETIME2 NOT NULL,
	[SysEndTime] DATETIME2 NOT NULL
) ON [PRIMARY]
GO

