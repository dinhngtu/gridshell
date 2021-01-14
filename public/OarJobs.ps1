function Get-OarJob {
    [CmdletBinding(DefaultParameterSetName = "Query")]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][int[]]$JobId,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        [Parameter(ParameterSetName = "Query")][ValidateRange(0, 10000)][int]$Offset = 0,
        [Parameter(ParameterSetName = "Query")][ValidateRange(1, 500)][int]$Limit = 50,
        [Parameter(ParameterSetName = "Query")][ValidateSet("waiting", "launching", "running", "hold", "error", "terminated", "*")][string[]]$State = @("waiting", "launching", "running", "hold"),
        [Parameter(ParameterSetName = "Query")][ValidatePattern("\w*")][string]$Project,
        [Parameter(ParameterSetName = "Query")][ValidatePattern("\w*")][string]$User = $(Get-G5KCurrentUser),
        [Parameter(ParameterSetName = "Query")][ValidateSet("default", "production", "admin", "besteffort")][string]$Queue,
        [Parameter(ParameterSetName = "Query")][switch]$Resources,
        [Parameter()][pscredential]$Credential
    )
    begin {
        if (!$PSBoundParameters.Site -and !$Site.Count) {
            $Site = @(Get-G5KCurrentSite)
        }
        if ($PSCmdlet.ParameterSetName -eq "Query") {
            if ($Site.Count -gt 1) {
                throw [System.ArgumentException]::new("You can only specify at most one site in your query")
            }
            if ($User -eq "*") {
                $User = ''
            }
            if ("*" -in $State) {
                $State = @()
            }
            $params = Remove-EmptyValues @{
                offset  = $Offset;
                limit   = $Limit;
                state   = $State -join ",";
                project = $Project;
                user    = $User;
                queue   = $Queue;
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq "Id") {
            if ($PSBoundParameters.Site -and $Site.Count -ne $JobId.Count -and $Site.Count -ne 1) {
                throw [System.ArgumentException]::new("You can only specify one site per job ID")
            }
        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq "Query") {
            return (Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/jobs" -f $g5kApiRoot, $Site[0]) -Credential $Credential -Body $params).items | ConvertTo-OarJobObject
        }
        else {
            for ($i = 0; $i -lt $JobId.Count; $i++) {
                $currentJobId = $JobId[$i]
                if ($Site.Count -eq 1) {
                    $currentSite = $Site[0]
                }
                else {
                    $currentSite = $Site[$i]
                }
                Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/jobs/{2}" -f $g5kApiRoot, $currentSite, $currentJobId) -Credential $Credential | ConvertTo-OarJobObject
            }
        }
    }
    end {}
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
        [Parameter()][ValidateSet("default", "production", "admin", "besteffort")][string]$Queue = "default",
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
New-Alias -Name Start-OarJob -Value New-OarJob
Export-ModuleMember -Alias Start-OarJob

function Wait-OarJob {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)][int[]]$JobId,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        [Parameter()][int]$PollInterval = 60,
        [Parameter()][string[]]$UntilState = @("error", "terminated")
    )
    if ($PSBoundParameters.Site -and ($Site.Count -ne $JobId.Count -and $Site.Count -ne 1)) {
        throw [System.ArgumentException]::new("You can only specify one site per job ID")
    }
    elseif (!$Site.Count) {
        $Site = @(Get-G5KCurrentSite)
    }
    if ($JobId.Count -gt 10) {
        Write-Warning "Too many jobs, be careful of overusing the Grid'5000 API!"
        if (!$PSBoundParameters.PollInterval) {
            Write-Warning "Increasing poll interval to 300 seconds"
            $PollInterval = 300
        }
    }
    $towait = 0..($JobId.Count - 1) | ForEach-Object {
        if ($Site.Count -eq 1) {
            $currentSite = $Site[0]
        }
        else {
            $currentSite = $Site[$_]
        }
        [pscustomobject]@{
            JobId = $JobId[$_];
            Site  = $currentSite;
        }
    }
    while ($towait.Count) {
        $pct = 100.0 * $towait.Count / $JobId.Count
        Write-Progress -Activity "Waiting for $($towait.Count) remaining jobs..." -PercentComplete $pct
        $towait = $towait | Get-OarJob | Where-Object state -NotIn $UntilState
        Start-Sleep -Seconds $PollInterval
    }
}
Export-ModuleMember -Function Wait-OarJob

function Remove-OarJob {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][int[]]$JobId,
        [Parameter(ParameterSetName = "Id", ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        [Parameter()][pscredential]$Credential,
        [Parameter()][switch]$AsJob,
        [Parameter()][switch]$PassThru
    )
    begin {
        if ($PSBoundParameters.Site -and ($Site.Count -ne $JobId.Count -and $Site.Count -ne 1)) {
            throw [System.ArgumentException]::new("You can only specify one site per job ID")
        }
        elseif (!$Site.Count) {
            $Site = @(Get-G5KCurrentSite)
        }
    }
    process {
        for ($i = 0; $i -lt $JobId.Count; $i++) {
            $currentJobId = $JobId[$i]
            if ($Site.Count -eq 1) {
                $currentSite = $Site[0]
            }
            else {
                $currentSite = $Site[$i]
            }
            if ($PSCmdlet.ShouldProcess("job '{0}', site '{1}'" -f @($currentJobId, $currentSite), "Remove-OarJob")) {
                $resp = Invoke-RestMethod -Method Delete -Uri ("{0}/3.0/sites/{1}/jobs/{2}" -f $g5kApiRoot, $currentSite, $currentJobId) -Credential $Credential
                if ($AsJob) {
                    Start-Job -ArgumentList @($currentSite, $currentJobId) -ScriptBlock {
                        param($currentSite, $currentJobId)
                        Import-Module gridshell | Write-Verbose
                        Wait-OarJob -JobId $currentJobId -Site $currentSite
                    }
                }
                elseif ($PassThru) {
                    Get-OarJob -JobId $currentJobId -Site $currentSite
                }
                else {
                    $resp
                }
            }
        }
    }
    end {}
}
Export-ModuleMember -Function Remove-OarJob
New-Alias -Name Stop-OarJob -Value Remove-OarJob
Export-ModuleMember -Alias Stop-OarJob
