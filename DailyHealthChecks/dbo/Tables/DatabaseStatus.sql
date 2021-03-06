﻿CREATE TABLE [dbo].[DatabaseStatus](
	[recordId] INT IDENTITY(1,1) NOT NULL,
	[serverName] VARCHAR(128) NOT NULL,
	[databaseName] VARCHAR(128) NOT NULL,
	[databaseStatus] VARCHAR(25) NOT NULL,
	[lastUpdate] DATETIME2 NOT NULL DEFAULT GETDATE(),
	SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
	SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
	CONSTRAINT [PK_DBStatus_RID] PRIMARY KEY (recordId),
	PERIOD FOR SYSTEM_TIME (SysStartTime,SysEndTime)
) ON [PRIMARY]
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.DatabaseStatusHistory));