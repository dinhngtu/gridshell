function Get-OarSite {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter()][pscredential]$Credential,
        [Parameter(Mandatory, ParameterSetName = "Current")][switch]$Current
    )
    if ($PSCmdlet.ParameterSetName -eq "Current") {
        $currentSite = Get-G5KCurrentSite
        if ($currentSite) {
            return (Get-OarSite $currentSite)
        } else {
            return $null
        }
    }
    else {
        $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}" -f $g5kApiRoot, $Site, $Branch) -Credential $Credential -Body @{
            branch = $Branch
        }
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
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Cluster,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter()][pscredential]$Credential
    )
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/clusters/{2}" -f $g5kApiRoot, $Site, $Cluster) -Credential $Credential -Body @{
        branch = $Branch
    }
    if ($Cluster) {
        return $resp | ConvertTo-OarClusterObject
    }
    else {
        return $resp.items | ConvertTo-OarClusterObject
    }
}
Export-ModuleMember -Function Get-OarCluster

function Get-OarNode {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$Node,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Cluster,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter()][pscredential]$Credential
    )
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/clusters/{2}/nodes/{3}" -f $g5kApiRoot, $Site, $Cluster, $Node) -Credential $Credential -Body @{
        branch = $Branch
    }
    if ($Node) {
        return $resp | ConvertTo-OarNodeObject
    }
    else {
        return $resp.items | ConvertTo-OarNodeObject
    }
}
Export-ModuleMember -Function Get-OarNode
