class G5KSelectorAnd : System.Collections.Generic.List[object] {
    [string] ToString() {
        $tokens = [System.Collections.Generic.List[string]]::new()
        foreach ($el in $this) {
            $tokens.Add($el.ToString());
            $tokens.Add("and");
        }
        if ($tokens.Count -gt 0) {
            $tokens.RemoveAt($tokens.Count - 1)
        }
        return "(" + (-join $tokens) + ")"
    }
}

class G5KSelectorOr : System.Collections.Generic.List[object] {
    [string] ToString() {
        $tokens = [System.Collections.Generic.List[string]]::new()
        foreach ($el in $this) {
            $tokens.Add($el.ToString());
            $tokens.Add("or");
        }
        if ($tokens.Count -gt 0) {
            $tokens.RemoveAt($tokens.Count - 1)
        }
        return "(" + (-join $tokens) + ")"
    }
}

function Select-OarNode {
    <#
    .SYNOPSIS
        Create or extend an OAR resource selector using a list of specifiers.
    #>
    [CmdletBinding()]
    param(
        # Specify a resource selector to combine with.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "IntersectAll")]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "IntersectAny")]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "UnionAll")]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "UnionAny")]
        [object]
        $Expression,
        # Resource must match both this selector and the combined selector.
        [Parameter(ParameterSetName = "IntersectAll")]
        [Parameter(ParameterSetName = "IntersectAny")]
        [switch]
        $Intersect,
        # Resource must match either this selector or the combined selector.
        [Parameter(Mandatory, ParameterSetName = "UnionAll")]
        [Parameter(Mandatory, ParameterSetName = "UnionAny")]
        [switch]
        $Union,
        # Match all specifiers of this selector.
        [Parameter(ParameterSetName = "All")]
        [Parameter(ParameterSetName = "IntersectAll")]
        [Parameter(ParameterSetName = "UnionAll")]
        [switch]
        $All,
        # Match any specifier of this selector.
        [Parameter(Mandatory, ParameterSetName = "Any")]
        [Parameter(Mandatory, ParameterSetName = "IntersectAny")]
        [Parameter(Mandatory, ParameterSetName = "UnionAny")]
        [switch]
        $Any,

        # The minimum number of CPU cores the node has.
        [Parameter()][System.Nullable[int]]$MinCoreCount,
        # The minimum number of CPUs (sockets) the node has.
        [Parameter()][System.Nullable[int]]$MinCpuCount,
        # What CPU architecture resource's CPU is member of?
        [Parameter()][ArgumentCompletions("aarch64", "ppc64le", "x86_64")][string]$CpuArch,
        # The minimum number of core per CPU.
        [Parameter()][System.Nullable[int]]$MinCorePerCpu,
        # The minimum frequency in GHz of resource's CPU.
        [Parameter()][System.Nullable[float]]$MinCpuFreq,
        # What processor's family resource's CPU is member of.
        [Parameter()][string]$CpuType,
        # The minimum number of reservable disks.
        [Parameter()][System.Nullable[int]]$MinDiskReservationCount,
        # The node's primary disk interface and storage type (like SATA/SSD).
        [Parameter()][ArgumentCompletions("HDD/HDD", "NVME/SSD", "RAID-0 (1 disk)/HDD", "RAID-0 (2 disks)/HDD", "RAID-1 (2 disks)/HDD", "RAID/HDD", "SAS/HDD", "SAS/SSD", "SATA/HDD", "SATA/SSD", "SCSI/HDD")][string]$DiskType,
        # Node has an SSD.
        [Parameter()][switch]$HasSsd,
        # The minimum number of Ethernet interface the node has.
        [Parameter()][System.Nullable[int]]$MinEthCount,
        # The minimum number of Ethernet interface with KaVLAN support the node has.
        [Parameter()][System.Nullable[int]]$MinEthKavlanCount,
        # The (minimum) maximum rate of connected network interfaces in Gbps.
        [Parameter()][System.Nullable[int]]$MinEthRate,
        # The minimum number of GPU cards available.
        [Parameter()][System.Nullable[int]]$MinGpuCount,
        # The type of GPU available.
        [Parameter()][string]$GpuModel,
        # The technology of the Infiniband interface.
        [Parameter()][ArgumentCompletions("EDR", "NO", "QDR")][string]$Infiniband,
        # Node has an Infiniband interface.
        [Parameter()][switch]$HasInfiniband,
        # The minimum number of Infiniband interfaces available.
        [Parameter()][System.Nullable[int]]$MinInfinibandCount,
        # The minimum rate of the connected Infiniband interface in Gbps
        [Parameter()][System.Nullable[int]]$MinInfinibandRate,
        # The minimum amount of memory in MB per CPU core.
        [Parameter()][System.Nullable[int]]$MinMemPerCore,
        # The minimum amount of memory in MB per CPU.
        [Parameter()][System.Nullable[int]]$MinMemPerCpu,
        # The minimum total amount of memory in MB of the node.
        [Parameter()][System.Nullable[int]]$MinMemPerNode,
        # Intel many integrated core architecture support.
        [Parameter()][string]$Mic,
        # The minimum number of Omni-Path interfaces available.
        [Parameter()][System.Nullable[int]]$MinOpaCount,
        # The minimum rate of the connected Omni-Path interface in Gbps.
        [Parameter()][System.Nullable[int]]$MinOpaRate,
        # The minimum total number of CPU threads the node has.
        [Parameter()][System.Nullable[int]]$MinThreadCount,
        # Node virtualization capacity.
        [Parameter()][ArgumentCompletions("NO", "amd-v", "arm64", "ivt")][string]$Virtual,
        # Node has virtualization capacity
        [Parameter()][switch]$HasVirtual,

        # Resource has 'atypical' hardware (such as non-x86_64 CPU architecture for example).
        [Parameter()][switch]$Exotic,
        # Node state.
        [Parameter()][ArgumentCompletions("Absent", "Alive", "Dead")][string]$State,
        # Node is alive.
        [Parameter()][switch]$IsAlive,
        # The full hostname of the node the resource is part of.
        [Parameter()][string]$HostName,

        # Custom specifiers to include.
        [Parameter()][string[]]$CustomExpressions,
        # List resources belonging to this selector with `oarnodes`.
        [Parameter()][switch]$List
    )

    if ($Any) {
        $expr = [G5KSelectorOr]::new()
    }
    else {
        $expr = [G5KSelectorAnd]::new()
    }

    if ($null -ne $MinCoreCount) {
        $expr.Add("(core_count>$MinCoreCount)")
    }
    if ($null -ne $MinCpuCount) {
        $expr.Add("(cpu_count>$MinCpuCount)")
    }
    if (![string]::IsNullOrEmpty($CpuArch)) {
        $expr.Add("(lower(cpuarch) like lower('$CpuArch'))")
    }
    if ($null -ne $MinCorePerCpu) {
        $expr.Add("(cpucore>$MinCorePerCpu)")
    }
    if ($null -ne $MinCpuFreq) {
        $expr.Add("(cpufreq>$MinCpuFreq)")
    }
    if (![string]::IsNullOrEmpty($CpuType)) {
        $expr.Add("(lower(cputype) like lower('$CpuType'))")
    }
    if ($null -ne $MinDiskReservationCount) {
        $expr.Add("(disk_reservation_count>$MinDiskReservationCount)")
    }
    if (![string]::IsNullOrEmpty($DiskType)) {
        $expr.Add("(lower(disktype) like lower('$DiskType'))")
    }
    elseif ($HasSsd) {
        $expr.Add("(lower(disktype) like '%/ssd')")
    }
    if ($null -ne $MinEthCount) {
        $expr.Add("(eth_count>$MinEthCount)")
    }
    if ($null -ne $MinEthKavlanCount) {
        $expr.Add("(eth_kavlan_count>$MinEthKavlanCount)")
    }
    if ($null -ne $MinEthRate) {
        $expr.Add("(eth_rate>$MinEthRate)")
    }
    if ($null -ne $MinGpuCount) {
        $expr.Add("(gpu_count>$MinGpuCount)")
    }
    if (![string]::IsNullOrEmpty($GpuModel)) {
        $expr.Add("(lower(gpu_model) like lower('$GpuModel'))")
    }
    if (![string]::IsNullOrEmpty($Infiniband)) {
        $expr.Add("(lower(ib) like lower('$Infiniband'))")
    }
    elseif ($HasInfiniband) {
        $expr.Add("(ib<>'NO')")
    }
    if ($null -ne $MinInfinibandCount) {
        $expr.Add("(ib_count>$MinInfinibandCount)")
    }
    if ($null -ne $MinInfinibandRate) {
        $expr.Add("(ib_rate>$MinInfinibandRate)")
    }
    if ($null -ne $MinMemPerCore) {
        $expr.Add("(memcore>$MinMemPerCore)")
    }
    if ($null -ne $MinMemPerCpu) {
        $expr.Add("(memcpu>$MinMemPerCpu)")
    }
    if ($null -ne $MinMemPerNode) {
        $expr.Add("(memnode>$MinMemPerNode)")
    }
    if (![string]::IsNullOrEmpty($Mic)) {
        $expr.Add("(lower(mic) like lower('$Mic'))")
    }
    if ($null -ne $MinOpaCount) {
        $expr.Add("(opa_count>$MinOpaCount)")
    }
    if ($null -ne $MinOpaRate) {
        $expr.Add("(opa_rate>$MinOpaRate)")
    }
    if ($null -ne $MinThreadCount) {
        $expr.Add("(thread_count>$MinThreadCount)")
    }
    if (![string]::IsNullOrEmpty($Virtual)) {
        $expr.Add("(lower(virtual) like lower('$Virtual'))")
    }
    elseif ($HasVirtual) {
        $expr.Add("(virtual<>'NO')")
    }

    if ($Exotic) {
        $expr.Add("(exotic<>'NO')")
    }
    if (![string]::IsNullOrEmpty($State)) {
        $expr.Add("(lower(state) like lower('$State'))")
    }
    elseif ($IsAlive) {
        $expr.Add("(state='Alive')")
    }
    # The full hostname of the node the resource is part of.
    if (![string]::IsNullOrEmpty($HostName)) {
        # The full hostname of the node the resource is part of.
        $expr.Add("(lower(host) like lower('$HostName'))")
    }

    foreach ($e in $CustomExpressions) {
        $expr.Add("($e)")
    }
    if ($null -ne $Expression) {
        if ($Union -and $Any) {
            foreach ($e in $Expression) {
                $expr.Add($e)
            }
        }
        elseif ($Union) {
            # implied -All
            $parent = [G5KSelectorOr]::new()
            $parent.Add($Expression)
            $parent.Add($expr)
            $expr = $parent
        }
        elseif ($Any) {
            # implied -Intersect
            $parent = [G5KSelectorAnd]::new()
            $parent.Add($Expression)
            $parent.Add($expr)
            $expr = $parent
        }
        else {
            # default (-Intersect -All)
            foreach ($e in $Expression) {
                $expr.Add($e)
            }
        }
    }

    $ret = [PSCustomObject]@{
        Expression       = $expr;
        ExpressionString = $expr.ToString()
    }
    if ($List) {
        oarnodes -Y --sql $ret.ExpressionString
    }
    else {
        $ret
    }
}
Export-ModuleMember -Function Select-OarNode
