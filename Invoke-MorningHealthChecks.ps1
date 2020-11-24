# -----------------------------------------------------------------------------
# Author:      Patrick Keisler, Microsoft
# Date:        Nov 2017
#
# File Name:   Invoke-MorningHealthChecks.ps1
#
# Purpose:     PowerShell script to automate morning health checks.
#
# History:
# Date         BY               Comment
# -----------  -----------      ----------------------------------------------------------------------
# 06 Nov 2017  Patrick Keisler  Created
# 27 May 2020  Patrick Keisler  Changed error trapping to continue processing when a server is offline.
# 27 May 2020  Patrick Keisler  Added "is enabled" check for the failed jobs function.
# 27 May 2020  Patrick Keisler  Fixed bug in the database status funtion for mirrored databases.
# 27 May 2020  Patrick Keisler  Added a new check for Windows Cluster node status.
# 27 May 2020  Patrick Keisler  Added a new check for SQL service(s) status.
# 21 Jul 2020  Joshua Lent      Added database insert statements to all checks (except error log)
# 24 Nov 2020  Joshua Lent      Added a check for expring SQL Logins
# -----------------------------------------------------------------------------------------------------
#
# Copyright (C) 2020 Microsoft Corporation
#
# Disclaimer:
#   This is SAMPLE code that is NOT production ready. It is the sole intention of this code to provide a proof of concept as a
#   learning tool for Microsoft Customers. Microsoft does not provide warranty for or guarantee any portion of this code
#   and is NOT responsible for any affects it may have on any system it is executed on  or environment it resides within.
#   Please use this code at your own discretion!
# Additional legalese:
#   This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
#   THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
#   INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#   We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute
#   the object code form of the Sample Code, provided that You agree:
#       (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
#      (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
#     (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys' fees,
#           that arise or result from the use or distribution of the Sample Code.
# -----------------------------------------------------------------------------
#
# Paramaters:
#   $cmsServer - Name of the CMS server where your list of SQL Servers is registered.
#   $cmsGroup - Name of the CMS group that will be evaluated.
#   $serverList - Comma delimited list of SQL Servers that will be evaluated.
#
# Important note: 
#   Either "$cmsServer/$cmsGroup" or "$serverList" parameter should have values specified, but NOT BOTH.
#
# Example 1 uses the CMS parameters to check servers in the 'SQL2012' CMS group that is a subfolder of 'PROD':
#   Invoke-MorningHealthChecks.ps1 -cmsServer 'SOLO\CMS' -cmsGroup 'PROD\SQL2012'
#
# Example 2 uses the $serverList paramenter to check 4 different SQL Servers:
#   Invoke-MorningHealthChecks.ps1 -serverList 'CHEWIE','CHEWIE\SQL01','LUKE\SKYWALKER','LANDO\CALRISSIAN'
#
# -----------------------------------------------------------------------------

####################   SCRIPT-LEVEL PARAMETERS   ########################
param(
  [CmdletBinding()]
  [Parameter(ParameterSetName='Set1',Position=0,Mandatory=$true)][String]$cmsServer,
  [parameter(ParameterSetName='Set1',Position=1,Mandatory=$false)][String]$cmsGroup,
  [parameter(ParameterSetName='Set2',Position=2,Mandatory=$true)][String]$serverList,
  [parameter(ParameterSetName='Set1',Position=3,Mandatory=$true)][String]$cmsDatabase ## Where we want to store the results to
)

####################   LOAD ASSEMBLIES   ########################

#Attempt to load assemblies by name starting with the latest version
try {
  #SMO v14 - SQL Server 2017
  Add-Type -AssemblyName 'Microsoft.SqlServer.ConnectionInfo, Version=14.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ErrorAction Stop
  Add-Type -AssemblyName 'Microsoft.SqlServer.Management.RegisteredServers, Version=14.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ErrorAction Stop
}
catch {
  try {
    #SMO v13 - SQL Server 2016
    Add-Type -AssemblyName 'Microsoft.SqlServer.ConnectionInfo, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ErrorAction Stop
    Add-Type -AssemblyName 'Microsoft.SqlServer.Management.RegisteredServers, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ErrorAction Stop
  }
  catch {
    try {
      #SMO v12 - SQL Server 2014
      Add-Type -AssemblyName 'Microsoft.SqlServer.ConnectionInfo, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ErrorAction Stop
      Add-Type -AssemblyName 'Microsoft.SqlServer.Management.RegisteredServers, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ErrorAction Stop
    }
    catch {
      try {
        #SMO v11 - SQL Server 2012
        Add-Type -AssemblyName 'Microsoft.SqlServer.ConnectionInfo, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ErrorAction Stop
        Add-Type -AssemblyName 'Microsoft.SqlServer.Management.RegisteredServers, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ErrorAction Stop
      }
      catch {
        Write-Warning 'SMO components not installed. Download from https://goo.gl/E700bG'
        Break
      }
    }
  }
}

####################   FUNCTIONS   ########################
function Get-Error {
  <#
      .SYNOPSIS
      Processes errors encoutered in PowerShell code.
      .DESCRIPTION
      The Get-SqlConnection function processes either PowerShell errors or application errors defined within your code.
      .INPUTS
      None
      .OUTPUTS
      None
      .EXAMPLE
      try { 1/0 } catch { Get-Error $Error }
      This passes the common error object (System.Management.Automation.ErrorRecord) for processing.
      .EXAMPLE
      try { 1/0 } catch { Get-Error "You attempted to divid by zero. Try again." }
      This passes a string that is output as an error message.
      .LINK
      Get-SqlConnection 
  #>
  param(
    [CmdletBinding()]
    [Parameter(Position=0,ParameterSetName='PowerShellError',Mandatory=$true)] [System.Management.Automation.ErrorRecord]$PSError,
    [Parameter(Position=0,ParameterSetName='ApplicationError',Mandatory=$true)] [string]$AppError,
		[Parameter(Position=1,Mandatory=$false)] [switch]$ContinueAfterError
  )

  if ($PSError) {
    #Process a PowerShell error
    Write-Host '******************************'
    Write-Host "Error Count: $($PSError.Count)"
    Write-Host '******************************'

    $err = $PSError.Exception
    Write-Host $err.Message
    $err = $err.InnerException
    while ($err.InnerException) {
      Write-Host $err.InnerException.Message
      $err = $err.InnerException
    }
    if ($ContinueAfterError) { Continue }
    else { Throw }
  }
  elseif ($AppError) {
    #Process an application error
    Write-Host '******************************'
    Write-Host 'Error Count: 1'
    Write-Host '******************************'
    Write-Host $AppError
    if ($ContinueAfterError) { Continue }
    else { Throw }
  }
} #Get-Error

