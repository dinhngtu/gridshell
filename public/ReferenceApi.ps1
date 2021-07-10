# SPDX-License-Identifier: GPL-3.0-only

function Get-OarSite {
    [CmdletBinding(DefaultParameterSetName = "DefaultDate")]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter(ParameterSetName = "DefaultDate")]
        [Parameter(ParameterSetName = "CurrentDate")]
        [System.Nullable[datetime]]$Date,
        [Parameter(Mandatory, ParameterSetName = "DefaultUnixTimestamp")]
        [Parameter(Mandatory, ParameterSetName = "CurrentUnixTimestamp")]
        [System.Nullable[long]]$UnixTimestamp,
        [Parameter(Mandatory, ParameterSetName = "DefaultVersion")]
        [Parameter(Mandatory, ParameterSetName = "CurrentVersion")]
        [string]$Version,
        [Parameter()][pscredential]$Credential,
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
    [CmdletBinding(DefaultParameterSetName = "Date")]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Cluster,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter(ParameterSetName = "Date")][System.Nullable[datetime]]$Date,
        [Parameter(ParameterSetName = "UnixTimestamp")][System.Nullable[long]]$UnixTimestamp,
        [Parameter(ParameterSetName = "Version")][string]$Version,
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
    [CmdletBinding(DefaultParameterSetName = "Date")]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Node,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Cluster,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter(ParameterSetName = "Date")][System.Nullable[datetime]]$Date,
        [Parameter(ParameterSetName = "UnixTimestamp")][System.Nullable[long]]$UnixTimestamp,
        [Parameter(ParameterSetName = "Version")][string]$Version,
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
    [CmdletBinding(DefaultParameterSetName = "Date")]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Pdu,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter(ParameterSetName = "Date")][System.Nullable[datetime]]$Date,
        [Parameter(ParameterSetName = "UnixTimestamp")][System.Nullable[long]]$UnixTimestamp,
        [Parameter(ParameterSetName = "Version")][string]$Version,
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
    [CmdletBinding(DefaultParameterSetName = "Date")]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$EquipmentId,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter(ParameterSetName = "Date")][System.Nullable[datetime]]$Date,
        [Parameter(ParameterSetName = "UnixTimestamp")][System.Nullable[long]]$UnixTimestamp,
        [Parameter(ParameterSetName = "Version")][string]$Version,
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
