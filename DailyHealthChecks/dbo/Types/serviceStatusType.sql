CREATE TYPE serviceStatusType AS TABLE
(
	[server_name] [nvarchar](128) NULL,
	[service_name] [nvarchar](256) NOT NULL,
	[startup_type_desc] [nvarchar](256) NULL,
	[status_desc] [nvarchar](256) NOT NULL
)