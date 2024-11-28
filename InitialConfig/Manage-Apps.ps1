param (
    [string]$Mode,
    [bool]$Interactive,
    [string]$ConfigFilePath,
    [switch]$ListInstalled
)

if (-Not (Test-Path $ConfigFilePath)) {
    Write-Host "Configuration file not found: $ConfigFilePath"
    return
}

$config = Get-Content $ConfigFilePath | ConvertFrom-Json
$appsToRemove = $config.appsToRemove
$appsToInstall = $config.appsToInstall

function Is-AppInstalled {
    param (
        [string]$appName
    )
    if (choco list --local-only | Select-String $appName) {
        return $true
    }
    return $false
}

function Log-Error {
    param ([string]$message)
    if (-not [System.Diagnostics.EventLog]::SourceExists("AppManager")) {
        New-EventLog -LogName Application -Source "AppManager"
    }
    Write-EventLog -LogName Application -Source "AppManager" -EventId 1 -EntryType Error -Message $message
}

function Install-App {
    param ([string]$appName)
    try {
        Write-Host "Installing $appName..."
        choco install $appName -y
        Write-Host "$appName installed."
    } catch { Log-Error $_.Exception.Message }
}

function Uninstall-App {
    param ([string]$appName)
    try {
        Write-Host "Uninstalling $appName..."
        choco uninstall $appName -y
        Write-Host "$appName uninstalled."
    } catch { Log-Error $_.Exception.Message }
}

function Manage-App {
    param ([string]$appName, [bool]$isInstall)
    if ($isInstall) {
        if (-Not (Is-AppInstalled -appName $appName)) {
            Install-App $appName
        } else { Write-Host "$appName is already installed." }
    } else {
        if (Is-AppInstalled -appName $appName) {
            Uninstall-App $appName
        } else { Write-Host "$appName is not installed." }
    }
}

function InteractiveMode {
    param ([string[]]$appList, [bool]$isInstall)
    $index = 0
    while ($true) {
        cls
        Write-Host "Use arrow keys to navigate. Press Enter to toggle. Press 'q' to finish."

        for ($i = 0; $i -lt $appList.Count; $i++) {
            if ($i -eq $index) {
                Write-Host "> $($appList[$i])" -ForegroundColor Cyan
            } else {
                Write-Host "  $($appList[$i])"
            }
        }

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { $index = ($index - 1 + $appList.Count) % $appList.Count }
            40 { $index = ($index + 1) % $appList.Count }
            13 { Manage-App $appList[$index] -isInstall $isInstall }
            81 { return }
        }
    }
}

function List-InstalledApps {
    Write-Host "Installed apps:"
    choco list --local-only
}

if ($ListInstalled) {
    List-InstalledApps
} elseif ($Mode -eq "install") {
    if ($Interactive) {
        InteractiveMode $appsToInstall -isInstall $true
    }
    else {
        $appsToInstall | ForEach-Object { Manage-App $_ -isInstall $true }
    }
} elseif ($Mode -eq "uninstall") {
    if ($Interactive) {
        InteractiveMode $appsToRemove -isInstall $false
    }
    else {
        $appsToRemove | ForEach-Object { Manage-App $_ -isInstall $false }
    }
} else {
    Write-Host "Invalid mode. Use 'install' or 'uninstall'."
}

Write-Host "Operation completed."
