CREATE TABLE [dbo].[DatabaseStatusHistory](
	[recordId] [int] NOT NULL,
	[serverName] [varchar](128) NOT NULL,
	[databaseName] [varchar](128) NOT NULL,
	[databaseStatus] [varchar](25) NOT NULL,
	[lastUpdate] [datetime2](7) NOT NULL,
	[SysStartTime] [datetime2](7) NOT NULL,
	[SysEndTime] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO

