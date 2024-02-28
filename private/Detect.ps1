# SPDX-License-Identifier: GPL-3.0-only

$script:currentSite = $null
$script:currentCredential = [pscredential]$null

function Get-GridshellCurrentSite {
    [CmdletBinding()]
    param()
    if ($null -ne $script:currentSite) {
        return $script:currentSite
    }
    $fqdn = [System.Net.Dns]::GetHostByName($null).HostName
    $fqdnParts = $fqdn.Split('.')
    if ($fqdnParts.Count -ge 4 -and $fqdn.EndsWith('.grid5000.fr')) {
        $script:currentSite = $fqdnParts[-3]
    }
    return $script:currentSite
}
Export-ModuleMember -Function Get-GridshellCurrentSite

function Set-GridshellCurrentSite {
    [CmdletBinding(DefaultParameterSetName = "Value")]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Value")]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        [string]
        $Site,
        [Parameter(Mandatory, ParameterSetName = "Default")][switch]$Default
    )
    if ($Default) {
        $Site = $null
    }
    $script:currentSite = $Site
}
Export-ModuleMember -Function Set-GridshellCurrentSite

function Set-GridshellCurrentCredential {
    [CmdletBinding(DefaultParameterSetName = "Value")]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Value")]
        [pscredential]
        $Credential,
        [Parameter(Mandatory, ParameterSetName = "Default")][switch]$Default
    )
    if ($Default) {
        $Credential = $null
    }
    $script:currentCredential = $Credential
}
Export-ModuleMember -Function Set-GridshellCurrentCredential
