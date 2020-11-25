CREATE PROC [dbo].[update_SQLLoginsTracker] @SQLLoginStatus sqlLoginStatusType READONLY
AS BEGIN
	MERGE dbo.sqlLogins_Tracker AS [target]
	USING 
		(
		SELECT	serverName, [loginName], daysUntilExpired, passwordLastSetTime, isExpired, userNameAsPassword, loginCreateDate, loginModifyDate, policyEnforced, expirationEnforced, isDisabled
		FROM @SQLLoginStatus
		) AS [SOURCE](	
				serverName, [loginName], daysUntilExpired, passwordLastSetTime, isExpired, userNameAsPassword, loginCreateDate, loginModifyDate, policyEnforced, expirationEnforced, isDisabled)

		ON (
			[TARGET].serverName = [SOURCE].serverName and
			[TARGET].loginName = [SOURCE].loginName
			)
		WHEN MATCHED
			THEN UPDATE SET
						--[target].serverName = [source].serverName,
						--[target].loginName = [source].loginName,
						[TARGET].daysUntilExpired = [SOURCE].daysUntilExpired,
						[TARGET].passwordLastSetTime = [SOURCE].passwordLastSetTime,
						[TARGET].isExpired = [SOURCE].isExpired,
						[TARGET].userNameAsPassword = [SOURCE].userNameAsPassword,
						[TARGET].loginCreateDate = [SOURCE].loginCreateDate,
						[TARGET].loginModifyDate = [SOURCE].loginModifyDate,
						[TARGET].policyEnforced = [SOURCE].policyEnforced,
						[TARGET].expirationEnforced = [SOURCE].expirationEnforced,
						[TARGET].isDisabled = [SOURCE].isDisabled
		WHEN NOT MATCHED THEN
			INSERT	(serverName, [loginName], daysUntilExpired, passwordLastSetTime, isExpired, userNameAsPassword, loginCreateDate, loginModifyDate, policyEnforced, expirationEnforced, isDisabled
					)
			VALUES	(
					[SOURCE].serverName,
					[SOURCE].[loginName],
					[SOURCE].daysUntilExpired,
					[SOURCE].passwordLastSetTime,
					[SOURCE].isExpired,
					[SOURCE].userNameAsPassword,
					[SOURCE].loginCreateDate, 
					[SOURCE].loginModifyDate,
					[SOURCE].policyEnforced,
					[SOURCE].expirationEnforced,
					[SOURCE].isDisabled
					);
END