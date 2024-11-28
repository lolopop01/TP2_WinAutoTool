param (
    [string]$Mode,
    [bool]$Interactive,
    [string]$ConfigFilePath,
    [switch]$ListInstalled
)

function Create-LogSource {
    if (-not [System.Diagnostics.EventLog]::SourceExists("AppManager")) {
        New-EventLog -LogName Application -Source "AppManager"
    }
}

function Get-Config {
    if (-not (Test-Path $ConfigFilePath)) {
        Write-EventLog -LogName Application -Source "AppManager" -EventId 2 -EntryType Error -Message "Config file missing."
        return $null
    }
    return Get-Content $ConfigFilePath | ConvertFrom-Json
}

function Is-AppInstalled {
    param ([string]$appName)
    $software = (Get-ItemProperty -Path "HKLM:\SOFTWARE\*\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue)
    $software += (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue)
    return $software | Where-Object { $_.DisplayName -like "*$appName*" }
}

function Manage-App {
    param ([string]$appName, [bool]$isInstall)

    if ($isInstall) {
        Write-EventLog -LogName Application -Source "AppManager" -EventId 6 -EntryType Information -Message "Attempting to install $appName."

        if (-not (Is-AppInstalled $appName)) {
            choco install $appName -y
            Write-EventLog -LogName Application -Source "AppManager" -EventId 7 -EntryType Information -Message "$appName installed."
        } else {
            Write-EventLog -LogName Application -Source "AppManager" -EventId 9 -EntryType Information -Message "$appName is already installed."
        }
    } else {
        Write-EventLog -LogName Application -Source "AppManager" -EventId 10 -EntryType Information -Message "Attempting to uninstall $appName."

        if (Is-AppInstalled $appName) {
            $uninstallString = (Get-ItemProperty -Path "HKLM:\SOFTWARE\*\Microsoft\Windows\CurrentVersion\Uninstall\$appName" -ErrorAction SilentlyContinue).UninstallString
            if ($uninstallString) {
                Start-Process -FilePath $uninstallString -ArgumentList "/quiet /norestart" -Wait
                Write-EventLog -LogName Application -Source "AppManager" -EventId 11 -EntryType Information -Message "$appName uninstalled."
            } else {
                Write-EventLog -LogName Application -Source "AppManager" -EventId 12 -EntryType Warning -Message "No uninstall string found for $appName."
            }
        } else {
            Write-EventLog -LogName Application -Source "AppManager" -EventId 13 -EntryType Information -Message "$appName is not installed."
        }
    }
    cls
}


function InteractiveMode {
    param ([string[]]$appList, [bool]$isInstall)
    $index = 0
    cls
    while ($true) {
        $Host.UI.RawUI.CursorPosition = @{X=0; Y=0}
        $appList | ForEach-Object { if ($_ -eq $appList[$index]) { Write-Host "> $_" -ForegroundColor Cyan } else { Write-Host "  $_" } }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
        switch ($key) {
            38 { $index = ($index - 1 + $appList.Count) % $appList.Count }
            40 { $index = ($index + 1) % $appList.Count }
            13 { Manage-App $appList[$index] $isInstall }
            81 { return }
        }
    }
}

function List-InstalledApps {
    Get-ItemProperty -Path "HKLM:\SOFTWARE\*\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Select-Object DisplayName, DisplayVersion, Publisher
}

Create-LogSource
$config = Get-Config
if (-not $config) { return }

$appsToRemove = $config.appsToRemove
$appsToInstall = $config.appsToInstall

if ($ListInstalled) {
    List-InstalledApps
} elseif ($Mode -eq "install") {
    if ($Interactive) { InteractiveMode $appsToInstall $true }
    else { $appsToInstall | ForEach-Object { Manage-App $_ $true } }
} elseif ($Mode -eq "uninstall") {
    if ($Interactive) { InteractiveMode $appsToRemove $false }
    else { $appsToRemove | ForEach-Object { Manage-App $_ $false } }
} else {
    Write-EventLog -LogName Application -Source "AppManager" -EventId 21 -EntryType Error -Message "Invalid mode."
    exit 1
}

Write-EventLog -LogName Application -Source "AppManager" -EventId 22 -EntryType Information -Message "Operation completed."
