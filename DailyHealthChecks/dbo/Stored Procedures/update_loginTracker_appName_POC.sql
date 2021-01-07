CREATE PROC update_loginTracker_appName_POC (@serverName VARCHAR(128), @dbName VARCHAR(255), @loginName varchar(50),@appName VARCHAR(50), @POC VARCHAR(128))
AS BEGIN
/*
Copyright

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
 
c 2017 Microsoft Corporation.  All rights reserved.
 
Microsoft, SQL Server, Windows, Window Server are either registered trademarks or trademarks of Microsoft Corporation in 
the United States and/or other countries.
 
The names of actual companies and products mentioned herein may be the trademarks of their respective owners.
*/

-- Sample Execution
--exec update_loginTracker_appName_POC
--	  @serverName = 'coe-wpcciq20dcp\wpcciq20dcp', 
--	  @dbName = 'FNMSInventory',
--	  @loginName = 'omartest',
--	  @appName = 'omarsAppTest',
--	  @POC = 'omar@mail.mil' -- separate multiple email addresses or DL's with a semicolon ';'
--go
	set nocount on

	IF(@serverName+@dbName+@loginName+@appName+@POC is not null)
	BEGIN	
		UPDATE sqlLogins_Tracker SET appName = @appName, POC = @POC
		WHERE serverName = @serverName and loginName = @loginName and dbList like ('%'+@dbName+'%')

		SELECT 'The following change has been made:' [message], id, serverName, dbList, appName, loginName, POC 
		FROM sqlLogins_Tracker
		WHERE serverName = @serverName and loginName = @loginName and dbList like ('%'+@dbName+'%')
	END
	ELSE BEGIN
		SELECT 
			'Please check your input values:' [Message],
			ISNULL(@serverName, '@serverName cannot be null') serverName,
			ISNULL(@dbName, '@dbName cannot be null') dbName,
			ISNULL(@loginName, '@loginName cannot be null') loginName,
			ISNULL(@appName, '@appName cannot be null') appName,
			ISNULL(@POC, '@POC cannot be null') POC
	END

END