function Get-SqlConnection {
  <#
      .SYNOPSIS
      Gets a ServerConnection.
      .DESCRIPTION
      The Get-SqlConnection function  gets a ServerConnection to the specified SQL Server.
      .INPUTS
      None
      You cannot pipe objects to Get-SqlConnection 
      .OUTPUTS
      Microsoft.SqlServer.Management.Common.ServerConnection
      Get-SqlConnection returns a Microsoft.SqlServer.Management.Common.ServerConnection object.
      .EXAMPLE
      Get-SqlConnection "Z002\sql2K8"
      This command gets a ServerConnection to SQL Server Z002\SQL2K8.
      .EXAMPLE
      Get-SqlConnection "Z002\sql2K8" "sa" "Passw0rd"
      This command gets a ServerConnection to SQL Server Z002\SQL2K8 using SQL authentication.
      .LINK
      Get-SqlConnection 
  #>
  param(
    [CmdletBinding()]
    [Parameter(Mandatory=$true)] [string]$sqlserver,
    [string]$username, 
    [string]$password,
    [Parameter(Mandatory=$false)] [string]$applicationName='Morning Health Checks'
  )

  Write-Verbose "Get-SqlConnection $sqlserver"
    
    if($Username -and $Password){
        try { $con = new-object ('Microsoft.SqlServer.Management.Common.ServerConnection') $sqlserver,$username,$password }
        catch { Get-Error $_ }
    }
    else {
        try { $con = new-object ('Microsoft.SqlServer.Management.Common.ServerConnection') $sqlserver }
        catch { Get-Error $_ }
    }
	
  $con.ApplicationName = $applicationName
  try {
    $con.Connect()
  }
  catch {
    Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $targetServer`n"
    Get-Error $_ -ContinueAfterError
  }

  Write-Output $con
    
} #Get-ServerConnection

function Get-CmsServer {
  <#
      .SYNOPSIS
      Returns a list of SQL Servers from a CMS server.

      .DESCRIPTION
      Parses registered servers in CMS to return a list of SQL Servers for processing.

      .INPUTS
      None
      You cannot pipe objects to Get-CmsServer 

      .OUTPUTS
      Get-CmsServer returns an array of strings.
 
      .PARAMETER cmsServer
      The name of the CMS SQL Server including instance name.

      .PARAMETER cmsGroup
      OPTIONAL. The name of a group (and path) in the CMS server.

      .PARAMETER recurse
      OPTIONAL. Return all servers that may exist in subfolders below cmsFolder.

      .PARAMETER unique
      OPTIONAL. Returns a unique list of servers. This is helpful if you have the same SQL server registered in multiple groups.

      .NOTES
      Includes code from Chrissy LeMarie (@cl).
      https://blog.netnerds.net/smo-recipes/central-management-server/

      .EXAMPLE
      Get-CmsServer -cmsServer "SOLO\CMS"
      Returns a list of all registered servers that are on the CMS server.

      .EXAMPLE
      Get-CmsServer -cmsServer "SOLO\CMS" -cmsFolder "SQL2012" -recurse
      Returns a list of all registered servers that are in the SQL2012 folder and any subfolders that exist below it.

      .EXAMPLE
      Get-CmsServer -cmsServer "SOLO\CMS" -cmsFolder "SQL2012\Cluster" -unique
      Returns a list of all unique (distinct) registered servers that are in the folder for this exact path "SQL2012\Cluster".

      .LINK
      http://www.patrickkeisler.com/
  #>
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$cmsServer,
    [parameter(Position=1)][String]$cmsGroup,
    [parameter(Position=2)][Switch]$recurse,
    [parameter(Position=3)][Switch]$unique
  ) 

  switch ($cmsServer.GetType().Name) {
    'String' { 
      try {
        $sqlConnection = Get-SqlConnection -sqlserver $cmsServer
        $cmsStore = new-object Microsoft.SqlServer.Management.RegisteredServers.RegisteredServersStore($sqlConnection)
      }
      catch {
        Get-Error $_
      }
    }
    'RegisteredServersStore' { $cmsStore = $cmsServer }
    default { Get-Error "Get-CmsGroup:Param `$cmsStore must be a String or ServerConnection object." }
  }

  Write-Verbose "Get-CmsServer $($cmsStore.DomainInstanceName) $cmsGroup $recurse $unique"

  ############### Declarations ###############

  $collection = @()
  $newcollection = @()
  $serverList = @()
  $cmsFolder = $cmsGroup.Trim('\')

  ############### Functions ###############

  Function Parse-ServerGroup {
    Param (
      [CmdletBinding()]
      [parameter(Position=0)][Microsoft.SqlServer.Management.RegisteredServers.ServerGroup]$serverGroup,
      [parameter(Position=1)][System.Object]$collection
    )

    #Get registered instances in this group.
    foreach ($instance in $serverGroup.RegisteredServers) {
      $urn = $serverGroup.Urn
      $group = $serverGroup.Name
      $fullGroupName = $null
 
      for ($i = 0; $i -lt $urn.XPathExpression.Length; $i++) {
        $groupName = $urn.XPathExpression[$i].GetAttributeFromFilter('Name')
        if ($groupName -eq 'DatabaseEngineServerGroup') { $groupName = $null }
        if ($i -ne 0 -and $groupName -ne 'DatabaseEngineServerGroup' -and $groupName.Length -gt 0 ) {
          $fullGroupName += "$groupName\"
        }
      }

      #Add a new object for each registered instance.
      $object = New-Object PSObject -Property @{
        Server = $instance.ServerName
        Group = $groupName
        FullGroupPath = $fullGroupName
      }
      $collection += $object
    }
 
    #Loop again if there are more sub groups.
    foreach($group in $serverGroup.ServerGroups)
    {
      $newobject = (Parse-ServerGroup -serverGroup $group -collection $newcollection)
      $collection += $newobject     
    }
    return $collection
  }

  ############### Main Execution Get-CmsServer ###############

  #Get a list of all servers in the CMS store
  foreach ($serverGroup in $cmsStore.DatabaseEngineServerGroup) {  
    $serverList = Parse-ServerGroup -serverGroup $serverGroup -collection $newcollection
  }

  #Set default to recurse if $cmsFolder is blank
  if ($cmsFolder -eq '') {$recurse = $true}

  if(($cmsFolder.Split('\')).Count -gt 1) {
    if($recurse.IsPresent) {
      #Return ones in this folder and subfolders
      $cmsFolder = "*$cmsFolder\*"
      if($unique.IsPresent) {
        $output = $serverList | Where-Object {$_.FullGroupPath -like $cmsFolder} | Select-Object Server -Unique
      }
      else {
        $output = $serverList | Where-Object {$_.FullGroupPath -like $cmsFolder} | Select-Object Server
      }
    }
    else {
      #Return only the ones in this folder
      $cmsFolder = "$cmsFolder\"
      if($unique.IsPresent) {
        $output = $serverList | Where-Object {$_.FullGroupPath -eq $cmsFolder} | Select-Object Server -Unique
      }
      else {
        $output = $serverList | Where-Object {$_.FullGroupPath -eq $cmsFolder} | Select-Object Server
      }
    }
  }
  elseif (($cmsFolder.Split('\')).Count -eq 1 -and $cmsFolder.Length -ne 0) {
    if($recurse.IsPresent) {
      #Return ones in this folder and subfolders
      $cmsFolder = "*$cmsFolder\*"
      if($unique.IsPresent) {
        $output = $serverList | Where-Object {$_.FullGroupPath -like $cmsFolder} | Select-Object Server -Unique
      }
      else {
        $output = $serverList | Where-Object {$_.FullGroupPath -like $cmsFolder} | Select-Object Server
      }
    }
    else {
      #Return only the ones in this folder
      if($unique.IsPresent) {
        $output = $serverList | Where-Object {$_.Group -eq $cmsFolder} | Select-Object Server -Unique
      }
      else {
        $output = $serverList | Where-Object {$_.Group -eq $cmsFolder} | Select-Object Server
      }
    }
  }
  elseif ($cmsFolder -eq '' -or $cmsFolder -eq $null) {
    if($recurse.IsPresent) {
      if($unique.IsPresent) {
        $output = $serverList | Select-Object Server -Unique
      }
      else {
        $output = $serverList | Select-Object Server
      }
    }
    else {
      if($unique.IsPresent) {
        $output = $serverList | Where-Object {$_.Group -eq $null} | Select-Object Server -Unique
      }
      else {
        $output = $serverList | Where-Object {$_.Group -eq $null} | Select-Object Server
      }
    }
  }
  
  #Convert the output a string array
  [string[]]$outputArray = $null
  $output | ForEach-Object {$outputArray += $_.Server}
  Write-Output $outputArray
} #Get-CmsServer

function Get-SqlUpTime {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    $server = Get-SqlConnection $targetServer

    #Get startup time
    $cmd = "SELECT sqlserver_start_time FROM sys.dm_os_sys_info;"
    try {
        $sqlStartupTime = $server.ExecuteScalar($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }
    #Write to DB, would like to change this to if not exists insert else update and convert to temporal table
    try {
    (Invoke-Sqlcmd -ServerInstance $targetServer -Query "SELECT @@servername, sqlserver_start_time FROM sys.dm_os_sys_info;") |
            Write-SqlTableData -serverInstance $cmsServer -DatabaseName $cmsDatabase -SchemaName "dbo" -TableName "SQLUpTime" -Force
    }
    catch{
         Get-Error $_ -ContinueAfterError
    }
    $upTime = (New-TimeSpan -Start ($sqlStartupTime) -End ($script:startTime))

    #Display the results to the console
    if ($upTime.Days -eq 0 -and $upTime.Hours -le 6) {
        #Critical if uptime is less than 6 hours
        Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
        Write-Host "Uptime: $($upTime.Days).$($upTime.Hours):$($upTime.Minutes):$($upTime.Seconds)"
    }
    elseif ($upTime.Days -lt 1 -and $upTime.Hours -gt 6) {
        #Warning if uptime less than 1 day but greater than 6 hours
        Write-Host "`nWARNING:" -BackgroundColor Yellow -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
        Write-Host "Uptime: $($upTime.Days).$($upTime.Hours):$($upTime.Minutes):$($upTime.Seconds)"
    }
    else {
        #Good if uptime is greater than 1 day
        Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
        Write-Host "Uptime: $($upTime.Days).$($upTime.Hours):$($upTime.Minutes):$($upTime.Seconds)"
    }
} #Get-SqlUptime

function Get-DatabaseStatus {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    #Get status of each database
    $server = Get-SqlConnection $targetServer

    $cmd = @"
		SELECT [name] AS [database_name], state_desc FROM sys.databases d
    JOIN sys.database_mirroring dm ON d.database_id = dm.database_id
    WHERE dm.mirroring_role_desc <> 'MIRROR'
    OR dm.mirroring_role_desc IS NULL;
"@
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }
   #Begin Write to DB
    try {
        ## Get the server\instance and startup time
        ##$result = $null
        $result = @(Invoke-Sqlcmd -ServerInstance $targetServer -Query "SELECT @@servername serverName, [name] AS [database_name], state_desc FROM sys.databases d
                                                                        JOIN sys.database_mirroring dm ON d.database_id = dm.database_id
                                                                        WHERE dm.mirroring_role_desc <> 'MIRROR'
                                                                        OR dm.mirroring_role_desc IS NULL;
                                                                        ")
       ## for each record exec sp (unless there's a way to pass in the whole resultSet)
        $result | ForEach-Object {
            ##write-host $result.database_Name
            $param1 = $_.serverName
            $param2 = $_.database_Name
            $param3 = $_.state_desc
            #Write-Host "$cmsDatabase, $param1, $param2, $param3"
            Invoke-SQLcmd -ServerInstance $cmsServer -Query "Exec [$cmsDatabase].dbo.sp_update_DatabaseStatus '$param1', '$param2', '$param3'" ##-outputerrors $true
        }
    }
    catch{
            Get-Error $_ -ContinueAfterError
    }
    #End Write to DB
    #Display the results to the console
    if ($results.Tables[0] | Where-Object {$_.state_desc -eq 'SUSPECT'}) {
        Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
    }
    elseif ($results.Tables[0] | Where-Object {$_.state_desc -in 'RESTORING','RECOVERING','RECOVERY_PENDING','EMERGENCY','OFFLINE','COPYING','OFFLINE_SECONDARY'}) {
        Write-Host "`nWARNING:" -BackgroundColor Yellow -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
    }
    else { Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)" }

    $results.Tables[0] | Where-Object {$_.state_desc -in 'SUSPECT','RESTORING','RECOVERING','RECOVERY_PENDING','EMERGENCY','OFFLINE','COPYING','OFFLINE_SECONDARY'} | Select-Object database_name,state_desc | Format-Table -AutoSize
} #Get-DatabaseStatus

function Get-AGStatus {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    $server = Get-SqlConnection $targetServer

    $cmd = @"
    SELECT 
	     ag.name AS ag_name
	    ,ar.replica_server_name
	    ,ars.role_desc AS role
	    ,ar.availability_mode_desc
	    ,ar.failover_mode_desc
	    ,adc.[database_name]
	    ,drs.synchronization_state_desc AS synchronization_state
	    ,drs.synchronization_health_desc AS synchronization_health
    FROM sys.dm_hadr_database_replica_states AS drs WITH (NOLOCK)
    INNER JOIN sys.availability_databases_cluster AS adc WITH (NOLOCK) ON drs.group_id = adc.group_id AND drs.group_database_id = adc.group_database_id
    INNER JOIN sys.availability_groups AS ag WITH (NOLOCK) ON ag.group_id = drs.group_id
    INNER JOIN sys.availability_replicas AS ar WITH (NOLOCK) ON drs.group_id = ar.group_id AND drs.replica_id = ar.replica_id
    INNER JOIN sys.dm_hadr_availability_replica_states AS ars ON ar.replica_id = ars.replica_id
    WHERE ars.is_local = 1
    ORDER BY ag.name, ar.replica_server_name, adc.[database_name] OPTION (RECOMPILE);
"@

    #If one exists, get status of each Availability Group
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }

#Begin Write to DB
#Build a DataTable to hold the Availability Group Status
$tAGStatus = New-Object System.Data.DataTable
$columnName = New-Object System.Data.DataColumn ag_name,([string])
$tAGStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn replica_server_name,([string])
$tAGStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn role,([string])
$tAGStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn availability_mode_desc,([string])
$tAGStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn failover_mode_desc,([string])
$tAGStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn database_name,([string])
$tAGStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn synchronization_state,([string])
$tAGStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn synchronization_health,([string])
$tAGStatus.Columns.Add($columnName)

try {
	$results.Tables[0] | ForEach-Object {
    $rAGStatus = $tAGStatus.NewRow()
    $rAGStatus.ag_name = $($_.ag_name)
    $rAGStatus.replica_server_name = $($_.replica_server_name)
    $rAGStatus.role = $($_.role)
    $rAGStatus.availability_mode_desc = $($_.availability_mode_desc)
    $rAGStatus.failover_mode_desc = $($_.failover_mode_desc)
	$rAGStatus.database_name = $($_.database_name)
    $rAGStatus.synchronization_state = $($_.synchronization_state)
	$rAGStatus.synchronization_health = $($_.synchronization_health)
    $tAGStatus.Rows.Add($rAGStatus)

    $conn = New-Object System.Data.SqlClient.SqlConnection "Data Source=$($cmsServer);Initial Catalog=`"$($cmsDatabase)`";Integrated Security=SSPI;Application Name=`"Invoke-MorningHealthChecks.ps1`""
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd.CommandText = 'dbo.sp_update_AGStatus'
    $cmd.Parameters.Add("@AGStatus", [System.Data.SqlDbType]::Structured) | Out-Null #Table
    $cmd.Parameters["@AGStatus"].Value = $tAGStatus}
    
    if ($tAGStatus.Rows.Count -gt 0){ #Don't bother calling the procedure if we don't have any rows
            try {
              $cmd.Connection = $conn
              $null = $cmd.ExecuteNonQuery()
            }
            catch {
              $objError = Get-Error $_ -ContinueAfterError
            }
            finally {
              #Make sure this connection is closed
              $conn.Close()
             }
        }
    }

catch{
      Get-Error $_ -ContinueAfterError
    }

    #End Write to DB

    #Display the results to the console
    if ($results.Tables[0].Rows.Count -ne 0) {
        if ($results.Tables[0] | Where-Object {$_.synchronization_health -ne 'HEALTHY'}) {
            if ($_.synchronization_health -eq 'NOT_HEALTHY') {
                Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
            }
            elseif ($_.synchronization_health -eq 'PARTIALLY_HEALTHY') {
                Write-Host "`nWARNING:" -BackgroundColor Yellow -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
            }
        }
        else {
            Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
        }

        $results.Tables[0] | Where-Object {$_.synchronization_health -in 'NOT_HEALTHY','PARTIALLY_HEALTHY'} | Select-Object ag_name,role,database_name,synchronization_state,synchronization_health | Format-Table -AutoSize
    }
    else {
      Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
      Write-Host '*** No Availabiliy Groups detected ***'
    }

} #Get-AGStatus

function Get-DatabaseBackupStatus {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    #Get status of each database
    $server = Get-SqlConnection $targetServer

    $cmd = @"
    SELECT 
	     name AS [database_name]
	    ,recovery_model_desc
	    ,[D] AS last_full_backup
	    ,[I] AS last_differential_backup
	    ,[L] AS last_tlog_backup
	    ,CASE
		    /* These conditions below will cause a CRITICAL status */
		    WHEN [D] IS NULL THEN 'CRITICAL'															-- if last_full_backup is null then critical
		    WHEN [D] < DATEADD(DD,-1,CURRENT_TIMESTAMP) AND [I] IS NULL THEN 'CRITICAL'								-- if last_full_backup is more than 2 days old and last_differential_backup is null then critical
		    WHEN [D] < DATEADD(DD,-7,CURRENT_TIMESTAMP) AND [I] < DATEADD(DD,-2,CURRENT_TIMESTAMP) THEN 'CRITICAL'				-- if last_full_backup is more than 7 days old and last_differential_backup more than 2 days old then critical
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] IS NULL THEN 'CRITICAL'	-- if recovery_model_desc is SIMPLE and last_tlog_backup is null then critical
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] < DATEADD(HH,-6,CURRENT_TIMESTAMP) THEN 'CRITICAL'		-- if last_tlog_backup is more than 6 hours old then critical
		    --/* These conditions below will cause a WARNING status */
		    WHEN [D] < DATEADD(DD,-1,CURRENT_TIMESTAMP) AND [I] < DATEADD(DD,-1,CURRENT_TIMESTAMP) THEN 'WARNING'		-- if last_full_backup is more than 1 day old and last_differential_backup is greater than 1 days old then warning
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] < DATEADD(HH,-3,CURRENT_TIMESTAMP) THEN 'WARNING'		-- if last_tlog_backup is more than 3 hours old then warning
            /* Everything else will return a GOOD status */
		    ELSE 'GOOD'
	     END AS backup_status
	    ,CASE
		    /* These conditions below will cause a CRITICAL status */
		    WHEN [D] IS NULL THEN 'No FULL backups'															-- if last_full_backup is null then critical
		    WHEN [D] < DATEADD(DD,-1,CURRENT_TIMESTAMP) AND [I] IS NULL THEN 'FULL backup > 1 day; no DIFF backups'			-- if last_full_backup is more than 2 days old and last_differential_backup is null then critical
		    WHEN [D] < DATEADD(DD,-7,CURRENT_TIMESTAMP) AND [I] < DATEADD(DD,-2,CURRENT_TIMESTAMP) THEN 'FULL backup > 7 day; DIFF backup > 2 days'	-- if last_full_backup is more than 7 days old and last_differential_backup more than 2 days old then critical
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] IS NULL THEN 'No LOG backups'	-- if recovery_model_desc is SIMPLE and last_tlog_backup is null then critical
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] < DATEADD(HH,-6,CURRENT_TIMESTAMP) THEN 'LOG backup > 6 hours'		-- if last_tlog_backup is more than 6 hours old then critical
		    --/* These conditions below will cause a WARNING status */
		    WHEN [D] < DATEADD(DD,-1,CURRENT_TIMESTAMP) AND [I] < DATEADD(DD,-1,CURRENT_TIMESTAMP) THEN 'FULL backup > 7 day; DIFF backup > 1 day'		-- if last_full_backup is more than 1 day old and last_differential_backup is greater than 1 days old then warning
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] < DATEADD(HH,-3,CURRENT_TIMESTAMP) THEN 'LOG backup > 3 hours'		-- if last_tlog_backup is more than 3 hours old then warning
            /* Everything else will return a GOOD status */
		    ELSE 'No issues'
	     END AS status_desc
    FROM (
	    SELECT
		     d.name
		    ,d.recovery_model_desc
		    ,bs.type
		    ,MAX(bs.backup_finish_date) AS backup_finish_date
	    FROM master.sys.databases d
	    LEFT JOIN msdb.dbo.backupset bs ON d.name = bs.database_name
	    WHERE (bs.type IN ('D','I','L') OR bs.type IS NULL)
	    AND d.database_id <> 2				-- exclude tempdb
	    AND d.source_database_id IS NULL	-- exclude snapshot databases
	    AND d.state NOT IN (1,6,10)			-- exclude offline, restoring, or secondary databases
	    AND d.is_in_standby = 0				-- exclude log shipping secondary databases
	    GROUP BY d.name, d.recovery_model_desc, bs.type
    ) AS SourceTable  
    PIVOT  
    (
	    MAX(backup_finish_date)
	    FOR type IN ([D],[I],[L])  
    ) AS PivotTable
    ORDER BY database_name;
