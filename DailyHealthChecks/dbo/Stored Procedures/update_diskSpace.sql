create procedure update_diskSpace (@diskSpace diskSpaceType READONLY)
as begin
	-- merge diskSpace into table
	select * from @diskSpace
end