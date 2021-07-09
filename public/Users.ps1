function Get-G5KUser {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$UserName = "~",
        [Parameter()][pscredential]$Credential
    )
    return Invoke-RestMethod -Uri ("{0}/3.0/users/users/{1}" -f $g5kApiRoot, $UserName) -Credential $Credential
}
Export-ModuleMember -Function Get-G5KUser

function Get-G5KGroup {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]$GroupName,
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
        date      = $Date ? $Date.ToString("s") : $null;
        timestamp = $UnixTimestamp;
        version   = $Version;
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/clusters/{2}/nodes/{3}" -f $g5kApiRoot, $Site, $Cluster, $Node) -Credential $Credential -Body $params
    if ($Node) {
        return $resp | ConvertTo-OarNodeObject
    }
    else {
        return $resp.items | ConvertTo-OarNodeObject
    }
}
Export-ModuleMember -Function Get-OarNode
