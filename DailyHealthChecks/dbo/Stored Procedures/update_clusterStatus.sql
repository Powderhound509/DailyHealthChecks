create procedure update_clusterStatus (@clusterStatus clusterStatusType READONLY)
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
	-- merge clusterStatus into table
	MERGE dbo.clusterStatus as [target]
	USING
		(
		SELECT 
			[cluster_node_name],
			[cluster_node_status]
		FROM @clusterStatus
		) AS [source](
						[cluster_node_name],
						[cluster_node_status]
					 )
		ON ([target].[cluster_node_name] = [source].[cluster_node_name])
		WHEN MATCHED
			THEN UPDATE SET
				[target].[cluster_node_status] = [source].[cluster_node_status]
		WHEN NOT MATCHED THEN
			INSERT(
					[cluster_node_name],
					[cluster_node_status]
				  )
			VALUES(
					[source].[cluster_node_name],
					[source].[cluster_node_status]
				  );
end