"@
    
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }

#Begin Write to DB

    $cmd = @"
    SELECT 
         @@servername as [server_name]
	    ,name AS [database_name]
	    ,recovery_model_desc
	    ,[D] AS last_full_backup
	    ,[I] AS last_differential_backup
	    ,[L] AS last_tlog_backup
	    ,CASE
		    /* These conditions below will cause a CRITICAL status */
		    WHEN [D] IS NULL THEN 'CRITICAL'															-- if last_full_backup is null then critical
		    WHEN [D] < DATEADD(DD,-1,CURRENT_TIMESTAMP) AND [I] IS NULL THEN 'CRITICAL'								-- if last_full_backup is more than 2 days old and last_differential_backup is null then critical
		    WHEN [D] < DATEADD(DD,-7,CURRENT_TIMESTAMP) AND [I] < DATEADD(DD,-2,CURRENT_TIMESTAMP) THEN 'CRITICAL'				-- if last_full_backup is more than 7 days old and last_differential_backup more than 2 days old then critical
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] IS NULL THEN 'CRITICAL'	-- if recovery_model_desc is SIMPLE and last_tlog_backup is null then critical
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] < DATEADD(HH,-6,CURRENT_TIMESTAMP) THEN 'CRITICAL'		-- if last_tlog_backup is more than 6 hours old then critical
		    --/* These conditions below will cause a WARNING status */
		    WHEN [D] < DATEADD(DD,-1,CURRENT_TIMESTAMP) AND [I] < DATEADD(DD,-1,CURRENT_TIMESTAMP) THEN 'WARNING'		-- if last_full_backup is more than 1 day old and last_differential_backup is greater than 1 days old then warning
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] < DATEADD(HH,-3,CURRENT_TIMESTAMP) THEN 'WARNING'		-- if last_tlog_backup is more than 3 hours old then warning
            /* Everything else will return a GOOD status */
		    ELSE 'GOOD'
	     END AS backup_status
	    ,CASE
		    /* These conditions below will cause a CRITICAL status */
		    WHEN [D] IS NULL THEN 'No FULL backups'															-- if last_full_backup is null then critical
		    WHEN [D] < DATEADD(DD,-1,CURRENT_TIMESTAMP) AND [I] IS NULL THEN 'FULL backup > 1 day; no DIFF backups'			-- if last_full_backup is more than 2 days old and last_differential_backup is null then critical
		    WHEN [D] < DATEADD(DD,-7,CURRENT_TIMESTAMP) AND [I] < DATEADD(DD,-2,CURRENT_TIMESTAMP) THEN 'FULL backup > 7 day; DIFF backup > 2 days'	-- if last_full_backup is more than 7 days old and last_differential_backup more than 2 days old then critical
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] IS NULL THEN 'No LOG backups'	-- if recovery_model_desc is SIMPLE and last_tlog_backup is null then critical
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] < DATEADD(HH,-6,CURRENT_TIMESTAMP) THEN 'LOG backup > 6 hours'		-- if last_tlog_backup is more than 6 hours old then critical
		    --/* These conditions below will cause a WARNING status */
		    WHEN [D] < DATEADD(DD,-1,CURRENT_TIMESTAMP) AND [I] < DATEADD(DD,-1,CURRENT_TIMESTAMP) THEN 'FULL backup > 7 day; DIFF backup > 1 day'		-- if last_full_backup is more than 1 day old and last_differential_backup is greater than 1 days old then warning
		    WHEN recovery_model_desc <> 'SIMPLE' AND name <> 'model' AND [L] < DATEADD(HH,-3,CURRENT_TIMESTAMP) THEN 'LOG backup > 3 hours'		-- if last_tlog_backup is more than 3 hours old then warning
            /* Everything else will return a GOOD status */
		    ELSE 'No issues'
	     END AS status_desc
    FROM (
	    SELECT
		     d.name
		    ,d.recovery_model_desc
		    ,bs.type
		    ,MAX(bs.backup_finish_date) AS backup_finish_date
	    FROM master.sys.databases d
	    LEFT JOIN msdb.dbo.backupset bs ON d.name = bs.database_name
	    WHERE (bs.type IN ('D','I','L') OR bs.type IS NULL)
	    AND d.database_id <> 2				-- exclude tempdb
	    AND d.source_database_id IS NULL	-- exclude snapshot databases
	    AND d.state NOT IN (1,6,10)			-- exclude offline, restoring, or secondary databases
	    AND d.is_in_standby = 0				-- exclude log shipping secondary databases
	    GROUP BY d.name, d.recovery_model_desc, bs.type
    ) AS SourceTable  
    PIVOT  
    (
	    MAX(backup_finish_date)
	    FOR type IN ([D],[I],[L])  
    ) AS PivotTable
    ORDER BY database_name;
