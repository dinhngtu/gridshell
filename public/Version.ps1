# SPDX-License-Identifier: GPL-3.0-only

function Get-OarVersion {
    <#
    .SYNOPSIS
        Fetch a collection of reference-repository git version, or a specific version commit item of reference-repository. A version is a Git commit.
    #>
    [CmdletBinding(DefaultParameterSetName = "List")]
    param(
        # ID of version to fetch, as a Git commit hash.
        [Parameter(Position = 0, ParameterSetName = "Get")][ValidatePattern("\w*")]$VersionId,
        # Use a specific branch of reference-repository, for example the 'testing' branch contains the resources that are not yet in production.
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        # Limit the number of items to return.
        [Parameter(ParameterSetName = "List")][ValidateRange(0, 999999999)][int]$Limit = 50,
        # Paginate through the collection with multiple requests.
        [Parameter(ParameterSetName = "List")][ValidateRange(1, 500)][int]$Offset = 0,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    $params = $null
    if ($PSCmdlet.ParameterSetName -eq "List") {
        $params = Remove-EmptyValues @{
            branch = $Branch;
            limit  = $Limit;
            offset = $Offset;
        }
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/versions/{1}" -f $script:g5kApiRoot, $VersionId) -Credential $Credential -Body $params
    if ($VersionId) {
        return $resp
    }
    else {
        return $resp.items
    }
}
Export-ModuleMember -Function Get-OarVersion

function Get-OarSiteVersion {
    <#
    .SYNOPSIS
        Fetch a collection of reference-repository git versions for a specific site, or a specific version commit item of reference-repository. A version is a Git commit.
    #>
    [CmdletBinding(DefaultParameterSetName = "List")]
    param(
        # ID of version to fetch, as a Git commit hash.
        [Parameter(Position = 0, ParameterSetName = "Get")][ValidatePattern("\w*")]$VersionId,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        $Site,
        # Use a specific branch of reference-repository, for example the 'testing' branch contains the resources that are not yet in production.
        [Parameter()][ValidatePattern("\w*")]$Branch = "master",
        # Limit the number of items to return.
        [Parameter(ParameterSetName = "List")][ValidateRange(0, 999999999)][int]$Limit = 50,
        # Paginate through the collection with multiple requests.
        [Parameter(ParameterSetName = "List")][ValidateRange(1, 500)][int]$Offset = 0,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = $null
    if ($PSCmdlet.ParameterSetName -eq "List") {
        $params = Remove-EmptyValues @{
            branch = $Branch;
            limit  = $Limit;
            offset = $Offset;
        }
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/versions/{2}" -f $script:g5kApiRoot, $Site, $VersionId) -Credential $Credential -Body $params
    if ($VersionId) {
        return $resp
    }
    else {
        return $resp.items
    }
}
Export-ModuleMember -Function Get-OarSiteVersion
