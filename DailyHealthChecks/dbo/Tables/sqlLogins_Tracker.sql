CREATE TABLE [dbo].[sqlLogins_Tracker]
(
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[serverName] [VARCHAR](128) NULL,
	[appName] [VARCHAR](50) NULL,
	[loginName] [VARCHAR](50) NULL,
	[POC] [VARCHAR](128) NULL,
	[daysUntilExpired] [VARCHAR](20) NULL,
	[passwordLastSetTime] [DATETIME2] NULL,
	[isExpired] [INT] NULL,
	[userNameAsPassword] [INT] NULL,
	[loginCreateDate] [DATETIME2] NULL, 
	[loginModifyDate] [DATETIME2] NULL,
	[policyEnforced] [INT] NULL,
	[expirationEnforced] [INT] NULL,
	[isDisabled] [INT] NULL,
	[SysStartTime] [DATETIME2](7) GENERATED ALWAYS AS ROW START NOT NULL,
	[SysEndTime] [DATETIME2](7) GENERATED ALWAYS AS ROW END NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
PERIOD FOR SYSTEM_TIME ([SysStartTime], [SysEndTime])
) ON [PRIMARY]
WITH
(
SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [dbo].[sqlLogins_TrackerHistory] )
)
