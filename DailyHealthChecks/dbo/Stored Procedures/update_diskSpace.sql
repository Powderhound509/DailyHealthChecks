CREATE procedure [dbo].[update_diskSpace] (@diskSpace diskSpaceType READONLY)
as begin
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
	-- merge disk info into table
	MERGE dbo.diskSpace as [target]
	USING
		(
		SELECT 
			[server_name],
			[volume_mount_point],
			[logical_volume_name],
			[total_size_gb],
			[available_size_gb],
			[free_space_pct]
		FROM @diskSpace
		) AS [source](
						[server_name],
						[volume_mount_point],
						[logical_volume_name],
						[total_size_gb],
						[available_size_gb],
						[free_space_pct]
					 )
		ON ([target].server_name = [source].server_name and
			[target].[volume_mount_point] = [source].[volume_mount_point] and
			[target].[logical_volume_name] = [source].[logical_volume_name])
		WHEN MATCHED
			THEN UPDATE SET
				[target].[total_size_gb] = [source].[total_size_gb],
				[target].[available_size_gb] = [source].[available_size_gb],
				[target].[free_space_pct] = [source].[free_space_pct]
		WHEN NOT MATCHED THEN
			INSERT(
						[server_name],
						[volume_mount_point],
						[logical_volume_name],
						[total_size_gb],
						[available_size_gb],
						[free_space_pct]
				  )
			VALUES(
					[source].[server_name],
					[source].[volume_mount_point],
					[source].[logical_volume_name],
					[source].[total_size_gb],
					[source].[available_size_gb],
					[source].[free_space_pct]
				  );
end