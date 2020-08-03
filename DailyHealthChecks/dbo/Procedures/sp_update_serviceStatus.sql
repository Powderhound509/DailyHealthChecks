create procedure sp_update_serviceStatus (@serviceStatus serviceStatusType READONLY)
as begin
	-- merge diskSpace into table
	select * from @serviceStatus
end