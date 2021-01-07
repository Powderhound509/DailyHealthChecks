CREATE PROC [dbo].[get_ExpiringLogins](@ExpiresIn INT) AS BEGIN
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

-- If you're using Windows Authentication only, then expirations are handled by Group Policy
-- Iterate through the results
DECLARE @recordID int = 0
DECLARE @serverName sysname
DECLARE @sqlLogin nvarchar(50), @appName nvarchar(50), @POC nvarchar(128), @expirationDays nvarchar(20), @message nvarchar(1000)


-- This is an endless loop that we'll break out of a few rows down
while (1=1)
	begin

		select top 1 
			@recordID = slt.ID, 
			@serverName = slt.serverName, 
			@sqlLogin = slt.loginName, 
			@expirationDays = slt.daysUntilExpired, 
			@appName = cast(isnull(slt.appName, 'Unkown App') as varchar(50)), 
			@POC = cast(isnull(slt.POC,'some.user@some.domain') as varchar (128))
		from sqlLogins_Tracker slt
		where slt.ID > @recordID
		and (isnumeric(slt.daysUntilExpired)=0 or slt.daysUntilExpired <=@ExpiresIn)
		order by slt.ID
		
		-- exit if no more records
		if @@ROWCOUNT = 0 BREAK;

set @message = 
'**********************************************************************************************																									   
The SQL login with name:['+ @sqlLogin + '], has login expiration of:['+@expirationDays+'] days.
		  																							   
The login is used by the application:['+@appName+'] on the SQL Server:['+@serverName+'].	   
																									   
You have been identified as the POC for this login.  										   
Please coordinate with the SQL Team to change the password for this login or submit a request to 
delete the login if it is no longer needed.					   
																									   
This message has been automatically generated.  Please do not reply.						   
***********************************************************************************************'

		-- Generate some emails
		exec msdb.dbo.sp_send_dbmail
			@profile_name = 'Default',-- or DailyReports
			@recipients = @POC,
			@subject = 'Expiring SQL Logins Notification',
			@body = @message;


	end --while


end
GO


