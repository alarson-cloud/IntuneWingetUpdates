#Requires -Version 5.1
#alarson@hbs.net - 2025-03-11
Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
$InformationPreference = 'Continue'
$exitCode = 0
$log = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\AppInstall.log"
Start-Transcript -Path $log -Append
$winget_exe = Resolve-Path "$($env:ProgramFiles)\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
if($winget_exe.count -gt 1){
	Write-Output "Multiple Winget versions detected.`nSelecting the latest version."
	$winget_exeLatest = $winget_exe | ForEach-Object{
		Get-Item $_.Path
	} | Sort-Object CreationTime -Descending | Select-Object -First 1
	$winget_exe = $winget_exeLatest.FullName
}

	#Add Included App IDs here only to update the apps in this list. Leave the included apps Blank if you want to update all available apps
$includedApps = @(
	"Adobe.Acrobat.Reader.64-bit"
	"Zoom.Zoom"
	)

Try{
	Foreach($app in $includedApps){
		Write-Output "Trying Install of $($app)"
		&$winget_exe install --id $app --silent --accept-package-agreements --accept-source-agreements -s winget --force --verbose-logs
		$installed = &$winget_exe list $app
			if($installed){
				Write-Output "$($app) is installed."
			}else{
				Write-Output "$($app) was not installed correctly."
			}
	}
}Catch{
	$errMsg = if($_.Exception -and $_.Exception.Message){$_.Exception.Message}else{"Unknown error occurred."}
	Write-Error "An error occurred: $errMsg`nFull error details: $_"
	$exitCode = 1
}Finally{
	Stop-Transcript
	exit $exitCode
}