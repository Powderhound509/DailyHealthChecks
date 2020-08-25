CREATE PROC update_SQLUpTime(@serverName VARCHAR(128), @startupTime DATETIME2)
AS BEGIN
	-- Check if there's already a record for the server\instance
	IF NOT EXISTS(SELECT 'a' FROM SQLUpTime WHERE serverName = @serverName)
		BEGIN
			INSERT INTO SQLUpTime (serverName, serverStartTime)
			VALUES(@serverName, @startupTime)
		END
	ELSE -- update the record and the history table will track the changes
		BEGIN
			UPDATE SQLUpTime SET serverStartTime = @startupTime
				WHERE serverStartTime < @startupTime
				AND serverName = @serverName
		END	
END