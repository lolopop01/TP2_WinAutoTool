Write-Host "Surveillance des performances système en cours... (Appuyez sur CTRL+C pour arrêter)" -ForegroundColor Green

$performanceData = @()

while ($true) {
    # Récupérer les informations sur l'utilisation du CPU
    $cpuUsage = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average

    # Récupérer les informations sur la RAM
    $memoryInfo = Get-WmiObject Win32_OperatingSystem
    $totalMemory = [math]::Round($memoryInfo.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($memoryInfo.FreePhysicalMemory / 1MB, 2)
    $usedMemory = $totalMemory - $freeMemory

    # Récupérer les informations sur l'utilisation du réseau
    $networkUsage = Get-Counter '\Network Interface(*)\Bytes Total/sec' | Select-Object -ExpandProperty CounterSamples
    $networkDetails = $networkUsage | ForEach-Object {
        "$($_.InstanceName) : $([math]::Round($_.CookedValue / 1KB, 2)) KB/s"
    }

    # Ajouter les données actuelles à la liste
    $timestamp = Get-Date -Format "HH:mm:ss"
    $currentData = @{
        Timestamp = $timestamp
        CPU       = "$cpuUsage%"
        RAM       = "$usedMemory MB / $totalMemory MB"
        Network   = $networkDetails -join ", "
    }
    $performanceData += $currentData

    Clear-Host
    Write-Host "Surveillance des performances système :"
    $performanceData | ForEach-Object {
        Write-Host "$($_.Timestamp) | CPU : $($_.CPU) | RAM : $($_.RAM) | Réseau : $($_.Network)"
        Write-Host ""
    }

    Start-Sleep -Seconds 2
}
