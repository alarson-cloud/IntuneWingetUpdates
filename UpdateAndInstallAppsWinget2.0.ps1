#Requires -Version 5.1
#alarson@hbs.net - 2025-03-11
Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
$InformationPreference = 'Continue'
$exitCode = 0
$log = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\AppUpdates.log"
Start-Transcript -Path $log -Append
$winget_exe = Resolve-Path "$($env:ProgramFiles)\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
$jsonFile = "$($env:windir)\temp\apps.txt"
    if ($jsonFile){ 
        Clear-Content $jsonFile
    }
&$winget_exe export -s winget -o $jsonFile --include-versions --ignore-warnings
$apps = get-content $jsonFile | ConvertFrom-Json
Set-Content $apps.Sources.Packages -Path $jsonFile
Get-Content $jsonFile | Sort-Object | Set-Content $jsonFile
$allapps = Get-Content $jsonFile
    $Apps = foreach ($line in $allapps) {
        if ($line -match 'PackageIdentifier=(.*?); Version=(.*)') {
            [PSCustomObject]@{
                PackageIdentifier = $matches[1]
                Version           = $matches[2].TrimEnd('}')
            }
        }
    }
$excludedApps = @(
        "Microsoft.Office"
        "Romanitho.Winget-AutoUpdate"
    ) 

Try{
    Foreach($app in $apps){
        if ($app.PackageIdentifier -notin $excludedApps){
            #Get Newest Version
            $versionsRaw = & $winget_exe show --versions --id $app.PackageIdentifier 2>&1
            $inVersionSection = $false
            $versionPairs = @()
                foreach ($line in $versionsRaw) {
                    if ($line -match '^Version\s*$') {
                    $inVersionSection = $true
                    continue
                    }
                    if ($inVersionSection -and $line -match '^\d+(\.\d+){1,3}$') {
                    $original = $line.Trim()
                        try {
                            $parsed = [version]$original
                            $versionPairs += [PSCustomObject]@{
                                Original = $original
                                Parsed   = $parsed
                            }
                        }   catch {
                            # Ignore invalid version strings
                            }
                    }
                }
                    $latest = $versionPairs | Sort-Object Parsed -Descending | Select-Object -First 1
                    if ($latest) {
                        Write-Output "$($app.PackageIdentifier): `n Latest Version:$($latest.Original) `n Current Version:$($app.Version)"
                            if($latest.Original -gt $app.Version) {
                                Write-Output "$($app.PackageIdentifier) has an update"
                                Write-Output "Attempting Update" 
                                &$winget_exe upgrade --id $app.PackageIdentifier --silent --accept-package-agreements --accept-source-agreements --verbose-logs
                                #Check If Upgrade worked 
                                $wingetOutput = & $winget_exe show --id $app.PackageIdentifier 2>&1
                                # Filter lines that look like version numbers
                                $versionLine = $wingetOutput | Where-Object { $_ -match '^Version:\s+(.*)$' }
                                    if ($versionLine -match '^Version:\s+(.*)$') {
                                       $line = &$winget_exe list --id $app.PackageIdentifier | Where-Object { $_ -match $app.PackageIdentifier }
                                            if ($line) {
                                                $columns = -split $line
                                                $idIndex = $columns.IndexOf($app.PackageIdentifier)
                                                    if ($idIndex -ge 0 -and $columns.Length -gt ($idIndex + 1)) {
                                                        $currentVersion = $columns[$idIndex + 1]
                                                        $currentVersion
                                                    } else {
                                                        Write-Host "Could not determine version from line: $line"
                                                        }
                                            } else {
                                                Write-Host "App not found."
                                                }
                                        Write-output "Rechecking $($app.PackageIdentifier) after update `n Version is now: $currentVersion" 
                                            if ($currentVersion -eq $latest.Original.Trim()) {
                                                Write-Output "$($app.PackageIdentifier) Updated Successfully"
                                                $exitCode = 0
                                            } else {
                                                Write-Output "Trying Install of $($app.PackageIdentifier) instead of upgrade"
                                                &$winget_exe install --id $app.PackageIdentifier --silent --accept-package-agreements --accept-source-agreements -s winget --force --verbose-logs
                                                    if($currentVersion -eq $latest.Original.Trim()) {
                                                        Write-Output "$($app.PackageIdentifier) Updated Successfully" 
                                                        $exitCode = 0
                                                    }else { 
                                                        Write-Output "$($app.PackageIdentifier) did not successfully. Exiting upgrade..." 
                                                        $exitCode = 1 
                                                    }     
                                                }   
                                    } else {
                                        Write-Warning "Could not find version for $app.PackageIdentifier"
                                        $exitCode = 1
                                        }
                             }else{ 
                                Write-Output "No updates detecteded."
                                $exitCode = 0
                            }  
                    } else {
                        Write-Warning "$($app.PackageIdentifier): No valid versions found."
                        $exitCode = 1
                    }
        } else { Write-Warning "$($app.PackageIdentifier) is excluded"
    
        }
    }
 } Catch {
        $errMsg = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { "Unknown error occurred." }
        Write-Error "An error occurred: $errMsg`nFull error details: $_"
        $exitCode = 1
    } Finally {
        Stop-Transcript
        exit $exitCode
    } 
