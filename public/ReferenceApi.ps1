# SPDX-License-Identifier: GPL-3.0-only

function Get-OarSite {
    <#
    .SYNOPSIS
        Fetch a collection of Grid'5000 sites, or the description of a specific site.
    #>
    [CmdletBinding(DefaultParameterSetName = "DefaultDate")]
    param(
        # Site's ID.
        [Parameter(Position = 0)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Use a specific branch of reference-repository, for example the 'testing' branch contains the resources that are not yet in production.
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        # Fetch the version of reference-repository for the specified date.
        [Parameter(ParameterSetName = "DefaultDate")]
        [Parameter(ParameterSetName = "CurrentDate")]
        [System.Nullable[datetime]]$Date,
        # Fetch the version of reference-repository for the specified UNIX timestamp.
        [Parameter(Mandatory, ParameterSetName = "DefaultUnixTimestamp")]
        [Parameter(Mandatory, ParameterSetName = "CurrentUnixTimestamp")]
        [System.Nullable[long]]$UnixTimestamp,
        # Specificy the reference-repository's commit hash to get. This allow to get a specific version of the requested resource, to go back in time.
        [Parameter(Mandatory, ParameterSetName = "DefaultVersion")]
        [Parameter(Mandatory, ParameterSetName = "CurrentVersion")]
        [string]$Version,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential,
        # Get the current Grid'5000 site you're on.
        [Parameter(Mandatory, ParameterSetName = "CurrentDate")]
        [Parameter(Mandatory, ParameterSetName = "CurrentUnixTimestamp")]
        [Parameter(Mandatory, ParameterSetName = "CurrentVersion")]
        [switch]$Current
    )
    $params = Remove-EmptyValues @{
        branch    = $Branch;
        date      = if ($Date) { $Date.ToString("s") } else { $null };
        timestamp = $UnixTimestamp;
        version   = $Version;
    }
    if ($PSCmdlet.ParameterSetName -like "Current*") {
        $currentSite = Get-G5KCurrentSite
        if ($currentSite) {
            return (Get-OarSite $currentSite)
        }
        else {
            return $null
        }
    }
    else {
        $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}" -f $script:g5kApiRoot, $Site) -Credential $Credential -Body $params
        if ($Site) {
            return $resp | ConvertTo-OarSiteObject
        }
        else {
            return $resp.items | ConvertTo-OarSiteObject
        }
    }
}
Export-ModuleMember -Function Get-OarSite

