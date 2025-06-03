#Requires -Version 5.1
#alarson@hbs.net - 2025-03-11
Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
$InformationPreference = 'Continue'
$exitCode = 0
$log = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\AppUpdates.log"
Start-Transcript -Path $log -Append
$winget_exe = Resolve-Path "$($env:ProgramFiles)\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
if($winget_exe.count -gt 1){
	Write-Output "Multiple Winget versions detected.`nSelecting the latest version."
	$winget_exeLatest = $winget_exe | ForEach-Object{
		Get-Item $_.Path
	} | Sort-Object CreationTime -Descending | Select-Object -First 1
	$winget_exe = $winget_exeLatest.FullName
}
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
	#Add Excluded App IDs here to Exclude them
$excludedApps = @(
	"Microsoft.Office"
	)
	#Add Included App IDs here only to update the apps in this list. Leave the included apps Blank if you want to update all available apps
$includedApps = @(

	)
$useInclusionFilter = $includedApps.Count -gt 0
Try{
Write-Output 'Detection Script started...'
	Foreach($app in $apps){
		if((-not $useInclusionFilter -or $app.PackageIdentifier -in $includedApps) -and ($app.PackageIdentifier -notin $excludedApps)){
			$versionsRaw = & $winget_exe show --versions --id $app.PackageIdentifier 2>&1
			$inVersionSection = $false
			$versionPairs = @()
				foreach($line in $versionsRaw){
					if($line -match '^Version\s*$'){
						$inVersionSection = $true
						continue
					}
					if($inVersionSection -and $line -match '^\d+(\.\d+){1,3}$'){
						$original = $line.Trim()
							try{
								$parsed = [version]$original
								$versionPairs += [PSCustomObject]@{
								Original = $original
								Parsed   = $parsed
								}
							}catch{
							# Ignore invalid version strings
							}
					}
				}
				$latest = $versionPairs | Sort-Object Parsed -Descending | Select-Object -First 1
					if($latest){
						Write-Output "$($app.PackageIdentifier): `n Latest Version:$($latest.Original) `n Current Version:$($app.Version)"
							if($latest.Original -gt $app.Version){
								Write-Output "$($app.PackageIdentifier) has an update"
								$exitCode = 1
							else{
								Write-Warning "Could not find version for $app.PackageIdentifier"
								$exitCode = 1
							}
							}else{ 
								Write-Output "No updates detecteded."
								$exitCode = 0
							}
					}else{
						Write-Warning "$($app.PackageIdentifier): No valid versions found."
						$exitCode = 0
					}
		}else{ 
            Write-Warning "$($app.PackageIdentifier) is excluded"
		}
	}
}Catch{
	$errMsg = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { "Unknown error occurred." }
	Write-Error "An error occurred: $errMsg`nFull error details: $_"
	$exitCode = 1
}Finally{
	if($exitcode -eq 1){
		Write-Output "Exit code is $($exitCode). `nUpgrades detected. `nStarting RemmediationScript..."
	}else{
		Write-Output "Exit code is $($exitCode). `nNo upgrades detected."
	}
	Stop-Transcript
	exit $exitCode
}