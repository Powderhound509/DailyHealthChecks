create procedure update_clusterStatus (@clusterStatus clusterStatusType READONLY)
as begin
	-- merge clusterStatus into table
	select * from @clusterStatus
end