"@
    
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }
#Build a DataTable to hold the Backup Status
$tBackupStatus = New-Object System.Data.DataTable
$columnName = New-Object System.Data.DataColumn server_name,([string])
$tBackupStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn database_name,([string])
$tBackupStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn recovery_model_desc,([string])
$tBackupStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn last_full_backup,([string])
$tBackupStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn last_differential_backup,([string])
$tBackupStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn last_tlog_backup,([string])
$tBackupStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn backup_status,([string])
$tBackupStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn status_desc,([string])
$tBackupStatus.Columns.Add($columnName)


try {#For each row in results, add it to the table object
	$results.Tables[0] | ForEach-Object {
    $rBackupStatus = $tBackupStatus.NewRow()
    $rBackupStatus.server_name = $($_.server_name)
    $rBackupStatus.database_name = $($_.database_name)
    $rBackupStatus.recovery_model_desc = $($_.recovery_model_desc)
    $rBackupStatus.last_full_backup = $($_.last_full_backup)
    $rBackupStatus.last_differential_backup = $($_.last_differential_backup)
	$rBackupStatus.last_tlog_backup = $($_.last_tlog_backup)
    $rBackupStatus.backup_status = $($_.backup_status)
	$rBackupStatus.status_desc = $($_.status_desc)
    $tBackupStatus.Rows.Add($rBackupStatus)

    #Connect to the CMS database and pass the table object to the stored procedure
    $conn = New-Object System.Data.SqlClient.SqlConnection "Data Source=$($cmsServer);Initial Catalog=`"$($cmsDatabase)`";Integrated Security=SSPI;Application Name=`"Invoke-MorningHealthChecks.ps1`""
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd.CommandText = 'dbo.sp_update_backupStatus'
    $cmd.Parameters.Add("@backupStatus", [System.Data.SqlDbType]::Structured) | Out-Null #Table
    $cmd.Parameters["@backupStatus"].Value = $tBackupStatus}
    
    if ($tBackupStatus.Rows.Count -gt 0){ #Don't bother calling the procedure if we don't have any rows
            try {
              $cmd.Connection = $conn
              $null = $cmd.ExecuteNonQuery()
            }
            catch {
              $objError = Get-Error $_ -ContinueAfterError
            }
            finally {
              #Make sure this connection is closed
              $conn.Close()
             }
        }
    }

