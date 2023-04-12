# SPDX-License-Identifier: GPL-3.0-only

function Get-KaEnvironment {
    <#
    .SYNOPSIS
        Fetch the list of all the public and authenticated user's environments for site, or a specific environment.
    #>
    [CmdletBinding(DefaultParameterSetName = "List")]
    param(
        # Site's ID.
        [Parameter()][ValidatePattern("\w*")]$Site,
        # ID of environment(s) to fetch.
        [Parameter(Mandatory, ParameterSetName = "Get")][ValidateNotNullOrEmpty()][string]$Uid,
        # Fetch description of all environments versions, instead of the latest only.
        [Parameter(ParameterSetName = "List")][switch]$AllVersions,
        # Fetch environments owned by the specified user.
        [Parameter(ParameterSetName = "List")][string]$User,
        # Fetch environments for a specific CPU architecture.
        [Parameter(ParameterSetName = "List")][string]$Architecture,
        # Fetch environments with the specified name.
        [Parameter(ParameterSetName = "List", Position = 0)][string]$Name,
        # Specifies the path to the environment output file.
        [Parameter()][string]$Output,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential
    )
    if (!$Site) {
        $Site = Get-G5KCurrentSite
    }
    $resp = $null
    if ($PSCmdlet.ParameterSetName -eq "Get") {
        $resp = Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/environments/{2}" -f $script:g5kApiRoot, $Site, $Uid) -Credential $Credential
    }
    elseif ($PSCmdlet.ParameterSetName -eq "List") {
        $params = Remove-EmptyValues @{
            name        = $Name;
            arch        = $Architecture;
            user        = $User;
            latest_only = if ($AllVersions) { "no" } else { "yes" };
        }
        $resp = (Invoke-RestMethod -Uri ("{0}/3.0/sites/{1}/environments" -f $script:g5kApiRoot, $Site) -Credential $Credential -Body $params).items
    }
    if ($Output) {
        if ($resp.Count -gt 1) {
            Write-Warning "Writing multiple environments, output file might not work directly for deployment"
        }
        $resp | Select-Object -ExcludeProperty links | ConvertTo-Yaml > $Output
    }
    else {
        $resp | ConvertTo-KaEnvironment
    }
}
Export-ModuleMember -Function Get-KaEnvironment

function Get-KaDeployment {
    <#
    .SYNOPSIS
        Fetch the list of all the deployments created for site, or a specific deployment.
    #>
    [CmdletBinding(DefaultParameterSetName = "Query")]
    param(
        # ID of deployment to fetch.
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][string[]]$DeploymentId,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        # Paginate through the collection with multiple requests.
        [Parameter()][ValidateRange(0, 999999999)][int]$Offset = 0,
        # Limit the number of items to return.
        [Parameter()][ValidateRange(1, 500)][int]$Limit = 50,
        # Filter the deployment collection with a specific deployment state. Use '*' to specify all states.
        [Parameter()][Alias("State")][ValidateSet("waiting", "processing", "canceled", "terminated", "error", "*", "")][string]$Status = "processing",
        # Filter the deployment collection with a specific deployment owner. Use '*' to specify all users.
        [Parameter()][ValidatePattern("\w*")][string]$User = "~",
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
            if ($Status -eq "*") {
                $Status = ''
            }
            $params = Remove-EmptyValues @{
                offset = $Offset;
                limit  = $Limit;
                status = $Status;
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
    <#
    .SYNOPSIS
        Submit a new deployment (requires a job deploy reservation).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Site's ID.
        [Parameter()][ValidatePattern("\w*")]$Site,
        # An array of nodes FQDN on which you want to deploy the new environment image.
        [Parameter(Mandatory)][string[]]$Nodes,
        # The environment to use, which can be one of the following:
        # - The name of an environment that belongs to you or whose visibility is public (e.g. debian10-x64-base);
        # - The name of an environment that is owned by another user but with visibility set to shared (e.g. env-name@user-uid);
        # - The HTTP or HTTPS URL to a file describing your environment (this has the advantage that you do not need to register it in the kadeploy database).
        [Parameter(Mandatory, ParameterSetName = "EnvironmentName")][ValidateNotNullOrEmpty()][string]$EnvironmentName,
        # Version of the environment to use.
        [Parameter(ParameterSetName = "EnvironmentName")][System.Nullable[int]]$EnvironmentVersion,
        # Specify an environment to use.
        [Parameter(Mandatory, ParameterSetName = "EnvironmentObject")][ValidateNotNull()]$Environment,
        # The content of your SSH public key or authorized_key file OR the HTTP URL to your SSH public key. That key will be dropped in the authorized_keys file of the nodes after deployment, so that you can SSH into them as root.
        [Parameter()][string]$AuthorizedKeys = (Get-Content -Raw "$HOME/.ssh/authorized_keys"),
        # The block device to deploy on.
        [Parameter()][string]$BlockDevice,
        # The partition number to deploy on.
        [Parameter()][System.Nullable[int]]$PartitionNumber,
        # Configure the nodes' vlan.
        [Parameter()][System.Nullable[int]]$Vlan,
        # Reformat the /tmp partition with the given filesystem type.
        [Parameter()][string]$TmpFilesystemType,
        # Disable the disk partioning.
        [Parameter()][switch]$DisableDiskPartitioning,
        # Disable the automatic installation of a bootloader for a Linux based environment.
        [Parameter()][switch]$DisableBootloaderInstall,
        # Don't complain when deploying on nodes tagged as 'currently deploying'.
        [Parameter()][switch]$IgnoreNodesDeploying,
        # Overwrite the default timeout for classical reboots.
        [Parameter()][System.Nullable[int]]$RebootClassicalTimeout,
        # Overwrite the default timeout for kexec reboots.
        [Parameter()][System.Nullable[int]]$RebootKexecTimeout,
        # Specify a user account that has permission to perform this action. The default is the current user.
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
    <#
    .SYNOPSIS
        Wait until a set of deployments reach a certain state.
    #>
    [CmdletBinding()]
    param(
        # ID of deployment(s) to wait for.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)][string[]]$DeploymentId,
        # Site's ID.
        [Parameter(ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        # Status check interval.
        [Parameter()][int]$Interval = 60,
        # Desired state of specified deployments.
        [Parameter()][ValidateSet("waiting", "processing", "canceled", "terminated", "error")][string[]]$Until = @("canceled", "terminated", "error"),
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
    <#
    .SYNOPSIS
        Cancel a deployment.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # ID of deployment(s) to cancel.
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id", ValueFromPipelineByPropertyName)][int[]]$DeploymentId,
        # Site's ID.
        [Parameter(ParameterSetName = "Id", ValueFromPipelineByPropertyName)][ValidatePattern("\w*")][string[]]$Site,
        # Specify a user account that has permission to perform this action. The default is the current user.
        [Parameter()][pscredential]$Credential,
        # Return an object representing the item with which you are working.
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
