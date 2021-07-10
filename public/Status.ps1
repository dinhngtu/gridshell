# SPDX-License-Identifier: GPL-3.0-only

function Get-OarSiteStatus {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][switch]$Disks,
        [Parameter()][switch]$Nodes,
        [Parameter()][switch]$Vlans,
        [Parameter()][switch]$Subnets,
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        disks   = if ($Disks) { "yes" } else { "no" };
        nodes   = if ($Nodes) { "yes" } else { "no" };
        vlans   = if ($Vlans) { "yes" } else { "no" };
        subnets = if ($Subnets) { "yes" } else { "no" };
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/status" -f $script:g5kApiRoot, $Site) -Credential $Credential -Body $params
}
Export-ModuleMember -Function Get-OarSiteStatus

function Get-OarClusterStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Cluster,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][switch]$Disks,
        [Parameter()][switch]$Nodes,
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        disks = if ($Disks) { "yes" } else { "no" };
        nodes = if ($Nodes) { "yes" } else { "no" };
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/clusters/{2}/status" -f $script:g5kApiRoot, $Site, $Cluster) -Credential $Credential -Body $params
}
Export-ModuleMember -Function Get-OarClusterStatus
