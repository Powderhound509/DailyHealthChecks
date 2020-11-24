CREATE TYPE [dbo].[sqlLoginStatusType] AS TABLE
(
	[serverName] [VARCHAR](128) NOT NULL,
	[loginName] [VARCHAR](50) NOT NULL,
	[daysUntilExpired] [VARCHAR](20) NOT NULL
)