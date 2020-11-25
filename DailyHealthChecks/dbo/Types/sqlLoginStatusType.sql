CREATE TYPE [dbo].[sqlLoginStatusType] AS TABLE
(
	[serverName] [VARCHAR](128) NULL,
	[loginName] [VARCHAR](50) NULL,
	[daysUntilExpired] [VARCHAR](20) NULL,
	[passwordLastSetTime] [DATETIME2] NULL,
	[isExpired] [INT] NULL,
	[userNameAsPassword] [INT] NULL,
	[loginCreateDate] [DATETIME2] NULL, 
	[loginModifyDate] [DATETIME2] NULL,
	[policyEnforced] [INT] NULL,
	[expirationEnforced] [INT] NULL,
	[isDisabled] [INT] NULL
)