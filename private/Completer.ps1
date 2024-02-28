$completionCacheCluster = @{}

function Get-G5KClusterCompletion {
    [OutputType([System.Management.Automation.CompletionResult])]
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
        $site = Get-G5KCurrentSite
    }
    if (!$completionCacheCluster.ContainsKey($site)) {
        $completionCacheCluster[$site] = Get-OarCluster -Site $site | Select-Object -ExpandProperty Cluster
    }

    $CompletionResults = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
    $completionCacheCluster[$site] | Where-Object {
        $_ -like "$WordToComplete*"
    } | ForEach-Object {
        $CompletionResults.Add($_)
    }
    return $CompletionResults
}
