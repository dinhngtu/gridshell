function Get-KaEnvironment {
    [CmdletBinding(DefaultParameterSetName = "List")]
    param(
        [Parameter()][ValidatePattern("\w*")]$Site,
        [Parameter(ParameterSetName = "Get", Position = 0, Mandatory)][string]$Uid,
        [Parameter(ParameterSetName = "List")][switch]$AllVersions,
        [Parameter(ParameterSetName = "List")][string]$User,
        [Parameter(ParameterSetName = "List")][string]$Architecture,
        [Parameter(ParameterSetName = "List")][string]$Name,
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    if ($PSCmdlet.ParameterSetName -eq "Get") {
        $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/environments/{2}" -f $g5kApiRoot, $Site, $Uid) -Credential $Credential
        return $resp
    }
    elseif ($PSCmdlet.ParameterSetName -eq "List") {
        $params = Remove-EmptyValues @{
            name         = $Name;
            architecture = $Architecture;
            user         = $User;
            latest_only  = $AllVersions ? "no" : "yes";
        }
        $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/environments" -f $g5kApiRoot, $Site) -Credential $Credential -Body $params
        return $resp.items
    }
}
Export-ModuleMember -Function Get-KaEnvironment
