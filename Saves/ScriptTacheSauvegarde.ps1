# Configuration
$taskName = "SauvegardeAutomatique"
$scriptPath = "C:\Chemin\Vers\Sauvegarde.ps1"  # Chemin du script de sauvegarde
$executionTime = "02:00AM"  # Heure d'exécution quotidienne

# Vérification que le script de sauvegarde existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Host "Erreur : Le script de sauvegarde $scriptPath n'existe pas. Veuillez vérifier le chemin."
    exit 1
}

# Définir le déclencheur pour exécution quotidienne
$trigger = New-ScheduledTaskTrigger -Daily -At $executionTime

# Définir l'action pour exécuter le script PowerShell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$scriptPath`""

# Définir le compte utilisateur pour exécuter la tâche
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount

# Configurer les paramètres de la tâche
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Enregistrer la tâche planifiée
try {
    Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Principal $principal -Settings $settings -Force
    Write-Host "Tâche planifiée '$taskName' créée avec succès pour exécuter $scriptPath à $executionTime."
} catch {
    Write-Host "Erreur lors de la création de la tâche planifiée : $_"
    exit 1
}
