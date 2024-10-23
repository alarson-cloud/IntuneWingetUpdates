Start-Transcript C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\UpdateApps.log -Append
$winget_exe = Resolve-Path "C:\program files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"

$date = Get-date
    Write-Output "Searching for App Updates. $($date)"
&$winget_exe upgrade --accept-package-agreements --accept-source-agreements

$upgradeApps = &$winget_exe upgrade
$upgradeAppNames = $upgradeApps | Select-String -Pattern "^\S+" | ForEach-Object { $_.Matches.Value }
Write-Output "Apps with available updates:"
$upgradeApps
    If ($upgradeAppNames)
    {
        Write-Output "Apps found with available updates:"
        $upgradeAppNames
        Write-Output "Starting App updates" 
            &$winget_exe upgrade --all --silent --accept-package-agreements --accept-source-agreements
        Write-Output "$($upgradeAppNames) were updated"
        Write-Output "Checking for any other updates"
        $upgradeApps = &$winget_exe upgrade
        $upgradeApps
        Stop-Transcript
        Exit 0 
    } else {
    Write-Output "No available app updates found"
    $upgradeAppNames 
    Stop-Transcript
    Exit 0 
    }





