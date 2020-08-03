create procedure sp_update_jobStatus (@jobStatus jobStatusType READONLY)
as begin
	-- merge diskSpace into table
	select * from @jobStatus
end