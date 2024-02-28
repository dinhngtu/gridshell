# SPDX-License-Identifier: GPL-3.0-only

function Get-OarSiteStatus {
    <#
    .SYNOPSIS
        Fetch site OAR resources status and reservations.
    #>
    [CmdletBinding()]
    param(
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Disable status of disks in response.
        [Parameter()][switch]$NoDisks,
        # Disable status of nodes in response.
        [Parameter()][switch]$NoNodes,
        # Disable status of vlans in response.
        [Parameter()][switch]$NoVlans,
        # Disable status of subnets in response.
        [Parameter()][switch]$NoSubnets,
        # Don't get upcoming jobs on resources in 'reservations' Array (in addition to current jobs).
        [Parameter()][switch]$NoWaiting,
        # Don't get jobs on resources. 'reservations' Array will not be present.
        [Parameter()][switch]$NoJobDetails,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-GridshellCurrentSite
    }
    $params = Remove-EmptyValues @{
        disks       = if ($NoDisks) { "no" } else { "yes" };
        nodes       = if ($NoNodes) { "no" } else { "yes" };
        vlans       = if ($NoVlans) { "no" } else { "yes" };
        subnets     = if ($NoSubnets) { "no" } else { "yes" };
        waiting     = if ($NoWaiting) { "no" } else { "yes" };
        job_details = if ($NoJobDetails) { "no" } else { "yes" };
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/status" -f $script:g5kApiRoot, $Site) -Credential $Credential -Body $params
}
Export-ModuleMember -Function Get-OarSiteStatus

function Get-OarClusterStatus {
    [CmdletBinding()]
    param(
        # Cluster's ID.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompleter({ Get-GridshellClusterCompletion @args })]
        $Cluster,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Disable status of disks in response.
        [Parameter()][switch]$NoDisks,
        # Disable status of nodes in response.
        [Parameter()][switch]$NoNodes,
        # Don't get upcoming jobs on resources in 'reservations' Array (in addition to current jobs).
        [Parameter()][switch]$NoWaiting,
        # Don't get jobs on resources. 'reservations' Array will not be present.
        [Parameter()][switch]$NoJobDetails,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-GridshellCurrentSite
    }
    $params = Remove-EmptyValues @{
        disks       = if ($NoDisks) { "no" } else { "yes" };
        nodes       = if ($NoNodes) { "no" } else { "yes" };
        waiting     = if ($NoWaiting) { "no" } else { "yes" };
        job_details = if ($NoJobDetails) { "no" } else { "yes" };
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/clusters/{2}/status" -f $script:g5kApiRoot, $Site, $Cluster) -Credential $Credential -Body $params
}
Export-ModuleMember -Function Get-OarClusterStatus

function Get-OarNodeAvailability {
    [CmdletBinding()]
    param(
        # Cluster's ID.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompleter({ Get-GridshellClusterCompletion @args })]
        $Cluster,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Disable status of disks in response.
        [Parameter()][switch]$NoDisks,
        # Disable status of nodes in response.
        [Parameter()][switch]$NoNodes,
        # Don't get upcoming jobs on resources in 'reservations' Array (in addition to current jobs).
        [Parameter()][switch]$NoWaiting,
        # Don't get jobs on resources. 'reservations' Array will not be present.
        [Parameter()][switch]$NoJobDetails,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-GridshellCurrentSite
    }
    $resp = Get-OarClusterStatus -Cluster $Cluster -Site $Site -NoDisks:$NoDisks -NoNodes:$NoNodes -NoWaiting:$NoWaiting -NoJobDetails:$NoJobDetails -Credential $Credential
    return $resp.nodes | ConvertTo-OarNodeAvailabilityObject | Sort-Object -Property Node
}
Export-ModuleMember -Function Get-OarNodeAvailability
