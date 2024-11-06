$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Install-WindowsUpdates.ps1"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 3:00am
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "WinAutoTool-UpdateCheck" -Description "Exécute le module de mise à jour de WinAutoTool chaque semaine."
