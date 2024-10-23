Start-Transcript C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\UpdateApps.log -Append
Write-Output "Starting Update Detection script..."
$winget_exe = Resolve-Path "C:\program files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"

$date = Get-date
Write-Output "Searching for App Updates. $($date)"
&$winget_exe upgrade --accept-package-agreements --accept-source-agreements

$upgradeApps = &$winget_exe upgrade
$upgradeAppNames = $upgradeApps | Select-String -Pattern "^\S+" | ForEach-Object { $_.Matches.Value }
$upgradeApps
    If ($upgradeAppNames)
    {
        Write-Output "Apps found with available updates:"
        Write-Output " Starting Remediation...." 

        $upgradeAppNames

        Stop-Transcript
        Exit 1
         
    } else {
    Write-Output "No available app updates found"
    $upgradeAppNames 
    Stop-Transcript
    Exit 0 
    
    }