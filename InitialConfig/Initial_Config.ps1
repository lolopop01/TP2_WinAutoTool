function Change-Background() {
    param (
        [string]$Path = "Deep_Lilypads_Biome.jpg"  # Optional argument with default value
    )

    $Data = @{
        WallpaperURL              = $Path
        LockscreenURL             = $Path
        DownloadDirectory         = "C:\temp"
        RegKeyPath                = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP' # Assigns the wallpaper
        StatusValue               = "1"
    }

    $WallpaperDest  = $($Data.DownloadDirectory + "\Wallpaper." + ($Data.WallpaperURL -replace ".*\."))
    $LockscreenDest = $($Data.DownloadDirectory + "\Lockscreen." + ($Data.LockscreenUrl -replace ".*\."))

    # Creates the destination folder on the target computer
    New-Item -ItemType Directory -Path $Data.DownloadDirectory -ErrorAction SilentlyContinue

    # Downloads the image file from the source location
    Start-BitsTransfer -Source $Data.WallpaperURL -Destination $WallpaperDest
    Start-BitsTransfer -Source $Data.LockscreenUrl -Destination $LockscreenDest

    New-Item -Path $Data.RegKeyPath -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $Data.RegKeyPath -Name 'DesktopImageStatus' -Value $Data.Statusvalue -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $Data.RegKeyPath -Name 'LockScreenImageStatus' -Value $Data.Statusvalue -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $Data.RegKeyPath -Name 'DesktopImagePath' -Value $WallpaperDest -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $Data.RegKeyPath -Name 'DesktopImageUrl' -Value $WallpaperDest -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $Data.RegKeyPath -Name 'LockScreenImagePath' -Value $LockscreenDest -PropertyType STRING -Force | Out-Null
    New-ItemProperty -Path $Data.RegKeyPath -Name 'LockScreenImageUrl' -Value $LockscreenDest -PropertyType STRING -Force | Out-Null
}

function Remove-SearchBar {
    $settings = [PSCustomObject]@{
        Path  = "Software\Microsoft\Windows\CurrentVersion\Search"
        Value = 0
        Name  = "SearchboxTaskbarMode"
    } | group Path

    foreach ($setting in $settings) {
        $registry = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($setting.Name, $true)
        if ($null -eq $registry) {
            $registry = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($setting.Name, $true)
        }
        $setting.Group | % {
            if (!$_.Type) {
                $registry.SetValue($_.name, $_.value)
            }
            else {
                $registry.SetValue($_.name, $_.value, $_.type)
            }
        }
        $registry.Dispose()
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "Choisissez une option:"
    Write-Host "1. Changer le fond d'écran"
    Write-Host "2. Supprimer la barre de recherche"
    Write-Host "3. Enlever du bloatware"
    Write-Host "4. Ajouter du bloatware"
    Write-Host "5. Quitter"

    $choice = Read-Host "Entrez votre choix"

    switch ($choice) {
        1 { Change-Background }
        2 { Remove-SearchBar }
        3 { Remove-Bloat }
        4 { Add-Bloat }
        5 { Exit }
        default { Write-Host "Choix non valide, veuillez réessayer." }
    }
}

function Remove-Bloat {
    param (
        [string]$ConfigFilePath = "config.json"  # Chemin du fichier de configuration JSON
    )

    # Vérifie si le fichier de configuration existe
    if (-Not (Test-Path $ConfigFilePath)) {
        Write-Host "Fichier de configuration non trouvé à: $ConfigFilePath"
        return
    }

    # Lit le fichier JSON et récupère la liste des applications
    $config = Get-Content $ConfigFilePath | ConvertFrom-Json
    $appsToRemove = $config.appsToRemove

    # Parcourt chaque application listée dans le fichier de configuration
    foreach ($app in $appsToRemove) {
        $appName = $app.Trim()

        # Recherche et récupère l'application correspondante pour tous les utilisateurs
        $appPackage = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*$appName*" }

        if ($appPackage) {
            # Assurez-vous de prendre le premier résultat si plusieurs sont trouvés
            $packageFullName = $appPackage.PackageFullName | Select-Object -First 1

            Write-Host "Suppression de l'application: $appName"
            try {
                Remove-AppxPackage -Package $packageFullName -ErrorAction Stop
            } catch {
                Write-Host "Erreur lors de la suppression de l'application: $appName. Message d'erreur: $_"
            }
        } else {
            Write-Host "Application non trouvée: $appName"4
        }
    }
}

function Add-Bloat {
    param (
        [string]$ConfigFilePath = "config.json",
        [switch]$InteractiveMode
    )

    function Install-Chocolatey {
        Write-Host "Chocolatey n'est pas installé. Installation en cours..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Chocolatey a été installé avec succès!"
    }

    # Vérifie si Chocolatey est installé
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Install-Chocolatey
    } else {
        Write-Host "Chocolatey est déjà installé."
    }

    # Vérifie si le fichier de configuration existe
    if (-Not (Test-Path $ConfigFilePath)) {
        Write-Host "Fichier de configuration non trouvé à: $ConfigFilePath"
        return
    }

    # Lit le fichier JSON et récupère la liste des applications
    $config = Get-Content $ConfigFilePath | ConvertFrom-Json
    $appsToInstall = $config.appsToInstall

    # Parcourt chaque application listée dans le fichier de configuration
    foreach ($app in $appsToInstall) {
        $appName = $app.name.Trim()

        Write-Host "Préparation de l'installation pour: $appName"

        if ($InteractiveMode) {
            $userResponse = Read-Host "Voulez-vous installer $appName via Chocolatey? (o/n)"
            if ($userResponse -ne 'o') {
                Write-Host "Installation de $appName annulée."
                continue
            }
        }

        try {
            # Installe l'application via Chocolatey
            Write-Host "Installation de $appName via Chocolatey..."
            choco install $appName -y

            Write-Host "$appName installé avec succès!"
        } catch {
            Write-Host "Erreur lors de l'installation de $appName. Message d'erreur: $_"
        }
    }
}

# Display the menu
Show-Menu