catch{
      Get-Error $_ -ContinueAfterError
    }
#End Write to DB

    #Display the results to the console
    if ($results.Tables[0] | Where-Object {$_.backup_status -eq 'CRITICAL'}) {
        Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
    }
    elseif ($results.Tables[0] | Where-Object {$_.backup_status -eq 'WARNING'}) {
        Write-Host "`nWARNING:" -BackgroundColor Yellow -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
    }
    else {
        Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
    }

    $results.Tables[0] | Where-Object {$_.backup_status -in 'CRITICAL','WARNING'} | Select-Object database_name,backup_status,status_desc | Format-Table -AutoSize

} #Get-DatabaseBackupStatus

function Get-DiskSpace {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    $server = Get-SqlConnection $targetServer

    $cmd = @"
    SELECT DISTINCT 
         vs.volume_mount_point
        ,vs.logical_volume_name
        ,CONVERT(DECIMAL(18,2), vs.total_bytes/1073741824.0) AS total_size_gb
        ,CONVERT(DECIMAL(18,2), vs.available_bytes/1073741824.0) AS available_size_gb
        ,CONVERT(DECIMAL(18,2), vs.available_bytes * 1. / vs.total_bytes * 100.) AS free_space_pct
    FROM sys.master_files AS f WITH (NOLOCK)
    CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs 
    ORDER BY vs.volume_mount_point OPTION (RECOMPILE);
"@

    #Get disk space and store it in the repository
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }

    #Display the results to the console
    if ($results.Tables[0] | Where-Object {$_.free_space_pct -lt 10.0}) {
        Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
    }
    elseif ($results.Tables[0] | Where-Object {$_.free_space_pct -lt 20.0 -and $_.free_space_pct -gt 10.0}) {
        Write-Host "`nWARNING:" -BackgroundColor Yellow -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
    }
    else { Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)" }

    $results.Tables[0] | Where-Object {$_.free_space_pct -lt 20.0} | Select-Object volume_mount_point,total_size_gb,available_size_gb,free_space_pct | Format-Table -AutoSize
