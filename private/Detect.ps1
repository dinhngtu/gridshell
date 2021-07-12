# SPDX-License-Identifier: GPL-3.0-only

function Get-G5KCurrentSite {
    [CmdletBinding()]
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
    [CmdletBinding()]
    param([Parameter()][pscredential]$Credential)
    $user = Get-G5KUser -Credential $Credential
    return $user.uid
}
