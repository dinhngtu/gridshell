function Get-G5KCurrentSite {
    param()
    $fqdn = [System.Net.Dns]::GetHostByName($null).HostName
    $fqdnParts = $fqdn.Split('.')
    $currentSite = $null
    if ($fqdnParts.Count -ge 4 -and $fqdn.EndsWith('.grid5000.fr')) {
        $currentSite = $fqdnParts[-3]
    }
    return $currentSite
}

function Get-G5KCurrentUser {
    param()
    if ($null -ne (Get-G5KCurrentSite)) {
        return [System.Environment]::UserName
    } else {
        return $null
    }
}
