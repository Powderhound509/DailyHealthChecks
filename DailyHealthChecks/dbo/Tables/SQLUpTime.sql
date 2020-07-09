CREATE TABLE [dbo].[SQLUpTime] (
    [recordID]        INT           IDENTITY (1, 1) NOT NULL,
    [serverName]      [sysname]     NOT NULL,
    [serverStartTime] DATETIME2 (7) NOT NULL,
    [recordTime]      DATETIME2 (7) DEFAULT (getdate()) NULL,
    PRIMARY KEY CLUSTERED ([recordID] ASC)
);

