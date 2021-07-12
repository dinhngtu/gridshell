# SPDX-License-Identifier: GPL-3.0-only

function Get-G5KUser {
    <#
    .SYNOPSIS
        Fetch user account information.
    #>
    [CmdletBinding()]
    param(
        # User's name.
        [Parameter(Position = 0)][ValidatePattern("\w*")]$UserName = "~",
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    return Invoke-RestMethod -Uri ("{0}/3.0/users/users/{1}" -f $script:g5kApiRoot, $UserName) -Credential $Credential | ConvertTo-G5KUser
}
Export-ModuleMember -Function Get-G5KUser

function Get-G5KGroup {
    <#
    .SYNOPSIS
        Fetch a collection of Grid'5000 managed groups, or the group description.
    #>
    [CmdletBinding()]
    param(
        # Group's name.
        [Parameter(Position = 0)][string]$GroupName,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/users/groups/{1}" -f $script:g5kApiRoot, $GroupName) -Credential $Credential
    if ($GroupName) {
        return $resp | ConvertTo-G5KGroup
    }
    else {
        return $resp.items | ConvertTo-G5KGroup
    }
}
Export-ModuleMember -Function Get-G5KGroup

function Get-G5KUserGroups {
    <#
    .SYNOPSIS
        Fetch user's groups collection.
    #>
    [CmdletBinding()]
    param(
        # User's name.
        [Parameter(Position = 0)][ValidatePattern("\w*")]$UserName = "~",
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    return (Invoke-RestMethod -Uri ("{0}/3.0/users/users/{1}/groups" -f $script:g5kApiRoot, $UserName) -Credential $Credential).items | ConvertTo-G5KGroupMembership
}
Export-ModuleMember -Function Get-G5KUserGroups

function Get-G5KGroupMembers {
    <#
    .SYNOPSIS
        Fetch a collection of members for group.
    #>
    [CmdletBinding()]
    param(
        # Group's name.
        [Parameter(Mandatory, Position = 0)][ValidatePattern("\w*")]$GroupName,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    return (Invoke-RestMethod -Uri ("{0}/3.0/users/groups/{1}/members" -f $script:g5kApiRoot, $GroupName) -Credential $Credential).items
}
Export-ModuleMember -Function Get-G5KGroupMembers
