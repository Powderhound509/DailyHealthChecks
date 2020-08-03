create procedure sp_update_backupStatus (@backupStatus backupStatusType READONLY)
as begin
	-- merge status into table
	select * from @backupStatus
end