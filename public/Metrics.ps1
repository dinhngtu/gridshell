# SPDX-License-Identifier: GPL-3.0-only

function Get-KwollectMetrics {
    [CmdletBinding()]
    param(
        [Parameter()][ValidatePattern("\w*")]$Site,
        [Parameter()][string[]]$Nodes,
        [Parameter()][System.Nullable[datetime]]$StartTime,
        [Parameter()][System.Nullable[datetime]]$EndTime,
        [Parameter()][int]$JobId,
        [Parameter()][string[]]$Metrics,
        [Parameter()][switch]$Summary,
        [Parameter()][string]$OutFile,
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
