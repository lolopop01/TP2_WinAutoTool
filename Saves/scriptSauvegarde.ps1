New-EventLog -LogName "Application" -Source "SauvegardeScript"
# Configuration
$sourceFolder = "C:\Chemin\Vers\Documents\Critiques"
$backupFolder = "\\ServeurRéseau\Emplacement\Sauvegarde"
$minimumFreeSpaceGB = 10
$logName = "Application"

# Vérification de l'espace disque disponible
function Get-FreeSpace {
    param([string]$path)
    $drive = Get-PSDrive -PSProvider FileSystem | Where-Object { $path.StartsWith($_.Root) }
    return [math]::Floor($drive.Free / 1GB)
}

# Vérification de l'espace disque
$freeSpace = Get-FreeSpace -path $backupFolder
if ($freeSpace -lt $minimumFreeSpaceGB) {
    Write-EventLog -LogName $logName -Source "SauvegardeScript" -EntryType Error -EventId 1001 -Message "Espace disque insuffisant pour la sauvegarde. Disponible : ${freeSpace}GB."
    exit 1
}

# Création du dossier de sauvegarde si nécessaire
if (-not (Test-Path -Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
}

# Copie des fichiers
try {
    Copy-Item -Path "$sourceFolder\*" -Destination $backupFolder -Recurse -Force
    Write-EventLog -LogName $logName -Source "SauvegardeScript" -EntryType Information -EventId 1000 -Message "Sauvegarde réussie. Les fichiers ont été copiés de $sourceFolder vers $backupFolder."
} catch {
    Write-EventLog -LogName $logName -Source "SauvegardeScript" -EntryType Error -EventId 1002 -Message "Erreur lors de la sauvegarde : $_"
    exit 1
}
