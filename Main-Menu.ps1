[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Menu {
    $menuOptions = @(
        "1. Exécuter le Gestionnaire de tâches (TaskManager/Task-Manager.ps1)",
        "2. Exécuter le script de sauvegarde (Saves/scriptSauvegarde.ps1)",
        "3. Exécuter le script de tâche de sauvegarde (Saves/ScriptTacheSauvegarde.ps1)",
        "4. Exécuter la configuration initiale (InitialConfig/Initial_Config.ps1)",
        "5. Exécuter les mises à jour (Updates/Install-WindowsUpdates.ps1)",
        "6. Exécuter la configuration de la tâche de mise à jour planifiée (Updates/Setup-ScheduledUpdateTask.ps1)",
        "7. Quitter"
    )

    # Display the menu options
    $menuOptions | ForEach-Object { Write-Host $_ }
}

function Run-Script {
    param(
        [string]$scriptPath
    )

    if (Test-Path $scriptPath) {
        Write-Host "Exécution de $scriptPath..."
        & $scriptPath
    } else {
        Write-Host "Script introuvable : $scriptPath"
    }
}

# Main loop to display menu and execute scripts
do {
    Clear-Host
    Show-Menu
    $selection = Read-Host "Veuillez sélectionner une option (1-7)"

    switch ($selection) {
        "1" {
            Run-Script -scriptPath ".\TaskManager\Task-Manager.ps1"
        }
        "2" {
            Run-Script -scriptPath ".\Saves\scriptSauvegarde.ps1"
        }
        "3" {
            Run-Script -scriptPath ".\Saves\ScriptTacheSauvegarde.ps1"
        }
        "4" {
            Run-Script -scriptPath ".\InitialConfig\Initial_Config.ps1"
        }
        "5" {
            Run-Script -scriptPath ".\Updates\Install-WindowsUpdates.ps1"
        }
        "6" {
            Run-Script -scriptPath ".\Updates\Setup-ScheduledUpdateTask.ps1"
        }
        "7" {
            Write-Host "Sortie..."
            break
        }
        default {
            Write-Host "Sélection invalide, veuillez choisir une option valide."
        }
    }

    # Pause for user to read any output before clearing
    if ($selection -ne "7") {
        Write-Host "Appuyez sur n'importe quelle touche pour revenir au menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} while ($selection -ne "7")
