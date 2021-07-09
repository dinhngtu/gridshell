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
        disks   = $Disks ? "yes" : "no";
        nodes   = $Nodes ? "yes" : "no";
        vlans   = $Vlans ? "yes" : "no";
        subnets = $Subnets ? "yes" : "no";
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/status" -f $g5kApiRoot, $Site) -Credential $Credential -Body $params
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
        disks = $Disks ? "yes" : "no";
        nodes = $Nodes ? "yes" : "no";
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/clusters/{2}/status" -f $g5kApiRoot, $Site, $Cluster) -Credential $Credential -Body $params
}
Export-ModuleMember -Function Get-OarClusterStatus
