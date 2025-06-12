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

	#Add Included App IDs here only to install all the apps in this list.
$includedApps = @(
	"Adobe.Acrobat.Reader.64-bit"
	"Zoom.Zoom"
	)

Try{
	Foreach($app in $includedApps){
		Write-Output "Trying Install of $($app)"
		&$winget_exe install --id $app --silent --accept-package-agreements --accept-source-agreements -s winget --force --verbose-logs
		$jsonFile = "$($env:windir)\temp\apps.txt"
			if($jsonFile){ 
				Clear-Content $jsonFile
			}
			&$winget_exe export -s winget -o $jsonFile --include-versions --ignore-warnings
			$apps = get-content $jsonFile | ConvertFrom-Json
			Set-Content $apps.Sources.Packages -Path $jsonFile
			Get-Content $jsonFile | Sort-Object | Set-Content $jsonFile
			$allapps = Get-Content $jsonFile
				$Apps = foreach($line in $allapps){
					if($line -match 'PackageIdentifier=(.*?); Version=(.*)'){
						[PSCustomObject]@{
							PackageIdentifier = $matches[1]
							Version = $matches[2].TrimEnd('}')
						}
					}
				}
			if($apps.PackageIdentifier -like $app){
				Write-Output "$($app) was installed successfully."
			}else{
				Write-Output "$($app) was not detected as installed."
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