# SPDX-License-Identifier: GPL-3.0-only

function Get-KwollectMetrics {
    # Fetch list of metrics values.
    [CmdletBinding()]
    param(
        # Site's ID.
        [Parameter()][ValidatePattern("\w*")]$Site,
        # List of nodes on which to obtain values.
        [Parameter(ParameterSetName = "WithJobId")]
        [Parameter(Mandatory, ParameterSetName = "WithoutJobId")]
        [string[]]$Nodes,
        # The time from which to obtain the values. By default it is 5 mintues before the current time.
        [Parameter()][System.Nullable[datetime]]$StartTime,
        # The time until which to obtain the values. By default it is the current time.
        [Parameter()][System.Nullable[datetime]]$EndTime,
        # OAR job ID. This parameter is an alternative to the union of parameters Nodes, StartTime and EndTime, as it will use nodes list, start and end time according to job characteristics.
        [Parameter(Mandatory, ParameterSetName = "WithJobId")][int]$JobId,
        # The list of metrics name on which to obtain values (metrics name are described in Reference API). By default all metrics are returned.
        [Parameter()][string[]]$Metrics,
        # Return a summary where metrics values are averaged over 5 minutes.
        [Parameter()][switch]$Summary,
        # Specifies the path to the metric output file.
        [Parameter()][string]$Output,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $params = Remove-EmptyValues @{
        nodes      = if ($Nodes.Count -gt 0) { $Nodes -join "," } else { "" };
        start_time = if ($StartTime) { $StartTime.ToString("s") } else { "" };
        end_time   = if ($EndTime) { $EndTime.ToString("s") } else { "" };
        job_id     = if ($PSBoundParameters.ContainsKey("JobId")) { $JobId } else { "" };
        metrics    = if ($Metrics.Count -gt 0) { $Metrics -join "," } else { "" };
        summary    = !!$Summary;
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/metrics" -f $script:g5kApiRoot, $Site) -Credential $Credential -Body $params -OutFile $OutFile
}
Export-ModuleMember -Function Get-KwollectMetrics
