CREATE TABLE [dbo].[sqlLogins_TrackerHistory]
(
	[ID] [INT] NOT NULL,
	[appName] [VARCHAR](50) NULL,
	[loginName] [VARCHAR](50) NULL,
	[POC] [VARCHAR](128) NULL,
	[daysUntilExpired] [VARCHAR](20) NULL,
	[serverName] [VARCHAR](128) NULL,
	[SysStartTime] [DATETIME2](7) NOT NULL,
	[SysEndTime] [DATETIME2](7) NOT NULL
) ON [PRIMARY]
