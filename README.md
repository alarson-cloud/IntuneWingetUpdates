Keep Microsoft and 3rd party apps up to date with Winget.
Deploy as a Remediation script with this script in Microsoft Intune.

Exclude Apps that you don't want upgraded in the $excludedApps list with the app's ID

Include only certain apps you want upgraded in the $includedApps list. Leaving the list blank will upgrade all available Winget apps except for the excluded apps list.
Find the App ID by running winget search *appname* in PowerShell 

Logs output to C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppUpdates.log after running and attempting app updates in any version. 

Log snip looks like this: 
![image](https://github.com/user-attachments/assets/7020d750-bc25-46ae-af79-260fc53a4d24)


