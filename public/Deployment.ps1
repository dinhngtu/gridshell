# SPDX-License-Identifier: GPL-3.0-only

function Get-KaEnvironment {
    [CmdletBinding(DefaultParameterSetName = "List")]
    param(
        [Parameter()][ValidatePattern("\w*")]$Site,
        [Parameter(Mandatory, ParameterSetName = "Get")][string]$Uid,
        [Parameter(ParameterSetName = "List")][switch]$AllVersions,
        [Parameter(ParameterSetName = "List")][string]$User,
        [Parameter(ParameterSetName = "List")][string]$Architecture,
        [Parameter(ParameterSetName = "List", Position = 0)][string]$Name,
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    if ($PSCmdlet.ParameterSetName -eq "Get") {
        return Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/environments/{2}" -f $script:g5kApiRoot, $Site, $Uid) -Credential $Credential
    }
    elseif ($PSCmdlet.ParameterSetName -eq "List") {
        $params = Remove-EmptyValues @{
            name         = $Name;
            architecture = $Architecture;
            user         = $User;
            latest_only  = if ($AllVersions) { "no" } else { "yes" };
        }
        return (Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/environments" -f $script:g5kApiRoot, $Site) -Credential $Credential -Body $params).items
    }
}
Export-ModuleMember -Function Get-KaEnvironment

function Get-KaDeployment {
    [CmdletBinding(DefaultParameterSetName = "Query")]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][string[]]$DeploymentId,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        [Parameter()][ValidateRange(0, 999999999)][int]$Offset = 0,
        [Parameter()][ValidateRange(1, 500)][int]$Limit = 50,
        [Parameter()][Alias("State")][ValidateSet("waiting", "processing", "canceled", "terminated", "error", "*")][string[]]$Status = @("waiting", "processing"),
        [Parameter()][ValidatePattern("\w*")][string]$User = $((Get-G5KCurrentUser).uid),
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
            if ("*" -in $Status) {
                $Status = @()
            }
            $params = Remove-EmptyValues @{
                offset = $Offset;
                limit  = $Limit;
                status = $Status -join ",";
                user   = $User;
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq "Id") {
            if ($PSBoundParameters.Site -and $Site.Count -ne $DeploymentId.Count -and $Site.Count -ne 1) {
                throw [System.ArgumentException]::new("You can only specify one site per job ID")
            }
        }
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq "Query") {
            return (Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/deployments" -f $script:g5kApiRoot, $Site[0]) -Credential $Credential -Body $params).items | ConvertTo-KaDeployment
        }
        else {
            for ($i = 0; $i -lt $DeploymentId.Count; $i++) {
                $currentJobId = $DeploymentId[$i]
                if ($Site.Count -eq 1) {
                    $currentSite = $Site[0]
                }
                else {
                    $currentSite = $Site[$i]
                }
                Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/deployments/{2}" -f $script:g5kApiRoot, $currentSite, $currentJobId) -Credential $Credential | ConvertTo-KaDeployment
            }
        }
    }
    end {}
}
Export-ModuleMember -Function Get-KaDeployment

function Start-KaDeployment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()][ValidatePattern("\w*")]$Site,
        [Parameter(Mandatory)][string[]]$Nodes,
        [Parameter(Mandatory, ParameterSetName = "EnvironmentName")][string]$EnvironmentName,
        [Parameter(ParameterSetName = "EnvironmentName")][int]$EnvironmentVersion,
        [Parameter(Mandatory, ParameterSetName = "EnvironmentObject")]$Environment,
        [Parameter()][string]$AuthorizedKeys = $((Get-G5KUser).key),
        [Parameter()][string]$BlockDevice,
        [Parameter()][System.Nullable[int]]$PartitionNumber,
        [Parameter()][System.Nullable[int]]$Vlan,
        [Parameter()][string]$TmpFilesystemType,
        [Parameter()][switch]$DisableDiskPartitioning,
        [Parameter()][switch]$DisableBootloaderInstall,
        [Parameter()][switch]$IgnoreNodesDeploying,
        [Parameter()][System.Nullable[int]]$RebootClassicalTimeout,
        [Parameter()][System.Nullable[int]]$RebootKexecTimeout,
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    if ($PSCmdlet.ParameterSetName -eq "EnvironmentObject") {
        $EnvironmentName = $Environment.name
        $EnvironmentVersion = $Environment.version
    }
    $params = Remove-EmptyValues @{
        nodes                      = $Nodes;
        environment                = $EnvironmentName;
        key                        = $AuthorizedKeys;
        version                    = $EnvironmentVersion;
        block_device               = $BlockDevice;
        partition_number           = $PartitionNumber;
        vlan                       = $Vlan;
        reformat_tmp               = $TmpFilesystemType;
        disable_disk_partitioning  = !!$DisableDiskPartitioning;
        disable_bootloader_install = !!$DisableBootloaderInstall;
        ignore_nodes_deploying     = !!$IgnoreNodesDeploying;
        reboot_classical_timeout   = $RebootClassicalTimeout;
        reboot_kexec_timeout       = $RebootKexecTimeout;
    }
    $params | Out-String | Write-Verbose
    if ($PSCmdlet.ShouldProcess(("environment '{0}' version {1} on {2} nodes" -f $EnvironmentName, $EnvironmentVersion, $Nodes.Count), "Start-KaDeployment")) {
        return Invoke-RestMethod -Method Post -Uri ("{0}/3.0/sites/{1}/deployments" -f $script:g5kApiRoot, $Site) -Credential $Credential -Body (ConvertTo-Json -InputObject $params) -ContentType "application/json"
    }
}
Export-ModuleMember -Function Start-KaDeployment
New-Alias -Name New-KaDeployment -Value Start-KaDeployment
Export-ModuleMember -Alias New-KaDeployment

