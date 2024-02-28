# SPDX-License-Identifier: GPL-3.0-only

function Get-OarJob {
    <#
    .SYNOPSIS
        Fetch the list of all jobs for site, or a specific job. Jobs ordering is by descending date of submission.
    #>
    [CmdletBinding(DefaultParameterSetName = "Query")]
    param(
        # ID of job(s) to fetch.
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][int[]]$JobId,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        [string[]]
        $Site,
        # Get more details (assigned_nodes and resources_by_types) for each job in the list.
        [Parameter()][switch]$Resources,
        # Paginate through the collection with multiple requests.
        [Parameter(ParameterSetName = "Query")][ValidateRange(0, 999999999)][int]$Offset = 0,
        # Limit the number of items to return.
        [Parameter(ParameterSetName = "Query")][ValidateRange(1, 500)][int]$Limit = 50,
        # Filter jobs by state (waiting, launching, running, hold, error, terminated). Use '*' to specify all states.
        [Parameter(ParameterSetName = "Query")][ValidateSet("waiting", "launching", "running", "hold", "error", "terminated", "*")][string[]]$State = @("waiting", "launching", "running", "hold"),
        # Filter jobs in a specific project.
        [Parameter(ParameterSetName = "Query")][ValidatePattern("\w*")][string]$Project,
        # Filter jobs with a specific name.
        [Parameter(ParameterSetName = "Query")][ValidatePattern("\w*")][string]$Name,
        # Filter jobs with a specific owner. Use '*' to specify all users.
        [Parameter(ParameterSetName = "Query")][ValidatePattern("\w*")][string]$User = "~",
        # Filter jobs by queue. Use '*' to specify all queues.
        [Parameter(ParameterSetName = "Query")][ValidateSet("default", "production", "admin", "besteffort", "testing")][string]$Queue,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    begin {
        if (!$PSBoundParameters.Site -and !$Site.Count) {
            $Site = @(Get-G5KCurrentSite)
        }
        if ($User -eq "~") {
            $User = Get-G5KCurrentUser -Credential $Credential -ErrorAction Stop
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
                offset    = $Offset;
                limit     = $Limit;
                state     = $State -join ",";
                project   = $Project;
                user      = $User;
                queue     = $Queue;
                resources = if ($Resources) { "yes" } else { "no" };
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
            return (Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/jobs" -f $script:g5kApiRoot, $Site[0]) -Credential $Credential -Body $params).items | ConvertTo-OarJobObject
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
                Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/jobs/{2}" -f $script:g5kApiRoot, $currentSite, $currentJobId) -Credential $Credential | ConvertTo-OarJobObject
            }
        }
    }
    end {}
}
Export-ModuleMember -Function Get-OarJob

