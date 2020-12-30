function Get-OarJob {
    [CmdletBinding(DefaultParameterSetName = "Query")]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][int]$JobId,
        [Parameter()][ValidatePattern("\w*")][string]$Site,
        [Parameter(ParameterSetName = "Query")][ValidateRange(0, 10000)][int]$Offset = 0,
        [Parameter(ParameterSetName = "Query")][ValidateRange(1, 500)][int]$Limit = 50,
        [Parameter(ParameterSetName = "Query")][ValidateSet("waiting", "launching", "running", "hold", "error", "terminated")][string[]]$State = @("waiting", "launching", "running", "hold"),
        [Parameter(ParameterSetName = "Query")][ValidatePattern("\w*")][string]$Project,
        [Parameter(ParameterSetName = "Query")][ValidatePattern("\w*")][string]$User = $(Get-G5KCurrentUser),
        [Parameter(ParameterSetName = "Query")][ValidateSet("default", "production", "admin")][string]$Queue,
        [Parameter(ParameterSetName = "Query")][switch]$Resources,
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    if ($PSCmdlet.ParameterSetName -eq "Query") {
        if ($User -eq "*") {
            $User = ''
        }
        $params = Remove-EmptyValues @{
            offset  = $Offset;
            limit   = $Limit;
            state   = $State -join ",";
            project = $Project;
            user    = $User;
            queue   = $Queue;
        }
        return (Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/jobs" -f $g5kApiRoot, $Site) -Credential $Credential -Body $params).items | ConvertTo-OarJobObject
    }
    else {
        return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/jobs/{2}" -f $g5kApiRoot, $Site, $JobId) -Credential $Credential | ConvertTo-OarJobObject
    }
}
Export-ModuleMember -Function Get-OarJob

function New-OarJob {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)][ValidateNotNullOrEmpty()][string]$Command,
        [Parameter()][ValidatePattern("\w*")][string]$Site,
        [Parameter()][string]$Resources,
        [Parameter()][string]$Directory = $(Get-Location),
        [Parameter()][string]$Output,
        [Parameter()][string]$ErrorOutput,
        [Parameter()][string]$Properties,
        [Parameter()][System.Nullable[datetime]]$Reservation,
        [Parameter()][ValidateSet("day", "night", "besteffort", "cosystem", "container", "inner", "noop", "allow_classic_ssh", "deploy")][string[]]$Type = @(),
        [Parameter()][string]$Project,
        [Parameter()][string]$Name,
        [Parameter()][ValidateSet("default", "production", "admin")][string]$Queue = "default",
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    if ($PSCmdlet.ShouldProcess(("command '{0}', type '{1}'" -f $Command, $Type -join ","), "New-OarJob")) {
        $params = Remove-EmptyValues @{
            command     = $Command;
            resources   = $Resources;
            directory   = $Directory;
            stdout      = $Output;
            stderr      = $ErrorOutput;
            properties  = $Properties;
            reservation = $Reservation ? ([System.DateTimeOffset]$Reservation).ToUnixTimeSeconds() : $null;
            types       = $Type;
            project     = $Project;
            name        = $Name;
            queue       = $Queue;
        }
        return Invoke-RestMethod -Method Post -Uri ("{0}/3.0/sites/{1}/jobs/{2}" -f $g5kApiRoot, $Site, $Id) -Credential $Credential -Body (ConvertTo-Json -InputObject $params) -ContentType "application/json" | ConvertTo-OarJobObject
    }
}
Export-ModuleMember -Function New-OarJob

function Remove-OarJob {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][int]$JobId,
        [Parameter(ParameterSetName = "Id", ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string]$Site,
        [Parameter()][pscredential]$Credential,
        [Parameter()][switch]$AsJob
    )
    begin {}
    process {
        if (!$Site) {
            $Site = Get-G5KCurrentSite
        }
        if ($PSCmdlet.ShouldProcess("job '{0}', site '{1}'" -f @($JobId, $Site), "Remove-OarJob")) {
            $resp = Invoke-RestMethod -Method Delete -Uri ("{0}/3.0/sites/{1}/jobs/{2}" -f $g5kApiRoot, $Site, $JobId) -Credential $Credential
            if ($AsJob) {
                return Start-Job -ArgumentList @($Site, $JobId) -ScriptBlock {
                    param($Site, $JobId)
                    do {
                        $pollResp = Get-OarJob -Site $Site -JobId $JobId
                    } until ($pollResp.state -eq "error" -or $pollResp.state -eq "terminated")
                }
            }
            else {
                return $resp
            }
        }
    }
    end {}
}
Export-ModuleMember -Function Remove-OarJob
