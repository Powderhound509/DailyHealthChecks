CREATE TABLE [dbo].[sqlLogins_TrackerHistory]
(
	[ID] [INT] NOT NULL,
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
	[SysStartTime] [DATETIME2](7) NOT NULL,
	[SysEndTime] [DATETIME2](7) NOT NULL
) ON [PRIMARY]