function Wait-KaDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)][string[]]$DeploymentId,
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        [Parameter()][int]$Interval = 60,
        [Parameter()][ValidateSet("waiting", "processing", "canceled", "terminated", "error")][string[]]$Until = @("canceled", "terminated", "error"),
        [Parameter()][pscredential]$Credential
    )
    begin {
        $towait = [System.Collections.Generic.List[object]]::new()
        if (!$Site.Count) {
            $Site = @(Get-G5KCurrentSite)
        }
    }
    process {
        if ($PSBoundParameters.Site -and ($Site.Count -ne $DeploymentId.Count -and $Site.Count -ne 1)) {
            throw [System.ArgumentException]::new("You can only specify one site per job ID")
        }
        0..($DeploymentId.Count - 1) | ForEach-Object {
            if ($Site.Count -eq 1) {
                $currentSite = $Site[0]
            }
            else {
                $currentSite = $Site[$_]
            }
            $job = [pscustomobject]@{
                DeploymentId = $DeploymentId[$_];
                Site         = $currentSite;
            }
            $towait.Add($job)
        }
    }
    end {
        $towait = $towait | Get-KaDeployment -Credential $Credential | Where-Object status -NotIn $Until
        $totalCount = $towait.Count
        if ($towait.Count -gt 10) {
            Write-Warning "Too many jobs, be careful of overusing the Grid'5000 API!"
            if (!$PSBoundParameters.Interval) {
                Write-Warning "Increasing poll interval to 300 seconds"
                $Interval = 300
            }
        }

        while ($towait.Count) {
            $doneCount = $totalCount - $towait.Count
            $breakdown = $towait | `
                Group-Object -Property status | `
                ForEach-Object { "$($_.Count) $($_.Name)" } | `
                Join-String -Separator ', '

            $pct = [int][System.Math]::Floor(100.0 * $doneCount / $totalCount)
            if ($pct -eq 0) {
                $pct = 1
            }
            Write-Progress `
                -Activity "Waiting for deployments..." `
                -Status "$doneCount of $totalCount deployments completed ($breakdown)." `
                -PercentComplete $pct

            Start-Sleep -Seconds $Interval

            $towait = $towait | Get-KaDeployment -Credential $Credential | Where-Object status -NotIn $Until
        }
    }
}
Export-ModuleMember -Function Wait-KaDeployment

function Stop-KaDeployment {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][int[]]$DeploymentId,
        [Parameter(ParameterSetName = "Id", ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        [Parameter()][pscredential]$Credential,
        [Parameter()][switch]$PassThru
    )
    begin {
        if ($PSBoundParameters.Site -and ($Site.Count -ne $DeploymentId.Count -and $Site.Count -ne 1)) {
            throw [System.ArgumentException]::new("You can only specify one site per job ID")
        }
        elseif (!$Site.Count) {
            $Site = @(Get-G5KCurrentSite)
        }
    }
    process {
        for ($i = 0; $i -lt $DeploymentId.Count; $i++) {
            $currentJobId = $DeploymentId[$i]
            if ($Site.Count -eq 1) {
                $currentSite = $Site[0]
            }
            else {
                $currentSite = $Site[$i]
            }
            if ($PSCmdlet.ShouldProcess("deployment '{0}', site '{1}'" -f @($currentJobId, $currentSite), "Stop-KaDeployment")) {
                $resp = Invoke-RestMethod -Method Delete -Uri ("{0}/3.0/sites/{1}/deployments/{2}" -f $script:g5kApiRoot, $currentSite, $currentJobId) -Credential $Credential
                if ($PassThru) {
                    Get-KaDeployment -DeploymentId $currentJobId -Site $currentSite
                }
                else {
                    $resp
                }
            }
        }
    }
    end {}
}
Export-ModuleMember -Function Stop-KaDeployment
New-Alias -Name Remove-KaDeployment -Value Stop-KaDeployment
Export-ModuleMember -Alias Remove-KaDeployment
