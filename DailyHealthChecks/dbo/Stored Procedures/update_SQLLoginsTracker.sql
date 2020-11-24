CREATE PROC [dbo].[update_SQLLoginsTracker] @SQLLoginStatus sqlLoginStatusType READONLY
AS BEGIN
	MERGE dbo.sqlLogins_Tracker AS [target]
	USING 
		(
		SELECT	serverName, loginName, daysUntilExpired
		FROM @SQLLoginStatus
		) AS [SOURCE]
					(	
						serverName, 
						loginName, 
						daysUntilExpired
					)

		ON (
				[TARGET].serverName = [SOURCE].serverName and
				[TARGET].loginName = [SOURCE].loginName
			)
		WHEN MATCHED
			THEN UPDATE SET
						[TARGET].daysUntilExpired = [SOURCE].daysUntilExpired
		WHEN NOT MATCHED THEN
			INSERT	(
						serverName, 
						loginName, 
						daysUntilExpired
					)
			VALUES	(
						[SOURCE].serverName,
						[SOURCE].loginName,
						[SOURCE].daysUntilExpired
					);
END