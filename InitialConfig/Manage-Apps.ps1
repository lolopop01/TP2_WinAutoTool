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
        Write-Host "Config file is missing." -ForegroundColor Red
        Write-EventLog -LogName Application -Source "AppManager" -EventId 2 -EntryType Error -Message "Config file missing."
        return $null
    }
    return Get-Content $ConfigFilePath | ConvertFrom-Json
}

function Is-AppInstalled {
    param ([string]$appName)
    $installedApp = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*$appName*" }
    if (-not $installedApp) {
        $installedApp = Get-AppxPackage -Name "*$appName*" -ErrorAction SilentlyContinue
    }
    return $installedApp
}

function Manage-App {
    param ([string]$appName, [bool]$isInstall)

    if ($isInstall) {
        Write-Host "Processing installation of $appName..." -ForegroundColor Yellow
        Write-EventLog -LogName Application -Source "AppManager" -EventId 6 -EntryType Information -Message "Attempting to install $appName."
        Start-Process -FilePath "choco" -ArgumentList "install $appName -y --no-progress" -NoNewWindow -Wait
        Write-Host "$appName installed successfully." -ForegroundColor Green
        Write-EventLog -LogName Application -Source "AppManager" -EventId 7 -EntryType Information -Message "$appName installed."
    } else {
        Write-Host "Processing uninstallation of $appName..." -ForegroundColor Yellow
        Write-EventLog -LogName Application -Source "AppManager" -EventId 10 -EntryType Information -Message "Attempting to uninstall $appName."
        $installedApp = Is-AppInstalled $appName
        if ($installedApp) {
            if ($installedApp -is [System.Management.ManagementObject]) {
                $uninstallString = $installedApp.UninstallString
                if ($uninstallString) {
                    Start-Process -FilePath $uninstallString -ArgumentList "/quiet /norestart" -NoNewWindow -Wait
                    Write-Host "$appName uninstalled successfully." -ForegroundColor Green
                    Write-EventLog -LogName Application -Source "AppManager" -EventId 11 -EntryType Information -Message "$appName uninstalled."
                } else {
                    Write-Host "No uninstall string found for $appName." -ForegroundColor Red
                    Write-EventLog -LogName Application -Source "AppManager" -EventId 12 -EntryType Warning -Message "No uninstall string found for $appName."
                }
            } elseif ($installedApp -is [System.Management.Automation.PSObject]) {
                Remove-AppxPackage -Package $installedApp.PackageFullName -ErrorAction SilentlyContinue
                Write-Host "$appName uninstalled successfully." -ForegroundColor Green
                Write-EventLog -LogName Application -Source "AppManager" -EventId 11 -EntryType Information -Message "$appName uninstalled."
            }
        } else {
            Write-Host "$appName is not installed." -ForegroundColor Cyan
            Write-EventLog -LogName Application -Source "AppManager" -EventId 13 -EntryType Information -Message "$appName is not installed."
        }
    }
}

function InteractiveMode {
    param ([string[]]$appList, [bool]$isInstall)
    $index = 0
    cls
    while ($true) {
        $Host.UI.RawUI.CursorPosition = @{X=0; Y=0}
        Write-Host "Navigate with Up/Down Arrow, Select with Enter, Exit with 'Q'"
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
    $installedApps = Get-CimInstance -ClassName Win32_Product | Select-Object Name, Version, Vendor
    Write-Host "Installed Applications:" -ForegroundColor Green
    $installedApps | Format-Table -AutoSize
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
    Write-Host "Invalid mode specified." -ForegroundColor Red
    Write-EventLog -LogName Application -Source "AppManager" -EventId 21 -EntryType Error -Message "Invalid mode."
    exit 1
}

Write-Host "Operation completed." -ForegroundColor Green
Write-EventLog -LogName Application -Source "AppManager" -EventId 22 -EntryType Information -Message "Operation completed."
