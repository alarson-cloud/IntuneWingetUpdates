#Requires -Version 5.1
#alarson@hbs.net - 2025-03-11
Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
$InformationPreference = 'Continue'

param (
	[switch] $install = $False,
	[switch] $uninstall = $False,
	[string] $appID
)

$exitCode = 0
$log = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\$($appID)_appInstall.log"

Start-Transcript -Path $log -append
$winget_exe = Resolve-Path "$($env:ProgramFiles)\Windowsapps\Microsoft.DesktopappInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
if($winget_exe.count -gt 1){
	Write-Output "Multiple Winget versions detected.`nSelecting the latest version."
	$winget_exeLatest = $winget_exe | ForEach-Object{
		Get-Item $_.Path
	} | Sort-Object CreationTime -Descending | Select-Object -First 1
	$winget_exe = $winget_exeLatest.FullName
}

if ($install) {
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
	if($apps.PackageIdentifier -like $appID) {
		Write-Output "$($appID) is already installed"
		exit $exitCode
	} else {
		Try{
			Write-Output "Trying Install of $($appID)"
			&$winget_exe install --id $appID --silent --accept-package-agreements --accept-source-agreements -s winget --force --verbose-logs
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
			if($apps.PackageIdentifier -like $appID){
				Write-Output "$($appID) was installed correctly."
			}else{
				Write-Output "$($appID) was not installed successfully."
				$exitCode = 1
			}
		}Catch{
			$errMsg = if($_.Exception -and $_.Exception.Message){$_.Exception.Message}else{"Unknown error occurred."}
			Write-Error "An error occurred: $errMsg`nFull error details: $_"
			$exitCode = 1
		}Finally{
			Stop-Transcript
			exit $exitCode
		}
	}
} elseif ($uninstall) {
	Try{
	Write-Output "Trying uninstall of $($appID)"
	&$winget_exe uninstall --id $appID --all-versions --silent --accept-source-agreements -s winget --force --verbose-logs
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
		if($apps.PackageIdentifier -like $appID){
			Write-Output "$($appID) was not removed correctly."
			$exitCode = 1
		}else{
			Write-Output "$($appID) was uninstalled successfully."
		}
	}Catch{
		$errMsg = if($_.Exception -and $_.Exception.Message){$_.Exception.Message}else{"Unknown error occurred."}
		Write-Error "An error occurred: $errMsg`nFull error details: $_"
		$exitCode = 1
	}Finally{
		Stop-Transcript
		exit $exitCode
	}
} else {
	$errMsg = "Invalid parameter option"
	Write-Error "An error occurred: $errMsg`nFull error details: $_"
	$exitCode = 3
	exit $exitCode
}