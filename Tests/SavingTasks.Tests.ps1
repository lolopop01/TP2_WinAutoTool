# Importation des scripts à tester
. "$PSScriptRoot\..\Saves\scriptSauvegarde.ps1"
. "$PSScriptRoot\..\Saves\ScriptTacheSauvegarde.ps1"

Describe "Tests des fonctions de sauvegarde" {

    BeforeAll {
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName New-EventLog -MockWith { }
        Mock -CommandName Write-EventLog -MockWith { }
        Mock -CommandName New-Item -MockWith { }
        Mock -CommandName Copy-Item -MockWith { }
        Mock -CommandName Compress-Archive -MockWith { }
        Mock -CommandName Remove-Item -MockWith { }
        Mock -CommandName Register-ScheduledTask -MockWith { }
    }

    Context "Script de sauvegarde (scriptSauvegarde.ps1)" {
        It "Doit enregistrer une erreur si l'espace disque est insuffisant" {
            Mock -CommandName Get-PSDrive -MockWith { [PSCustomObject]@{ Root = "C:\"; Free = 5GB } }
            . "$PSScriptRoot\..\Saves\scriptSauvegarde.ps1"
            Assert-MockCalled Write-EventLog -Exactly 1 -Scope It -ParameterFilter { $_.EventId -eq 1001 }
        }

        It "Doit créer les répertoires de sauvegarde et compresser les fichiers" {
            Mock -CommandName Get-PSDrive -MockWith { [PSCustomObject]@{ Root = "C:\"; Free = 20GB } }
            . "$PSScriptRoot\..\Saves\scriptSauvegarde.ps1"
            Assert-MockCalled New-Item -AtLeast 2 -Scope It
            Assert-MockCalled Compress-Archive -Exactly 1 -Scope It
        }

        It "Doit enregistrer le succès après la sauvegarde" {
            . "$PSScriptRoot\..\Saves\scriptSauvegarde.ps1"
            Assert-MockCalled Write-EventLog -Exactly 1 -Scope It -ParameterFilter { $_.EventId -eq 1000 }
        }

        It "Doit enregistrer une erreur si la sauvegarde échoue" {
            Mock -CommandName Compress-Archive -MockWith { throw "Erreur de compression" }
            . "$PSScriptRoot\..\Saves\scriptSauvegarde.ps1"
            Assert-MockCalled Write-EventLog -Exactly 1 -Scope It -ParameterFilter { $_.EventId -eq 1002 }
        }
    }

    Context "Script de tâche planifiée (ScriptTacheSauvegarde.ps1)" {
        It "Doit quitter avec une erreur si le chemin du script est invalide" {
            Mock -CommandName Test-Path -MockWith { $false }
            . "$PSScriptRoot\..\Saves\ScriptTacheSauvegarde.ps1"
            Assert-MockCalled Register-ScheduledTask -Exactly 0 -Scope It
        }

        It "Doit enregistrer une tâche planifiée si le script existe" {
            Mock -CommandName Test-Path -MockWith { $true }
            . "$PSScriptRoot\..\Saves\ScriptTacheSauvegarde.ps1"
            Assert-MockCalled Register-ScheduledTask -Exactly 1 -Scope It
        }

        It "Doit configurer correctement les paramètres et le déclencheur de la tâche" {
            Mock -CommandName New-ScheduledTaskTrigger -MockWith { "MockTrigger" }
            Mock -CommandName New-ScheduledTaskAction -MockWith { "MockAction" }
            Mock -CommandName New-ScheduledTaskPrincipal -MockWith { "MockPrincipal" }
            . "$PSScriptRoot\..\Saves\ScriptTacheSauvegarde.ps1"
            Assert-MockCalled New-ScheduledTaskTrigger -Exactly 1 -Scope It
            Assert-MockCalled New-ScheduledTaskAction -Exactly 1 -Scope It
            Assert-MockCalled New-ScheduledTaskPrincipal -Exactly 1 -Scope It
        }
    }
}
