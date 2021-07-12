# SPDX-License-Identifier: GPL-3.0-only

function Get-OarSiteStatus {
    <#
    .SYNOPSIS
        Fetch site OAR resources status and reservations.
    #>
    [CmdletBinding()]
    param(
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        # Enable or disable status of disks in response.
        [Parameter()][switch]$Disks,
        # Enable or disable status of nodes in response.
        [Parameter()][switch]$Nodes,
        # Enable or disable status of vlans in response.
        [Parameter()][switch]$Vlans,
        # Enable or disable status of subnets in response.
        [Parameter()][switch]$Subnets,
        # Specify a user account that has permission to perform this action. The default is the current user.
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
        # Cluster's ID.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Cluster,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        # Enable or disable status of disks in response.
        [Parameter()][switch]$Disks,
        # Enable or disable status of nodes in response.
        [Parameter()][switch]$Nodes,
        # Specify a user account that has permission to perform this action. The default is the current user.
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