#Begin Write to DB
    $cmd = @"
    SELECT DISTINCT
         @@servername server_name 
        ,vs.volume_mount_point
        ,vs.logical_volume_name
        ,CONVERT(DECIMAL(18,2), vs.total_bytes/1073741824.0) AS total_size_gb
        ,CONVERT(DECIMAL(18,2), vs.available_bytes/1073741824.0) AS available_size_gb
        ,CONVERT(DECIMAL(18,2), vs.available_bytes * 1. / vs.total_bytes * 100.) AS free_space_pct
    FROM sys.master_files AS f WITH (NOLOCK)
    CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs 
    ORDER BY vs.volume_mount_point OPTION (RECOMPILE);
"@
    try {
            $results = $server.ExecuteWithResults($cmd)
        }
        catch {
            Get-Error $_ -ContinueAfterError
        }
#Build a DataTable to hold the Disk Space
    $tDiskSpace = New-Object System.Data.DataTable
    $columnName = New-Object System.Data.DataColumn server_name,([string])
    $tDiskSpace.Columns.Add($columnName)
    $columnName = New-Object System.Data.DataColumn volume_mount_point,([string])
    $tDiskSpace.Columns.Add($columnName)
    $columnName = New-Object System.Data.DataColumn logical_volume_name,([string])
    $tDiskSpace.Columns.Add($columnName)
    $columnName = New-Object System.Data.DataColumn total_size_gb,([string])
    $tDiskSpace.Columns.Add($columnName)
    $columnName = New-Object System.Data.DataColumn available_size_gb,([string])
    $tDiskSpace.Columns.Add($columnName)
    $columnName = New-Object System.Data.DataColumn free_space_pct,([string])
    $tDiskSpace.Columns.Add($columnName)


try {
	$results.Tables[0] | ForEach-Object {
    $rDiskSpace = $tDiskSpace.NewRow()
    $rDiskSpace.server_name = $($_.server_name)
    $rDiskSpace.volume_mount_point = $($_.volume_mount_point)
    $rDiskSpace.logical_volume_name = $($_.logical_volume_name)
    $rDiskSpace.total_size_gb = $($_.total_size_gb)
    $rDiskSpace.available_size_gb = $($_.available_size_gb)
	$rDiskSpace.free_space_pct = $($_.free_space_pct)
    $tDiskSpace.Rows.Add($rDiskSpace)

    $conn = New-Object System.Data.SqlClient.SqlConnection "Data Source=$($cmsServer);Initial Catalog=`"$($cmsDatabase)`";Integrated Security=SSPI;Application Name=`"Invoke-MorningHealthChecks.ps1`""
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd.CommandText = 'dbo.update_diskSpace'
    $cmd.Parameters.Add("@diskSpace", [System.Data.SqlDbType]::Structured) | Out-Null #Table
    $cmd.Parameters["@diskSpace"].Value = $tDiskSpace}
    
    if ($tDiskSpace.Rows.Count -gt 0){ #Don't bother calling the procedure if we don't have any rows
            try {
              $cmd.Connection = $conn
              $null = $cmd.ExecuteNonQuery()
            }
            catch {
              $objError = Get-Error $_ -ContinueAfterError
            }
            finally {
              #Make sure this connection is closed
              $conn.Close()
             }
        }
    }

catch{
      Get-Error $_ -ContinueAfterError
    }
#End Write to DB
} #Get-DiskSpace

function Get-FailedJobs {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    $server = Get-SqlConnection $targetServer

    $cmd = @"
    SELECT 
	    j.name AS job_name
	    ,CASE
		    WHEN a.start_execution_date IS NULL THEN 'Not Running'
		    WHEN a.start_execution_date IS NOT NULL AND a.stop_execution_date IS NULL THEN 'Running'
		    WHEN a.start_execution_date IS NOT NULL AND a.stop_execution_date IS NOT NULL THEN 'Not Running'
	        END AS 'current_run_status'
	    ,a.start_execution_date AS 'last_start_date'
	    ,a.stop_execution_date AS 'last_stop_date'
	    ,CASE h.run_status
		    WHEN 0 THEN 'Failed'
		    WHEN 1 THEN 'Succeeded'
		    WHEN 2 THEN 'Retry'
		    WHEN 3 THEN 'Canceled'
	        END AS 'last_run_status'
	    ,h.message AS 'job_output'
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.sysjobactivity a ON j.job_id = a.job_id
    LEFT JOIN msdb.dbo.sysjobhistory h ON a.job_history_id = h.instance_id
    WHERE a.session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity)
		AND j.enabled = 1
    ORDER BY j.name;
"@

    #Get the failed jobs and store it in the repository
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }

    #Display the results to the console
    if ($results.Tables[0] | Where-Object {$_.last_run_status -eq 'Failed'}) {
        Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
    }
    elseif ($results.Tables[0] | Where-Object {$_.last_run_status -in 'Retry','Canceled'}) {
        Write-Host "`nWARNING:" -BackgroundColor Yellow -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
    }
    else {
      Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
    }

    $results.Tables[0] | Where-Object {$_.last_run_status -in 'Failed','Retry','Canceled'} | Select-Object job_name,current_run_status,last_run_status,last_stop_date | Format-Table -AutoSize
    #Begin Write to DB
#Get new data with added columns
$cmd = @"
    SELECT
        @@SERVERNAME server_name 
	    ,j.name AS job_name
	    ,CASE
		    WHEN a.start_execution_date IS NULL THEN 'Not Running'
		    WHEN a.start_execution_date IS NOT NULL AND a.stop_execution_date IS NULL THEN 'Running'
		    WHEN a.start_execution_date IS NOT NULL AND a.stop_execution_date IS NOT NULL THEN 'Not Running'
	        END AS 'current_run_status'
	    ,a.start_execution_date AS 'last_start_date'
	    ,a.stop_execution_date AS 'last_stop_date'
	    ,CASE h.run_status
		    WHEN 0 THEN 'Failed'
		    WHEN 1 THEN 'Succeeded'
		    WHEN 2 THEN 'Retry'
		    WHEN 3 THEN 'Canceled'
	        END AS 'last_run_status'
	    ,h.message AS 'job_output'
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.sysjobactivity a ON j.job_id = a.job_id
    LEFT JOIN msdb.dbo.sysjobhistory h ON a.job_history_id = h.instance_id
    WHERE a.session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity)
		AND j.enabled = 1
    ORDER BY j.name;
"@
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }
#Build a DataTable to hold the Job Status
$tJobStatus = New-Object System.Data.DataTable
$columnName = New-Object System.Data.DataColumn server_name,([string])
$tJobStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn job_name,([string])
$tJobStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn current_run_status,([string])
$tJobStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn last_start_date,([string])
$tJobStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn last_stop_date,([string])
$tJobStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn last_run_status,([string])
$tJobStatus.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn job_output,([string])
$tJobStatus.Columns.Add($columnName)


