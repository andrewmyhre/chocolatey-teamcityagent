if ($env:chocolateyPackageParameters -eq $null) {
    Write-ChocolateyFailure 'TeamCityAgent' "No parameters have been passed into Chocolatey install, e.g. -params 'serverUrl=http://...;agentName=...;agentDir=...'"
}

$parameters = ConvertFrom-StringData -StringData $env:chocolateyPackageParameters.Replace(";", "`n")

## Validate parameters
if ($parameters["serverUrl"] -eq $null) {
    Write-ChocolateyFailure 'TeamCityAgent' "Please specify the TeamCity server URL by passing it as a parameter to Chocolatey install, e.g. -params 'serverUrl=http://...'"
}
if ($parameters["agentDir"] -eq $null) {
    $parameters["agentDir"] = "$env:SystemDrive\buildAgent"
    Write-Host No agent directory is specified. Defaulting to $parameters["agentDir"]
}
if ($parameters["agentName"] -eq $null) {
    $parameters["agentName"] = "$env:COMPUTERNAME"
    Write-Host No agent name is specified. Defaulting to $parameters["agentName"]
}

## Make local variables of it
$serverUrl = $parameters["serverUrl"];
$agentDir = $parameters["agentDir"];
$agentName = $parameters["agentName"];

## Download from TeamCity server
Get-ChocolateyWebFile 'buildAgent.zip' "$env:TEMP\buildAgent.zip" "$serverUrl/update/buildAgent.zip"

## Extract
Get-ChocolateyUnzip "$env:TEMP\buildAgent.zip" $agentDir  

## Clean up
del "$env:TEMP\buildAgent.zip"

# Configure agent
copy $agentDir\conf\buildAgent.dist.properties $agentDir\conf\buildAgent.properties
(Get-Content $agentDir\conf\buildAgent.properties) | Foreach-Object {
    $_ -replace 'serverUrl=http://localhost:8111/', "serverUrl=$serverUrl" `
	   -replace 'name=', "name=$agentName"
    } | Set-Content $agentDir\conf\buildAgent.properties

Start-ChocolateyProcessAsAdmin "/C `"cd $agentDir\bin && $agentDir\bin\service.install.bat && $agentDir\bin\service.start.bat`"" cmd

## Done!
Write-ChocolateySuccess 'TeamCityAgent'
exit