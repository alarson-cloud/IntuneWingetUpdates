Deploy as an App or Remediation script with these scripts. App already packaged and ready to upload as Win32. App version is currently set to run as a task scheduler task on Monday morning at 10 AM CST and run weekly. 

Edit the $trigger to change the time/frequency of running this scheduled task in the AppUpdatesTaskScheduler.ps1 and re-package as Win32. 

Logs output to C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\UpdateApps.log after running and attempting app updates in either version. 

![image](https://github.com/user-attachments/assets/b9b327a9-1e54-454e-bca5-6839217ca5f4)
![image](https://github.com/user-attachments/assets/4b62bf9a-1b0f-4a20-bc14-cf59d9cba898)