function New-OarJob {
    <#
    .SYNOPSIS
        Submit a new job.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The command to execute when the job starts.
        [Parameter(Mandatory, Position = 0)][ValidateNotNullOrEmpty()][string]$Command,
        # Site's ID.
        [Parameter()]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        [string]
        $Site,
        # A description of the resources you want to book for your job, in OAR format.
        [Parameter()][string]$Resources,
        # The directory in which the command will be launched.
        [Parameter()][string]$Directory = $(Get-Location -PSProvider FileSystem),
        # The path to the file that will contain the STDOUT output of your command.
        [Parameter()][string]$Output,
        # The path to the file that will contain the STDERR output of your command.
        [Parameter()][string]$ErrorOutput,
        # A string containing SQL constraints on the resources (see OAR documentation for more details).
        [Parameter()][string]$Properties,
        # Request that the job starts at a specified time.
        [Parameter()][System.Nullable[datetime]]$Reservation,
        # Request that the job ends at a specified time.
        [Parameter()][System.Nullable[datetime]]$Deadline,
        # Request that the job lasts a specified time.
        [Parameter()][System.Nullable[timespan]]$Duration,
        # An array of job types.
        [Parameter()][ValidateSet("day", "night", "besteffort", "cosystem", "container", "inner", "noop", "allow_classic_ssh", "deploy", "destructive", "exotic")][string[]]$Type = @(),
        # A project name to link your job to, set by default to the default one specified (if so) in UMS (known as GGA).
        [Parameter()][string]$Project,
        # A job name.
        [Parameter()][string]$Name,
        # A job queue.
        [Parameter()][ValidateSet("default", "production", "admin", "besteffort", "testing")][string]$Queue = "default",
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $resv_string = $null
    if ($Reservation -and $Deadline) {
        $resv_string = "{0},{1}" -f (Format-G5KDate $Reservation), (Format-G5KDate $Deadline)
    }
    elseif ($Reservation -and $Duration) {
        $resv_string = "{0},{1}" -f (Format-G5KDate $Reservation), (Format-G5KDate ($Reservation + $Duration))
    }
    elseif ($Reservation -and !$Deadline) {
        $resv_string = Format-G5KDate $Reservation
    }
    elseif (!$Reservation -and $Deadline) {
        $resv_string = "now,{0}" -f (Format-G5KDate $Deadline)
    }
    elseif (!$Reservation -and $Duration) {
        $resv_string = "now,{0}" -f (Format-G5KDate ([datetime]::Now + $Duration))
    }
    $params = Remove-EmptyValues @{
        command     = $Command;
        resources   = $Resources;
        directory   = $Directory;
        stdout      = $Output;
        stderr      = $ErrorOutput;
        properties  = $Properties;
        reservation = $resv_string;
        types       = $Type;
        project     = $Project;
        name        = $Name;
        queue       = $Queue;
    }
    $params | Out-String | Write-Verbose
    if ($PSCmdlet.ShouldProcess(("command '{0}', type '{1}'" -f $Command, $Type -join ","), "New-OarJob")) {
        return Invoke-RestMethod -Method Post -Uri ("{0}/3.0/sites/{1}/jobs/{2}" -f $script:g5kApiRoot, $Site, $Id) -Credential $Credential -Body (ConvertTo-Json -InputObject $params) -ContentType "application/json" | ConvertTo-OarJobObject
    }
}
Export-ModuleMember -Function New-OarJob
New-Alias -Name Start-OarJob -Value New-OarJob
Export-ModuleMember -Alias Start-OarJob

function Wait-OarJob {
    <#
    .SYNOPSIS
        Wait until a set of OAR jobs reach a certain state.
    #>
    [CmdletBinding()]
    param(
        # ID of job(s) to wait for.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)][int[]]$JobId,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        [string[]]
        $Site,
        # Status check interval.
        [Parameter()][int]$Interval = 60,
        # Desired state of specified jobs.
        [Parameter()][ValidateSet("waiting", "launching", "running", "hold", "error", "terminated")][string[]]$Until = @("error", "terminated"),
        # Do not estimate job runtime.
        [Parameter()][switch]$NoEstimate,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    begin {
        $towait = [System.Collections.Generic.List[object]]::new()
        if (!$Site.Count) {
            $Site = @(Get-G5KCurrentSite)
        }
    }
    process {
        if ($PSBoundParameters.Site -and ($Site.Count -ne $JobId.Count -and $Site.Count -ne 1)) {
            throw [System.ArgumentException]::new("You can only specify one site per job ID")
        }
        0..($JobId.Count - 1) | ForEach-Object {
            if ($Site.Count -eq 1) {
                $currentSite = $Site[0]
            }
            else {
                $currentSite = $Site[$_]
            }
            $job = [pscustomobject]@{
                JobId = $JobId[$_];
                Site  = $currentSite;
            }
            $towait.Add($job)
        }
    }
    end {
        $towait = $towait | Get-OarJob -Credential $Credential | Where-Object state -NotIn $Until
        $totalCount = $towait.Count
        if ($towait.Count -gt 10) {
            Write-Warning "Too many jobs, be careful of overusing the Grid'5000 API!"
            if (!$PSBoundParameters.Interval) {
                Write-Warning "Increasing poll interval to 300 seconds"
                $Interval = 300
            }
        }
        $totalWalltime = ($towait | Measure-Object -Sum walltime).Sum
        if (!$totalWalltime) {
            $totalWalltime = 1
        }
        $totalDuration = (New-TimeSpan -Seconds $totalWalltime).ToString()

        while ($towait.Count) {
            $doneCount = $totalCount - $towait.Count
            $breakdown = $towait | `
                Group-Object -Property state | `
                ForEach-Object { "$($_.Count) $($_.Name)" } | `
                Join-String -Separator ', '

            if ($NoEstimate) {
                $pct = [int][System.Math]::Floor(100.0 * $doneCount / $totalCount)
                if ($pct -eq 0) {
                    $pct = 1
                }
                Write-Progress `
                    -Activity "Waiting for jobs..." `
                    -Status "$doneCount of $totalCount jobs completed ($breakdown)." `
                    -PercentComplete $pct
            }
            else {
                $now = [System.DateTimeOffset]::Now.ToUnixTimeSeconds()
                $waits = $towait | ForEach-Object {
                    if ($_.state -In $Until) {
                        0
                    }
                    elseif ($_.started_at -gt 0) {
                        $w = $_.started_at + $_.walltime - $now
                        if ($w -lt 0) {
                            $w = 0
                        }
                        elseif ($w -gt $_.walltime) {
                            $w = $_.walltime
                        }
                        $w
                    }
                    else {
                        $_.walltime
                    }
                } | Measure-Object -Sum -Maximum

                $remainingWalltime = $totalWalltime - $waits.Sum
                $elapsedDuration = (New-TimeSpan -Seconds $remainingWalltime).ToString()
                $timePct = [int][System.Math]::Floor(100.0 * $remainingWalltime / $totalWalltime)
                if ($timePct -eq 0) {
                    $timePct = 1
                }
                Write-Progress `
                    -Activity "Waiting for jobs..." `
                    -Status "$doneCount of $totalCount jobs ($elapsedDuration/$totalDuration) completed ($breakdown)" `
                    -SecondsRemaining $waits.Maximum `
                    -PercentComplete $timePct
            }

            Start-Sleep -Seconds $Interval

            $towait = $towait | Get-OarJob -Credential $Credential | Where-Object state -NotIn $Until
        }
    }
}
Export-ModuleMember -Function Wait-OarJob

