CREATE PROC update_DatabaseStatus(@serverName NVARCHAR(128), @databaseName NVARCHAR(128), @databaseStatus NVARCHAR(25))
AS BEGIN

IF NOT EXISTS(SELECT serverName FROM DatabaseStatus WHERE serverName = @serverName AND databaseName = @databaseName)
		BEGIN
			INSERT INTO DatabaseStatus (serverName, databaseName, databaseStatus, lastUpdate)
			VALUES(@serverName, @databaseName, @databaseStatus, getdate())
		END
	ELSE -- update the record and the history table will track the changes
		BEGIN
			UPDATE DatabaseStatus SET databaseStatus = @databaseStatus, lastUpdate = getdate()
				WHERE  serverName = @serverName and databaseName = @databaseName
		END	
END