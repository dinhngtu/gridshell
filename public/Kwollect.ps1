function Get-KwollectMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidatePattern("\w*")]$Site,
        [Parameter()][string[]]$Nodes,
        [Parameter()][System.Nullable[datetime]]$StartTime,
        [Parameter()][System.Nullable[datetime]]$EndTime,
        [Parameter()][int]$JobId,
        [Parameter()][string[]]$Metrics,
        [Parameter()][string]$OutFile,
        [Parameter()][pscredential]$Credential
    )
    $params = Remove-EmptyValues @{
        nodes      = $Nodes.Count -gt 0 ? ($Nodes -join ",") : "";
        start_time = $StartTime ? $StartTime.ToString("s") : "";
        end_time   = $EndTime ? $EndTime.ToString("s") : "";
        job_id     = $PSBoundParameters.ContainsKey("JobId") ? $JobId : "";
        metrics    = $Metrics.Count -gt 0 ? ($Metrics -join ",") : "";
    }
    return Invoke-RestMethod -Uri ("{0}/sid/sites/{1}/metrics" -f $g5kApiRoot, $Site) -Credential $Credential -Body $params -OutFile $OutFile
}
Export-ModuleMember -Function Get-KwollectMetrics
