Describe "Fonctions de AppManager" {

    BeforeAll {
        Mock -CommandName New-EventLog -MockWith { }
        Mock -CommandName Write-EventLog -MockWith { }
        Mock -CommandName Get-CimInstance -MockWith { @{} }
        Mock -CommandName Remove-AppxPackage -MockWith { }
        Mock -CommandName Start-Process -MockWith { }
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Get-Content -MockWith { '{"appsToInstall":["App1","App2"],"appsToRemove":["App3"]}' }
        Mock -CommandName ConvertFrom-Json -MockWith { @{"appsToInstall"="App1"; "appsToRemove"="App3"} }
    }

    Context "Create-LogSource" {
        It "Devrait créer une source de journal si elle n'existe pas" {
            Mock -CommandName [System.Diagnostics.EventLog]::SourceExists -MockWith { $false }
            Create-LogSource
            Assert-MockCalled New-EventLog -Exactly 1 -Scope It
        }
    }

    Context "Get-Config" {
        It "Devrait retourner la configuration à partir du fichier de configuration" {
            $config = Get-Config
            $config.appsToInstall | Should -Be "App1"
        }

        It "Devrait retourner null si le fichier de configuration est manquant" {
            Mock -CommandName Test-Path -MockWith { $false }
            $config = Get-Config
            $config | Should -Be $null
        }
    }

    Context "Manage-App" {
        It "Devrait tenter d'installer une application" {
            Manage-App -appName "TestApp" -isInstall $true
            Assert-MockCalled Start-Process -Exactly 1 -Scope It
        }

        It "Devrait gérer la désinstallation des applications installées" {
            Mock -CommandName Is-AppInstalled -MockWith { @{"UninstallString"="mockUninstall"} }
            Manage-App -appName "TestApp" -isInstall $false
            Assert-MockCalled Start-Process -Exactly 1 -Scope It
        }

        It "Devrait enregistrer une erreur si l'application n'est pas installée" {
            Mock -CommandName Is-AppInstalled -MockWith { $null }
            Manage-App -appName "TestApp" -isInstall $false
            Assert-MockCalled Write-EventLog -Exactly 1 -Scope It
        }
    }

    Context "Change-Background" {
        It "Devrait télécharger et définir les images du fond d'écran et de l'écran de verrouillage" {
            Mock -CommandName Start-BitsTransfer -MockWith { }
            Mock -CommandName New-ItemProperty -MockWith { }
            Change-Background -Path "C:\TestPath\image.jpg"
            Assert-MockCalled Start-BitsTransfer -Times 2 -Scope It
            Assert-MockCalled New-ItemProperty -AtLeast 1 -Scope It
        }
    }

    Context "Remove-SearchBar" {
        It "Devrait mettre à jour les paramètres du registre pour supprimer la barre de recherche" {
            Mock -CommandName [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey -MockWith { New-Object PSObject }
            Mock -CommandName [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey -MockWith { New-Object PSObject }
            Remove-SearchBar
            Assert-MockCalled [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey -AtLeast 1 -Scope It
        }
    }
}
