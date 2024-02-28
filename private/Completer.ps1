$completionCacheCluster = @{}

function Get-GridshellClusterCompletion {
    param(
        [string]$CommandName,
        [string]$ParameterName,
        [string]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )
    $site = $null
    if ($FakeBoundParameters.ContainsKey('Site')) {
        $site = $FakeBoundParameters.Site
    }
    else {
        $site = Get-GridshellCurrentSite
    }
    if (!$completionCacheCluster.ContainsKey($site)) {
        $completionCacheCluster[$site] = Get-OarCluster -Site $site | Select-Object -ExpandProperty Cluster
    }

    $completionCacheCluster[$site] | Where-Object {
        $_ -like "$WordToComplete*"
    }
}
Export-ModuleMember -Function Get-GridshellClusterCompletion
