Start-Transcript -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\CreateAppUpdatesTask.log -Append

# Define the source item and destination folder
$sourceItem = "AppUpdates2.0.ps1"
$destinationFolder = "C:\hbs\scripts"
$date = get-date 
$date 
# Check if the destination folder exists, if not, create it
Write-Output "Checking if $($destinationFolder) exists." 
if (-not (Test-Path -Path $destinationFolder)) {
    
    New-Item -Path $destinationFolder -ItemType Directory -Force
    Write-Host "Created folder: $destinationFolder"
}else {Write-Output "$($destinationFolder) Exists already. Copying file now."} 

# Copy the item to the destination folder
Copy-Item -Path $sourceItem -Destination $destinationFolder -Force

Write-Output "$($sourceItem) copied to $($destinationFolder)"
$fullFilePath = $destinationFolder+"\"+$sourceItem

$taskExists = Get-ScheduledTask -TaskName WeeklyWingetUpdateCheck

if ($taskExists.TaskName -ne "WeeklyWingetUpdateCheck"){ 
        # Define the action - Replace script or program path as needed
        $action = New-ScheduledTaskAction -Execute powershell.exe  -Argument "-executionpolicy bypass -file $($fullFilePath)"

        # Define the trigger - Set it to run weekly at 10:00 AM every Monday (customize as needed)
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 10:00AM

        # Define the principal - Run the task as SYSTEM
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        # Define the settings - Customize as needed
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -StartWhenAvailable -WakeToRun -DontStopIfGoingOnBatteries 

        # Register the task
        Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName "WeeklyWingetUpdateCheck" -Description "This is a weekly scheduled task running as SYSTEM."
        $taskExistsNow = Get-ScheduledTask -TaskName WeeklyWingetUpdateCheck
        if($taskExistsNow.TaskName -eq "WeeklyWingetUpdateCheck"){Write-Output "Scheduled task created successfully."
        Stop-Transcript 
        exit 0 
        }else {Write-Output "Scheduled task was not created."
                $errMsg = $_.Exception.Message
                Write-Error $errMsg
                Stop-Transcript
                Exit 1 
        
         }  

    }else {Write-Output "$taskExistsNow.TaskName already exists. Exiting..."
            Stop-Transcript
            Exit 0 
     }  