try {
	$results.Tables[0] | ForEach-Object {
    $rJobStatus = $tJobStatus.NewRow()
    $rJobStatus.server_name = $($_.server_name)
    $rJobStatus.job_name = $($_.job_name)
    $rJobStatus.current_run_status = $($_.current_run_status)
    $rJobStatus.last_start_date = $($_.last_start_date)
    $rJobStatus.last_stop_date = $($_.last_stop_date)
    $rJobStatus.last_run_status = $($_.last_run_status)
	$rJobStatus.job_output = $($_.job_output)
    $tJobStatus.Rows.Add($rJobStatus)

    $conn = New-Object System.Data.SqlClient.SqlConnection "Data Source=$($cmsServer);Initial Catalog=`"$($cmsDatabase)`";Integrated Security=SSPI;Application Name=`"Invoke-MorningHealthChecks.ps1`""
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd.CommandText = 'dbo.update_jobStatus'
    $cmd.Parameters.Add("@jobStatus", [System.Data.SqlDbType]::Structured) | Out-Null #Table
    $cmd.Parameters["@jobStatus"].Value = $tJobStatus}
    
    if ($tJobStatus.Rows.Count -gt 0){ #Don't bother calling the procedure if we don't have any rows
            try {
              $cmd.Connection = $conn
              $null = $cmd.ExecuteNonQuery()
            }
            catch {
              $objError = Get-Error $_ -ContinueAfterError
            }
            finally {
              #Make sure this connection is closed
              $conn.Close()
             }
        }
    }

catch{
      Get-Error $_ -ContinueAfterError
    }
#End Write to DB
} #Get-FailedJobs

function Get-AppLogEvents {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    <#
      NOTE: If SQL is using the "-n" startup paramenter, then SQL does not 
      write to the Windows Application log, and this will always return no errors.
      https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/database-engine-service-startup-options
    #>

    #Get the physical hostname
    $server = Get-SqlConnection $targetServer

    if($server.TrueName.Split('\')[1]) {
        $source = "MSSQL`$$($server.TrueName.Split('\')[1])"
    }
    else {
        $source = 'MSSQLSERVER'
    }

    $cmd = "SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS');"
    try {
        $computerName = $server.ExecuteScalar($cmd)
    }
    catch {
        Get-Error $_
    }
    
    #ErrorAction = SilentlyConintue to prevent "No events were found"
    $events = $null
    $events = Get-WinEvent -ComputerName $computerName -FilterHashtable @{LogName='Application';Level=2;StartTime=((Get-Date).AddDays(-1));ProviderName=$source} -ErrorAction SilentlyContinue

    if ($events) {
        #Display the results to the console
        Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
        Write-Host "Found $($events.Count) error(s)! Showing only the most recent events:"
        $events | Select-Object TimeCreated,@{Label='EventID';Expression={$_.Id}},Message | Format-Table -AutoSize
    }
    else { Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)" }
} #Get-AppLogEvents

function Get-ServiceStatus {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    $cmd = "SELECT servicename,CASE SERVERPROPERTY('IsClustered') WHEN 0 THEN startup_type_desc WHEN 1 THEN 'Automatic' END AS startup_type_desc,status_desc FROM sys.dm_server_services;"

    #Get status of each SQL service
    $server = Get-SqlConnection $targetServer
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }

    #Display the results to the console
    if ($results.Tables[0] | Where-Object {$_.status_desc -ne 'Running' -and $_.startup_type_desc -eq 'Automatic'}) {
        Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
    }
    else { Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)" }

    #Display the results to the console
    if ($results.Tables[0] | Where-Object {$_.status_desc -ne 'Running' -and $_.startup_type_desc -eq 'Automatic'}) {
        $results.Tables[0] | ForEach-Object {
            Write-Host "$($_.servicename): $($_.status_desc)"
        }
    }

#Begin Write to DB

    $cmd = "SELECT @@servername server_name, servicename as service_name,CASE SERVERPROPERTY('IsClustered') WHEN 0 THEN startup_type_desc WHEN 1 THEN 'Automatic' END AS startup_type_desc,status_desc FROM sys.dm_server_services;"

    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }
    #Build a DataTable to hold the SQL Service Status
            $tServiceStatus = New-Object System.Data.DataTable
            $columnName = New-Object System.Data.DataColumn server_name,([string])
            $tServiceStatus.Columns.Add($columnName)
            $columnName = New-Object System.Data.DataColumn service_name,([string])
            $tServiceStatus.Columns.Add($columnName)
            $columnName = New-Object System.Data.DataColumn startup_type_desc,([string])
            $tServiceStatus.Columns.Add($columnName)
            $columnName = New-Object System.Data.DataColumn status_desc,([string])
            $tServiceStatus.Columns.Add($columnName)
    
    try {#For each row in results, add it to the table object
    
    	$results.Tables[0] | ForEach-Object {

        $rServiceStatus = $tServiceStatus.NewRow()
        $rServiceStatus.server_name = $($_.server_name)
        $rServiceStatus.service_name = $($_.service_name)
        $rServiceStatus.startup_type_desc = $($_.startup_type_desc)
        $rServiceStatus.status_desc = $($_.status_desc)
        $tServiceStatus.Rows.Add($rServiceStatus)
        
        #Connect to the CMS database and pass the table object to the stored procedure
        $conn = New-Object System.Data.SqlClient.SqlConnection "Data Source=$($cmsServer);Initial Catalog=`"$($cmsDatabase)`";Integrated Security=SSPI;Application Name=`"Invoke-MorningHealthChecks.ps1`""
        $conn.Open()
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $cmd.CommandText = 'dbo.sp_update_serviceStatus'
        $cmd.Parameters.Add("@serviceStatus", [System.Data.SqlDbType]::Structured) | Out-Null #Table
        $cmd.Parameters["@serviceStatus"].Value = $tServiceStatus}
        
        if ($tServiceStatus.Rows.Count -gt 0){ #Don't bother calling the procedure if we don't have any rows
                try {
                  $cmd.Connection = $conn
                  $null = $cmd.ExecuteNonQuery()
                }
                catch {
                  $objError = Get-Error $_ -ContinueAfterError
                }
                finally {
                  #Make sure this connection is closed
                  $conn.Close()
                 }
            }
        }

    catch{
          Get-Error $_ -ContinueAfterError
        }

#End Write to DB
} #Get-ServiceStatus

function Get-ClusterStatus {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    $cmd = @"
    SELECT
         NodeName AS cluster_node_name
        ,UPPER(status_description) AS cluster_node_status
    FROM sys.dm_os_cluster_nodes
    UNION
    SELECT
         member_name AS cluster_node_name
        ,member_state_desc AS cluster_node_status
    FROM sys.dm_hadr_cluster_members
    WHERE member_type = 0;
"@

    #If one exists, get status of each Availability Group
    $server = Get-SqlConnection $targetServer
    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }

    #Display the results to the console
    if ($results.Tables[0].Rows.Count -ne 0) {
        if ($results.Tables[0] | Where-Object {$_.cluster_node_status -ne 'UP'}) {
            Write-Host "`nCRITICAL:" -BackgroundColor Red -ForegroundColor White -NoNewline; Write-Host " $($server.TrueName)"
        }
        else { Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)" }
    }

    #Display the results to the console
    if ($results.Tables[0] | Where-Object {$_.cluster_node_status -ne 'UP'}) {
        $results.Tables[0] | ForEach-Object {
            if ($_.cluster_node_status -ne 'UP') {
                Write-Host "$($_.cluster_node_name): $($_.cluster_node_status)" -BackgroundColor Red -ForegroundColor White
            }
            else {
                Write-Host "$($_.cluster_node_name): $($_.cluster_node_status)"
            }
        }
    }
    if ($results.Tables[0].Rows.Count -eq 0) {
      Write-Host "`nGOOD:" -BackgroundColor Green -ForegroundColor Black -NoNewline; Write-Host " $($server.TrueName)"
      Write-Host '*** No cluster detected ***'
    }