function Get-OarCluster {
    <#
    .SYNOPSIS
        Fetch a collection of Grid'5000 clusters for a specific site, or the description of a specific cluster.
    #>
    [CmdletBinding(DefaultParameterSetName = "Date")]
    param(
        # Cluster's ID.
        [Parameter(Position = 0)]
        [ValidatePattern("\w*")]
        [ArgumentCompleter({ Get-G5KClusterCompletion @args })]
        $Cluster,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Use a specific branch of reference-repository, for example the 'testing' branch contains the resources that are not yet in production.
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        # Fetch the version of reference-repository for the specified date.
        [Parameter(ParameterSetName = "Date")][System.Nullable[datetime]]$Date,
        # Fetch the version of reference-repository for the specified UNIX timestamp.
        [Parameter(ParameterSetName = "UnixTimestamp")][System.Nullable[long]]$UnixTimestamp,
        # Specificy the reference-repository's commit hash to get. This allow to get a specific version of the requested resource, to go back in time.
        [Parameter(ParameterSetName = "Version")][string]$Version,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        branch    = $Branch;
        date      = if ($Date) { $Date.ToString("s") } else { $null };
        timestamp = $UnixTimestamp;
        version   = $Version;
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/clusters/{2}" -f $script:g5kApiRoot, $Site, $Cluster) -Credential $Credential -Body $params
    if ($Cluster) {
        return $resp | ConvertTo-OarClusterObject
    }
    else {
        return $resp.items | ConvertTo-OarClusterObject
    }
}
Export-ModuleMember -Function Get-OarCluster

function Get-OarNode {
    <#
    .SYNOPSIS
        Fetch a collection of Grid'5000 servers for a specific site, or the description of a specific server.
    #>
    [CmdletBinding(DefaultParameterSetName = "Date")]
    param(
        # Server's ID.
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Node,
        # Cluster's ID.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompleter({ Get-G5KClusterCompletion @args })]
        $Cluster,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Use a specific branch of reference-repository, for example the 'testing' branch contains the resources that are not yet in production.
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        # Fetch the version of reference-repository for the specified date.
        [Parameter(ParameterSetName = "Date")][System.Nullable[datetime]]$Date,
        # Fetch the version of reference-repository for the specified UNIX timestamp.
        [Parameter(ParameterSetName = "UnixTimestamp")][System.Nullable[long]]$UnixTimestamp,
        # Specificy the reference-repository's commit hash to get. This allow to get a specific version of the requested resource, to go back in time.
        [Parameter(ParameterSetName = "Version")][string]$Version,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        branch    = $Branch;
        date      = if ($Date) { $Date.ToString("s") } else { $null };
        timestamp = $UnixTimestamp;
        version   = $Version;
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/clusters/{2}/nodes/{3}" -f $script:g5kApiRoot, $Site, $Cluster, $Node) -Credential $Credential -Body $params
    if ($Node) {
        return $resp | ConvertTo-OarNodeObject
    }
    else {
        return $resp.items | ConvertTo-OarNodeObject
    }
}
Export-ModuleMember -Function Get-OarNode

function Get-OarPdu {
    <#
    .SYNOPSIS
        Fetch a collection of Grid'5000 pdus for a specific site, or the description of a specific pdu.
    #>
    [CmdletBinding(DefaultParameterSetName = "Date")]
    param(
        # Pdu's ID.
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Pdu,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Use a specific branch of reference-repository, for example the 'testing' branch contains the resources that are not yet in production.
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        # Fetch the version of reference-repository for the specified date.
        [Parameter(ParameterSetName = "Date")][System.Nullable[datetime]]$Date,
        # Fetch the version of reference-repository for the specified UNIX timestamp.
        [Parameter(ParameterSetName = "UnixTimestamp")][System.Nullable[long]]$UnixTimestamp,
        # Specificy the reference-repository's commit hash to get. This allow to get a specific version of the requested resource, to go back in time.
        [Parameter(ParameterSetName = "Version")][string]$Version,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        branch    = $Branch;
        date      = if ($Date) { $Date.ToString("s") } else { $null };
        timestamp = $UnixTimestamp;
        version   = $Version;
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/pdus/{2}" -f $script:g5kApiRoot, $Site, $Pdu) -Credential $Credential -Body $params
    if ($Pdu) {
        return $resp
    }
    else {
        return $resp.items
    }
}
Export-ModuleMember -Function Get-OarPdu

function Get-OarNetworkEquipment {
    <#
    .SYNOPSIS
        Fetch a collection of Grid'5000 network_equipments for a specific site, or the description of a specific network_equipment.
    #>
    [CmdletBinding(DefaultParameterSetName = "Date")]
    param(
        # Network Equipment's ID.
        [Parameter(Position = 0)][ValidatePattern("\w*")]$EquipmentId,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Use a specific branch of reference-repository, for example the 'testing' branch contains the resources that are not yet in production.
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        # Fetch the version of reference-repository for the specified date.
        [Parameter(ParameterSetName = "Date")][System.Nullable[datetime]]$Date,
        # Fetch the version of reference-repository for the specified UNIX timestamp.
        [Parameter(ParameterSetName = "UnixTimestamp")][System.Nullable[long]]$UnixTimestamp,
        # Specificy the reference-repository's commit hash to get. This allow to get a specific version of the requested resource, to go back in time.
        [Parameter(ParameterSetName = "Version")][string]$Version,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        branch    = $Branch;
        date      = if ($Date) { $Date.ToString("s") } else { $null };
        timestamp = $UnixTimestamp;
        version   = $Version;
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/network_equipments/{2}" -f $script:g5kApiRoot, $Site, $EquipmentId) -Credential $Credential -Body $params
    if ($Pdu) {
        return $resp
    }
    else {
        return $resp.items
    }
}
Export-ModuleMember -Function Get-OarNetworkEquipment
