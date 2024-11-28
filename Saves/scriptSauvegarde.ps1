# Check if the event source exists, and create it if not
$logSource = "SauvegardeScript"
$logName = "Application"

# Check if the event source exists in the registry
$eventSourceRegistryKey = "HKLM:\System\CurrentControlSet\Services\EventLog\$logName\$logSource"

if (-not (Test-Path -Path $eventSourceRegistryKey)) {
    # Register the event source if it doesn't exist
    try {
        New-EventLog -LogName $logName -Source $logSource
        Write-Host "Event source '$logSource' has been created."
    } catch {
        Write-Host "Error creating event source: $_"
    }
} else {
    Write-Host "Event source '$logSource' already exists."
}


# Configuration
$sourceFolder = Resolve-Path -Path "DocumentsImportants"
$backupFolder = "C:\Users\$env:USERNAME\OneDrive\Backup"
$minimumFreeSpaceGB = 10

# Function to check available free space on the drive
function Get-FreeSpace {
    param([string]$path)
    $drive = Get-PSDrive -PSProvider FileSystem | Where-Object { $path.StartsWith($_.Root) }
    return [math]::Floor($drive.Free / 1GB)
}

# Check if there is enough free space on OneDrive
$freeSpace = Get-FreeSpace -path $backupFolder
if ($freeSpace -lt $minimumFreeSpaceGB) {
    Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId 1001 -Message "Espace disque insuffisant pour la sauvegarde. Disponible : ${freeSpace}GB."
    exit 1
}

# Create the backup folder in OneDrive if it does not exist
if (-not (Test-Path -Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
}

# Create a dated folder to hold the backup zip
$backupDateFolder = Join-Path $backupFolder (Get-Date -Format "yyyyMMdd_HHmmss")
New-Item -ItemType Directory -Path $backupDateFolder | Out-Null

# Perform the backup (copying files)
try {
    # Copy files from source folder to the backup date folder
    Copy-Item -Path "$sourceFolder\*" -Destination $backupDateFolder -Recurse -Force

    # Now, zip the files
    $zipFileName = "$backupDateFolder.zip"
    Compress-Archive -Path "$backupDateFolder\*" -DestinationPath $zipFileName

    # After zipping, remove the unzipped files (optional)
    Remove-Item -Path $backupDateFolder -Recurse -Force

    # Log the success of the backup
    Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId 1000 -Message "Sauvegarde réussie. Les fichiers ont été copiés et zippés dans $zipFileName."
} catch {
    Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId 1002 -Message "Erreur lors de la sauvegarde : $_"
    exit 1
}
