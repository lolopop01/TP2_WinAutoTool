param (
    [string]$Mode = "install",
    [switch]$Interactive,
    [string]$ConfigFilePath = ".\config.json"
)

function Install-Chocolatey {
    Write-Host "Chocolatey n'est pas installé. Installation en cours..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installé avec succès !"
}

if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Install-Chocolatey
} else {
    Write-Host "Chocolatey est déjà installé."
}

if (-Not (Test-Path $ConfigFilePath)) {
    Write-Host "Fichier de configuration introuvable à : $ConfigFilePath"
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    Get-ChildItem -Path $scriptDir

    return
}

$config = Get-Content $ConfigFilePath | ConvertFrom-Json
$appsToRemove = $config.appsToRemove
$appsToInstall = $config.appsToInstall

if ($Mode -eq "install") {
    Write-Host "Installation des applications..."
} elseif ($Mode -eq "uninstall") {
    Write-Host "Suppression des applications..."
} else {
    Write-Host "Mode invalide spécifié. Utilisez 'install' ou 'uninstall'."
    return
}

function Manage-App {
    param (
        [string]$appName,
        [bool]$isInstall
    )

    if ($Interactive) {
        $action = if ($isInstall) { 'installer' } else { 'désinstaller' }
        $userResponse = Read-Host "Voulez-vous $action $appName via Chocolatey ? (o/n)"
        if ($userResponse -ne 'o') {
            Write-Host "$action de $appName ignoré."
            return
        }
    }

    try {
        if ($isInstall) {
            Write-Host "Installation de $appName via Chocolatey..."
            choco install $appName -y
            Write-Host "$appName installé avec succès !"
        } else {
            if ($appName -in $appsToInstall) {
                Write-Host "Désinstallation de $appName via Chocolatey..."
                choco uninstall $appName -y
                Write-Host "$appName désinstallé avec succès !"
            } else {
                Write-Host "Suppression de $appName via AppX..."
                Get-AppxPackage -Name $appName | Remove-AppxPackage -ErrorAction SilentlyContinue
                Write-Host "$appName supprimé avec succès !"
            }
        }
    } catch {
        Write-Host "Erreur lors de l'opération sur $appName : $_"
    }
}

if ($Mode -eq "uninstall") {
    foreach ($appName in $appsToRemove) {
        Manage-App -appName $appName -isInstall $false
    }
}

if ($Mode -eq "install") {
    foreach ($appName in $appsToInstall) {
        Manage-App -appName $appName -isInstall $true
    }
}

Write-Host "Opération terminée."
