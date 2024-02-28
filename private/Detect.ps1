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
    if ($null -eq $script:currentSite) {
        throw "Cannot detect current site, set it manually with Get-GridshellCurrentSite"
    }
    return $script:currentSite
}
Export-ModuleMember -Function Get-GridshellCurrentSite
New-Alias -Name Get-OarCurrentSite -Value Get-GridshellCurrentSite
Export-ModuleMember -Alias Get-OarCurrentSite

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
New-Alias -Name Set-OarCurrentSite -Value Set-GridshellCurrentSite
Export-ModuleMember -Alias Set-OarCurrentSite

function Connect-G5KUser {
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
Export-ModuleMember -Function Connect-G5KUser

function Disconnect-G5KUser {
    $script:currentCredential = $null
}
Export-ModuleMember -Function Disconnect-G5KUser
