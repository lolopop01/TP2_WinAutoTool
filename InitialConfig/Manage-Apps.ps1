param (
    [string]$Mode,
    [switch]$Interactive,
    [string]$ConfigFilePath
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

function Is-AppInstalled {
    param (
        [string]$appName
    )

    # Check if the app is installed via Chocolatey
    $chocoInstalled = choco list --local-only | Select-String $appName
    if ($chocoInstalled) {
        return $true
    }

    # Check if the app is installed via AppX (for UWP apps)
    $appxInstalled = Get-AppxPackage -Name $appName
    if ($appxInstalled) {
        return $true
    }

    return $false
}

function Manage-App {
    param (
        [string]$appName,
        [bool]$isInstall
    )

    $isChocolateyApp = $appsToInstall -contains $appName

    if ($Interactive) {
        # Only prompt if the app is installed
        if (Is-AppInstalled -appName $appName) {
            $action = if ($isInstall) { 'installer' } else { 'désinstaller' }
            if ($isChocolateyApp) {
                $userResponse = Read-Host "Voulez-vous $action $appName via Chocolatey ? (o/n)"
                if ($userResponse -ne 'o') {
                    Write-Host "$action de $appName ignoré."
                    return $null
                }
            } else {
                $userResponse = Read-Host "Voulez-vous $action $appName via AppX ? (o/n)"
                if ($userResponse -ne 'o') {
                    Write-Host "$action de $appName ignoré."
                    return $null
                }
            }
        } else {
            Write-Host "$appName n'est pas installé, donc il ne sera pas désinstallé."
            return $null
        }
    }

    try {
        if ($isInstall) {
            Write-Host "Installation de $appName via Chocolatey..."
            choco install $appName -y
            Write-Host "$appName installé avec succès !"
            return $appName
        } else {
            if ($appName -in $appsToInstall) {
                Write-Host "Désinstallation de $appName via Chocolatey..."
                choco uninstall $appName -y
                Write-Host "$appName désinstallé avec succès !"
                return $appName
            } else {
                Write-Host "Suppression de $appName via AppX..."
                Get-AppxPackage -Name $appName | Remove-AppxPackage -ErrorAction SilentlyContinue
                Write-Host "$appName supprimé avec succès !"
                return $appName
            }
        }
    } catch {
        Write-Host "Erreur lors de l'opération sur $appName : $_"
        return $null
    }
}

$installedApps = @()
$uninstalledApps = @()

if ($Mode -eq "uninstall") {
    foreach ($appName in $appsToRemove) {
        $result = Manage-App -appName $appName -isInstall $false
        if ($result) {
            $uninstalledApps += $result
        }
    }
}

if ($Mode -eq "install") {
    foreach ($appName in $appsToInstall) {
        $result = Manage-App -appName $appName -isInstall $true
        if ($result) {
            $installedApps += $result
        }
    }
}

if ($Mode -eq "install" -and $installedApps.Count -gt 0) {
    Write-Host "Applications installées avec succès :"
    $installedApps | ForEach-Object { Write-Host $_ }
} elseif ($Mode -eq "uninstall" -and $uninstalledApps.Count -gt 0) {
    Write-Host "Applications désinstallées avec succès :"
    $uninstalledApps | ForEach-Object { Write-Host $_ }
}

Write-Host "Opération terminée."
