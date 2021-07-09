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
        [Parameter(Position = 0)][string]$GroupName,
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $resp = Invoke-RestMethod -Uri ("{0}/3.0/users/groups/{1}" -f $g5kApiRoot, $GroupName) -Credential $Credential
    if ($GroupName) {
        return $resp
    }
    else {
        return $resp.items
    }
}
Export-ModuleMember -Function Get-G5KGroup

function Get-G5KUserGroups {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][ValidatePattern("\w*")]$UserName = "~",
        [Parameter()][pscredential]$Credential
    )
    return (Invoke-RestMethod -Uri ("{0}/3.0/users/users/{1}/groups" -f $g5kApiRoot, $UserName) -Credential $Credential).items
}
Export-ModuleMember -Function Get-G5KUserGroups

function Get-G5KGroupMembers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][ValidatePattern("\w*")]$GroupName,
        [Parameter()][pscredential]$Credential
    )
    return (Invoke-RestMethod -Uri ("{0}/3.0/users/groups/{1}/members" -f $g5kApiRoot, $GroupName) -Credential $Credential).items
}
Export-ModuleMember -Function Get-G5KGroupMembers