function Remove-OarJob {
    <#
    .SYNOPSIS
        Ask for deletion of job.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # ID of job(s) to delete.
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][int[]]$JobId,
        # Site's ID.
        [Parameter(ParameterSetName = "Id", ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        [string[]]
        $Site,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential,
        # Return an object representing the item with which you are working.
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
                $resp = Invoke-RestMethod -Method Delete -Uri ("{0}/3.0/sites/{1}/jobs/{2}" -f $script:g5kApiRoot, $currentSite, $currentJobId) -Credential $Credential
                if ($PassThru) {
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

function Get-OarJobWalltime {
    <#
    .SYNOPSIS
        Fetch walltime change for a specific job.
    #>
    [CmdletBinding()]
    param(
        # ID of job to fetch.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)][int]$JobId,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        [string[]]
        $Site
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/jobs/{2}/walltime" -f $script:g5kApiRoot, $Site, $JobId) -Credential $Credential
}
Export-ModuleMember -Function Get-OarJobWalltime

function Set-OarJobWalltime {
    <#
    .SYNOPSIS
        Submit a job walltime change for a specific job.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # ID of job to fetch.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)][int]$JobId,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern("\w*")]
        [ArgumentCompletions("grenoble", "lille", "luxembourg", "lyon", "nancy", "nantes", "rennes", "sophia", "toulouse")]
        [string[]]
        $Site,
        # The new wanted walltime, format is <[+]new walltime>. If no signed is used, the value is absolute.
        [Parameter(Mandatory)][string]$Walltime,
        # Request walltime increase to be trialed or applied immediately regardless of any otherwise configured delay. Must be authorized in OAR configuration.
        [Parameter()][switch]$Force,
        # Request walltime increase to possibly delay next batch jobs. Must be authorized in OAR configuration.
        [Parameter()][switch]$DelayNextJobs,
        # Request walltime increase to be trialed or applied wholly at once, or not applied otherwise.
        [Parameter()][switch]$Whole,
        # Specify a timeout (in seconds) after which the walltime change request will be aborted if not already accepted by the scheduler. A default timeout could be set in OAR configuration.
        [Parameter()][System.Nullable[int]]$Timeout
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        walltime        = $Walltime;
        force           = !!$Force;
        delay_next_jobs = !!$DelayNextJobs;
        whole           = !!$Whole;
        timeout         = $Timeout;
    }
    if ($PSCmdlet.ShouldProcess("job '{0}', site '{1}', walltime '{2}'" -f @($JobId, $Site, $Walltime), "Set-OarJobWalltime")) {
        return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/jobs/{2}/walltime" -f $script:g5kApiRoot, $Site, $JobId) -Credential $Credential -Body $params
    }
}
Export-ModuleMember -Function Set-OarJobWalltime
