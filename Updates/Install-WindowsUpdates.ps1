function Install-WindowsUpdates {
    if (-not [System.Diagnostics.EventLog]::SourceExists("WinAutoTool")) {
        [System.Diagnostics.EventLog]::CreateEventSource("WinAutoTool", "Application")
    }

    Write-EventLog -LogName Application -Source "WinAutoTool" -EntryType Information -EventId 1001 -Message "Début de la recherche de mises à jour."

    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()

        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")

        if ($searchResult.Updates.Count -eq 0) {
            Write-EventLog -LogName Application -Source "WinAutoTool" -EntryType Information -EventId 1002 -Message "Aucune mise à jour de sécurité disponible."
            return
        }

        $updateInstaller = $updateSession.CreateUpdateInstaller()
        $updateCollection = New-Object -ComObject Microsoft.Update.UpdateColl

        foreach ($update in $searchResult.Updates) {
            $updateCollection.Add($update) | Out-Null
        }

        $updateInstaller.Updates = $updateCollection
        $installationResult = $updateInstaller.Install()

        foreach ($update in $searchResult.Updates) {
            $updateStatus = if ($update.IsInstalled) { "Succès" } else { "Échec" }
            Write-EventLog -LogName Application -Source "WinAutoTool" -EntryType Information -EventId 1003 -Message "Mise à jour '$($update.Title)' : $updateStatus."
        }

        if ($installationResult.RebootRequired) {
            Write-EventLog -LogName Application -Source "WinAutoTool" -EntryType Information -EventId 1004 -Message "Un redémarrage est nécessaire pour compléter les mises à jour."
        }

    } catch {
        Write-EventLog -LogName Application -Source "WinAutoTool" -EntryType Error -EventId 1005 -Message "Erreur lors de l'installation des mises à jour: $_"
    }
}

Install-WindowsUpdates

Install-WindowsUpdates
