CREATE PROC [dbo].[update_SQLLoginsTracker] @SQLLoginStatus sqlLoginStatusType READONLY
AS BEGIN
/*
-- Copyright (c) Microsoft Corporation.
-- Licensed under the MIT License.

This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object 
code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and 
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, 
that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within 
the Premier Customer Services Description.
  
Microsoft, SQL Server, Windows, Window Server are either registered trademarks or trademarks of Microsoft Corporation in 
the United States and/or other countries.

The names of actual companies and products mentioned herein may be the trademarks of their respective owners.

*/
	MERGE dbo.sqlLogins_Tracker AS [target]
	USING 
		(
		SELECT	serverName, dbList, [loginName], daysUntilExpired, passwordLastSetTime, isExpired, userNameAsPassword, loginCreateDate, loginModifyDate, policyEnforced, expirationEnforced, isDisabled
		FROM @SQLLoginStatus
		) AS [SOURCE](	
				serverName, dbList, [loginName], daysUntilExpired, passwordLastSetTime, isExpired, userNameAsPassword, loginCreateDate, loginModifyDate, policyEnforced, expirationEnforced, isDisabled)

		ON (
			[TARGET].serverName = [SOURCE].serverName and
			[TARGET].loginName = [SOURCE].loginName
			)
		WHEN MATCHED
			THEN UPDATE SET
						--[target].serverName = [source].serverName,
						[TARGET].dbList = [SOURCE].dbList,
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
			INSERT	(serverName, dbList, [loginName], daysUntilExpired, passwordLastSetTime, isExpired, userNameAsPassword, loginCreateDate, loginModifyDate, policyEnforced, expirationEnforced, isDisabled
					)
			VALUES	(
					[SOURCE].serverName,
					[SOURCE].dbList,
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