$wingettask = Get-ScheduledTask -TaskName "WeeklyWingetUpdateCheck"
try
{
    if (($wingettask.TaskName -eq "WeeklyWingetUpdateCheck")){
        Write-Output "$($wingettask.TaskName) is added successfully to the computer."
        Exit 0
}
    else{
        #Module Already installed
        Write-Output "$($wingettask.TaskName) is not detected on this computer."  
        Exit 1  
    }
 }  catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    Exit 1 
}