# Importation des scripts à tester
. "$PSScriptRoot\..\Updates\Install-WindowsUpdates.ps1"
. "$PSScriptRoot\..\Updates\Setup-ScheduledUpdateTask.ps1"

Describe "Tests des mises à jour Windows" {

    BeforeAll {
        Mock -CommandName [System.Diagnostics.EventLog]::SourceExists -MockWith { $true }
        Mock -CommandName [System.Diagnostics.EventLog]::CreateEventSource -MockWith { }
        Mock -CommandName Write-EventLog -MockWith { }
        Mock -CommandName New-Object -MockWith {
            if ($args[0] -eq 'Microsoft.Update.Session') {
                [PSCustomObject]@{
                    CreateUpdateSearcher = { [PSCustomObject]@{ Search = { [PSCustomObject]@{ Updates = @() } } } }
                    CreateUpdateInstaller = { [PSCustomObject]@{ Install = { [PSCustomObject]@{ RebootRequired = $false } } } }
                }
            }
        }
        Mock -CommandName Register-ScheduledTask -MockWith { }
        Mock -CommandName Unregister-ScheduledTask -MockWith { }
        Mock -CommandName Get-ScheduledTask -MockWith { @() }
    }

    Context "Install-WindowsUpdates.ps1" {
        It "Doit créer une source d'événements si elle n'existe pas" {
            Mock -CommandName [System.Diagnostics.EventLog]::SourceExists -MockWith { $false }
            Install-WindowsUpdates
            Assert-MockCalled [System.Diagnostics.EventLog]::CreateEventSource -Exactly 1 -Scope It
        }

        It "Doit enregistrer qu'aucune mise à jour n'est disponible si aucune n'est trouvée" {
            Mock -CommandName New-Object -MockWith {
                if ($args[0] -eq 'Microsoft.Update.Session') {
                    [PSCustomObject]@{
                        CreateUpdateSearcher = { [PSCustomObject]@{ Search = { [PSCustomObject]@{ Updates = @() } } } }
                    }
                }
            }
            Install-WindowsUpdates
            Assert-MockCalled Write-EventLog -Exactly 1 -Scope It -ParameterFilter { $_.EventId -eq 1002 }
        }

        It "Doit installer les mises à jour lorsque des mises à jour sont disponibles" {
            Mock -CommandName New-Object -MockWith {
                if ($args[0] -eq 'Microsoft.Update.Session') {
                    [PSCustomObject]@{
                        CreateUpdateSearcher = { [PSCustomObject]@{ Search = { [PSCustomObject]@{ Updates = @("Update1", "Update2") } } } }
                        CreateUpdateInstaller = { [PSCustomObject]@{ Install = { [PSCustomObject]@{ RebootRequired = $true } } } }
                    }
                }
            }
            Install-WindowsUpdates
            Assert-MockCalled Write-EventLog -AtLeast 3 -Scope It
        }

        It "Doit enregistrer une erreur si une exception se produit pendant l'installation des mises à jour" {
            Mock -CommandName New-Object -MockWith { throw "Test Exception" }
            Install-WindowsUpdates
            Assert-MockCalled Write-EventLog -Exactly 1 -Scope It -ParameterFilter { $_.EventId -eq 1005 }
        }
    }

    Context "Setup-ScheduledUpdateTask.ps1" {
        It "Doit créer une nouvelle tâche planifiée si aucune n'existe" {
            Mock -CommandName Get-ScheduledTask -MockWith { @() }
            . "$PSScriptRoot\..\Updates\Setup-ScheduledUpdateTask.ps1"
            Assert-MockCalled Register-ScheduledTask -Exactly 1 -Scope It
        }

        It "Doit mettre à jour une tâche planifiée existante si elle est trouvée" {
            Mock -CommandName Get-ScheduledTask -MockWith { [PSCustomObject]@{ TaskName = "WinAutoTool-UpdateCheck" } }
            . "$PSScriptRoot\..\Updates\Setup-ScheduledUpdateTask.ps1"
            Assert-MockCalled Unregister-ScheduledTask -Exactly 1 -Scope It
            Assert-MockCalled Register-ScheduledTask -Exactly 1 -Scope It
        }

        It "Doit configurer la tâche avec les bons paramètres" {
            Mock -CommandName New-ScheduledTaskAction -MockWith { "MockAction" }
            Mock -CommandName New-ScheduledTaskTrigger -MockWith { "MockTrigger" }
            Mock -CommandName New-ScheduledTaskPrincipal -MockWith { "MockPrincipal" }
            . "$PSScriptRoot\..\Updates\Setup-ScheduledUpdateTask.ps1"
            Assert-MockCalled New-ScheduledTaskAction -Exactly 1 -Scope It
            Assert-MockCalled New-ScheduledTaskTrigger -Exactly 1 -Scope It
            Assert-MockCalled New-ScheduledTaskPrincipal -Exactly 1 -Scope It
        }
    }
}
