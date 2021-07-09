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
        nodes      = $Nodes.Count -gt 0 ? ($Nodes -join ",") : "";
        start_time = $StartTime ? $StartTime.ToString("s") : "";
        end_time   = $EndTime ? $EndTime.ToString("s") : "";
        job_id     = $PSBoundParameters.ContainsKey("JobId") ? $JobId : "";
        metrics    = $Metrics.Count -gt 0 ? ($Metrics -join ",") : "";
        summary    = !!$Summary;
    }
    return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/metrics" -f $g5kApiRoot, $Site) -Credential $Credential -Body $params -OutFile $OutFile
}
Export-ModuleMember -Function Get-KwollectMetrics
