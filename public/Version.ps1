# SPDX-License-Identifier: GPL-3.0-only

function Get-OarVersion {
    [CmdletBinding(DefaultParameterSetName = "List")]
    param(
        [Parameter(Position = 0, ParameterSetName = "Get")][ValidatePattern("\w*")]$VersionId,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter(ParameterSetName = "List")][ValidateRange(0, 999999999)][int]$Limit = 50,
        [Parameter(ParameterSetName = "List")][ValidateRange(1, 500)][int]$Offset = 0,
        [Parameter()][pscredential]$Credential
    )
    $params = Remove-EmptyValues @{
        branch = $Branch;
        limit  = $Limit;
        offset = $Offset;
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/versions/{1}" -f $g5kApiRoot, $VersionId) -Credential $Credential -Body $params
    if ($VersionId) {
        return $resp
    }
    else {
        return $resp.items
    }
}
Export-ModuleMember -Function Get-OarVersion

function Get-OarSiteVersion {
    [CmdletBinding(DefaultParameterSetName = "List")]
    param(
        [Parameter(Position = 0, ParameterSetName = "Get")][ValidatePattern("\w*")]$VersionId,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")]$Site,
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        [Parameter(ParameterSetName = "List")][ValidateRange(0, 999999999)][int]$Limit = 50,
        [Parameter(ParameterSetName = "List")][ValidateRange(1, 500)][int]$Offset = 0,
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        branch = $Branch;
        limit  = $Limit;
        offset = $Offset;
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/versions/{2}" -f $g5kApiRoot, $Site, $VersionId) -Credential $Credential -Body $params
    if ($VersionId) {
        return $resp
    }
    else {
        return $resp.items
    }
}
Export-ModuleMember -Function Get-OarSiteVersion
