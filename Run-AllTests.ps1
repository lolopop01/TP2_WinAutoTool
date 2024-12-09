function Ensure-Pester {
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Host "Pester n'est pas installé. Installation de Pester..." -ForegroundColor Yellow
        Install-Module -Name Pester -Scope CurrentUser -Force
    } else {
        Write-Host "Pester est déjà installé." -ForegroundColor Green
    }
}

Ensure-Pester

$testsFolder = "$PSScriptRoot\Tests"

if (-not (Test-Path -Path $testsFolder)) {
    Write-Host "Le dossier Tests n'existe pas. Veuillez vérifier le chemin : $testsFolder" -ForegroundColor Red
    exit 1
}

$testFiles = Get-ChildItem -Path $testsFolder -Filter "*.Tests.ps1" -File

if ($testFiles.Count -eq 0) {
    Write-Host "Aucun fichier de test trouvé dans le dossier Tests." -ForegroundColor Yellow
    exit 1
}

foreach ($testFile in $testFiles) {
    Write-Host "Exécution des tests dans le fichier : $($testFile.FullName)" -ForegroundColor Cyan
    try {
        Invoke-Pester -Path $testFile.FullName -Output Detailed
    } catch {
        Write-Host "Erreur lors de l'exécution des tests dans le fichier $($testFile.Name) : $_" -ForegroundColor Red
    }
}

Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
