# Relative path to the MonitorPerformance.ps1 script
$scriptPath = "..\Performance\Monitor-Perf.ps1"

# Open a new PowerShell window and run the script
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File $scriptPath"


function Change-Background() {
    param (
        [string]$Path = ".\InitialConfig\Deep_Lilypads_Biome.jpg"
    )

    $Data = @{
        WallpaperURL              = $Path
        LockscreenURL             = $Path
        DownloadDirectory         = "C:\temp"
        RegKeyPath                = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
        StatusValue               = "1"
    }

    $WallpaperDest  = $($Data.DownloadDirectory + "\Wallpaper." + ($Data.WallpaperURL -replace ".*\."))
    $LockscreenDest = $($Data.DownloadDirectory + "\Lockscreen." + ($Data.LockscreenUrl -replace ".*\."))

    New-Item -ItemType Directory -Path $Data.DownloadDirectory -ErrorAction SilentlyContinue
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

function Manage-Apps {
    $actionChoice = Read-Host "Voulez-vous (1) Désinstaller ou (2) Installer des applications ? (Entrez 1 ou 2)"
    $modeChoice = Read-Host "Choisissez le mode : (1) Automatique ou (2) Interactif (Entrez 1 ou 2)"

    $mode = if ($actionChoice -eq "1") { "uninstall" } elseif ($actionChoice -eq "2") { "install" } else { "invalid" }
    $interactive = if ($modeChoice -eq "1") { $false } elseif ($modeChoice -eq "2") { $true } else { $false }

    if ($mode -eq "invalid") {
        Write-Host "Choix invalide. Veuillez choisir 1 ou 2 pour l'action."
        return
    }
    
    $ConfigFilePath = Resolve-Path ".\InitialConfig\config.json"
    if (-Not (Test-Path $ConfigFilePath)) {
        $errorMessage = "Le fichier de configuration n'a pas été trouvé. Veuillez vérifier le chemin."
        Write-Host $errorMessage
        Log-ErrorToEventViewer -Message $errorMessage
        return
    }

    .\InitialConfig\Manage-Apps.ps1 -Mode $mode -Interactive $interactive -ConfigFilePath $ConfigFilePath
}

function Show-Menu {
    $ConfigFilePath = Resolve-Path ".\InitialConfig\config.json"

    while ($true) {
        
        Write-Host "Choisissez une option:"
        Write-Host "1. Changer le fond d'écran"
        Write-Host "2. Supprimer la barre de recherche"
        Write-Host "3. Gérer les applications"
        Write-Host "4. Quitter"

        $choice = Read-Host "Entrez votre choix"

        switch ($choice) {
            1 {
                Change-Background
            }
            2 {
                Remove-SearchBar
            }
            3 {
                Manage-Apps
            }
            4 {
                Exit
            }
            default {
                Write-Host "Choix non valide, veuillez réessayer."
            }
        }

        # If user chose to quit, the script will exit the loop
        if ($choice -eq 4) {
            break
        }
    }
}


Show-Menu