#Begin Write to DB
    #Build a DataTable to hold the Cluster Status
    $tCLStatus = New-Object System.Data.DataTable
    $columnName = New-Object System.Data.DataColumn cluster_node_name,([string])
    $tCLStatus.Columns.Add($columnName)
    $columnName = New-Object System.Data.DataColumn cluster_node_status,([string])
    $tCLStatus.Columns.Add($columnName)


try {
	$results.Tables[0] | ForEach-Object {
    $rCLStatus = $tCLStatus.NewRow()
    $rCLStatus.cluster_node_name = $($_.cluster_node_name)
    $rCLStatus.cluster_node_status = $($_.cluster_node_status)
    $tCLStatus.Rows.Add($rCLStatus)

    $conn = New-Object System.Data.SqlClient.SqlConnection "Data Source=$($cmsServer);Initial Catalog=`"$($cmsDatabase)`";Integrated Security=SSPI;Application Name=`"Invoke-MorningHealthChecks.ps1`""
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd.CommandText = 'dbo.update_clusterStatus'
    $cmd.Parameters.Add("@clusterStatus", [System.Data.SqlDbType]::Structured) | Out-Null #Table
    $cmd.Parameters["@clusterStatus"].Value = $tCLStatus}
    
    if ($tCLStatus.Rows.Count -gt 0){ #Don't bother calling the procedure if we don't have any rows
            try {
              $cmd.Connection = $conn
              $null = $cmd.ExecuteNonQuery()
            }
            catch {
              $objError = Get-Error $_ -ContinueAfterError
            }
            finally {
              #Make sure this connection is closed
              $conn.Close()
             }
        }
    }

catch{
      Get-Error $_ -ContinueAfterError
    }
#End Write to DB
} #Get-ClusterStatus
#Get-SQLLogins
function Get-SQLLogins {
  Param (
    [CmdletBinding()]
    [parameter(Position=0,Mandatory=$true)][ValidateNotNullOrEmpty()]$targetServer
    )

    $server = Get-SqlConnection $targetServer

    $cmd = @"
if(SELECT SERVERPROPERTY('IsIntegratedSecurityOnly'))=1
	print 'Server is configured for Windows Authentication Only, Goodbye.'
else begin
	-- table variable to hold filtered results from the CTE
	declare @LoginsExpiring table(recordID int identity(1,1), serverName sysname, SQL_Login varchar(50), DaysUntilExpiration varchar(50));
	-- This is the notification threshold
	declare @limit int = 360;
	-- CTE to capture and filter based on @limit
	with sqlLogins_CTE(serverName, [sqlLogin], DaysUntilExpiration)
	as
	-- CTE Query
	(
		select @@servername, [name], LOGINPROPERTY([name], 'DaysUntilExpiration')[DaysUntilExpiration] 
		from sys.server_principals
		where [type] = 'S' -- SQL Login
		and name not like '#%'
		and sid <> 0x01
	)
	select serverName, [sqlLogin], cast(isnull(DaysUntilExpiration,'Non-Expiring Account') as varchar(20)) daysUntilExpired
	from sqlLogins_CTE
	where DaysUntilExpiration is null or DaysUntilExpiration <= @limit;

end --if
"@

    try {
        $results = $server.ExecuteWithResults($cmd)
    }
    catch {
        Get-Error $_ -ContinueAfterError
    }


#Begin Write to DB
#Build a DataTable to hold the Availability Group Status
$tSQLLogin = New-Object System.Data.DataTable
$columnName = New-Object System.Data.DataColumn serverName,([string])
$tSQLLogin.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn sqlLogin,([string])
$tSQLLogin.Columns.Add($columnName)
$columnName = New-Object System.Data.DataColumn daysUntilExpired,([string])
$tSQLLogin.Columns.Add($columnName)


try {
	$results.Tables[0] | ForEach-Object {
    $rSQLLogin = $tSQLLogin.NewRow()
    $rSQLLogin.serverName = $($_.serverName)
    $rSQLLogin.sqlLogin = $($_.sqlLogin)
    $rSQLLogin.daysUntilExpired = $($_.daysUntilExpired)
    $tSQLLogin.Rows.Add($rSQLLogin)

    $conn = New-Object System.Data.SqlClient.SqlConnection "Data Source=$($cmsServer);Initial Catalog=`"$($cmsDatabase)`";Integrated Security=SSPI;Application Name=`"Invoke-MorningHealthChecks.ps1`""
    $conn.Open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
    $cmd.CommandText = 'dbo.update_SQLLoginsTracker'
    $cmd.Parameters.Add("@SQLLoginStatus", [System.Data.SqlDbType]::Structured) | Out-Null #Table
    $cmd.Parameters["@SQLLoginStatus"].Value = $tSQLLogin}
    
    if ($tSQLLogin.Rows.Count -gt 0){ #Don't bother calling the procedure if we don't have any rows
            try {
              $cmd.Connection = $conn
              $null = $cmd.ExecuteNonQuery()
            }
            catch {
              $objError = Get-Error $_ -ContinueAfterError
            }
            finally {
              #Make sure this connection is closed
              $conn.Close()
             }
        }
    }

catch{
      Get-Error $_ -ContinueAfterError
    }
#End Write to DB

} #Get-SQLLogins
####################   MAIN   ########################
Clear-Host

$startTime = Get-Date

[string[]]$targetServerList = $null

#Get the server list from the CMS group, only if one was specified
if($cmsServer) {
    $targetServerList = Get-CmsServer -cmsServer $cmsServer -cmsGroup $cmsGroup -recurse
}
else {
    $targetServerList = $serverList
}

#Check uptime of each SQL Server
Write-Host "##########  SQL Server Uptime Report (DD.HH:MM:SS):  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-SqlUptime -targetServer $targetServer}

#Get the status of each SQL service
Write-Host "`n##########  SQL Service(s) Status Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-ServiceStatus -targetServer $targetServer }

#Get the state of each Windows cluster node
Write-Host "`n##########  Windows Cluster Node Status Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-ClusterStatus -targetServer $targetServer }

#Get status of each database for each server
Write-Host "`n##########  Database Status Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-DatabaseStatus -targetServer $targetServer}

#Get status of each Availability Group for each server
Write-Host "`n##########  Availability Groups Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-AGStatus -targetServer $targetServer}

#Get the most recent backup of each database
Write-Host "`n##########  Database Backup Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-DatabaseBackupStatus -targetServer $targetServer}

#Get the disk space info for each server
Write-Host "`n##########  Disk Space Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-DiskSpace -targetServer $targetServer}

#Get the failed jobs for each server
Write-Host "`n##########  Failed Jobs Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-FailedJobs -targetServer $targetServer}

#Check the Application event log for SQL errors
Write-Host "`n##########  Application Event Log Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-AppLogEvents -targetServer $targetServer}
##Check the SQLLoginExpirations
Write-Host "`n##########  SQL Logins Report:  ##########" -BackgroundColor Black -ForegroundColor Green
ForEach ($targetServer in $targetServerList) { Get-SQLLogins -targetServer $targetServer}

##Execution Summary
Write-Host "`nElapsed Time: $(New-TimeSpan -Start $startTime -End (Get-Date))"
