$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Install-WindowsUpdates.ps1"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 3:00am
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$taskName = "WinAutoTool-UpdateCheck"

# Check if the scheduled task already exists
$existingTask = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }

if ($existingTask) {
    Write-Host "La tâche planifiée '$taskName' existe déjà. Mise à jour de la tâche..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName -Description "Exécute le module de mise à jour de WinAutoTool chaque semaine."
} else {
    Write-Host "La tâche planifiée '$taskName' n'a pas été trouvée. Enregistrement de la tâche..."
    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName -Description "Exécute le module de mise à jour de WinAutoTool chaque semaine."
}
