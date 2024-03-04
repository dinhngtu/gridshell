class G5KSelectorAnd : System.Collections.Generic.List[object] {
    [string] ToString() {
        if ($this.Count -eq 1) {
            return $this[0]
        }
        else {
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
}

class G5KSelectorOr : System.Collections.Generic.List[object] {
    [string] ToString() {
        if ($this.Count -eq 1) {
            return $this[0]
        }
        else {
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
}

function Select-OarNode {
    <#
    .SYNOPSIS
        Create or extend an OAR resource selector using the given specifiers.
    #>
    [CmdletBinding()]
    param(
        # Specify a resource selector to combine with.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "IntersectAll")]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "IntersectAny")]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "UnionAll")]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "UnionAny")]
        [object]
        $Selector,
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
        # The minimum rate of the connected Infiniband interface in Gbps.
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
        # Node has virtualization capacity.
        [Parameter()][switch]$HasVirtual,

        # The full hostname of the node the resource is part of.
        [Parameter()][string]$HostName,

        # Resource has 'atypical' hardware (such as non-x86_64 CPU architecture for example).
        [Parameter()][Alias("IsExotic")][switch]$Exotic,
        # Node state.
        [Parameter()][ArgumentCompletions("Absent", "Alive", "Dead")][string]$State,
        # Node is alive.
        [Parameter()][switch]$IsAlive,
        # The type of wattmeter available.
        [Parameter()][Alias("HasWattmeter")][switch]$Wattmeter,

        # Additional specifiers to include.
        [Parameter()][string[]]$Filters,
        # List resources belonging to this selector with `oarnodes`.
        [Parameter()][switch]$List
    )

    if ($Any) {
        $sel = [G5KSelectorOr]::new()
    }
    else {
        $sel = [G5KSelectorAnd]::new()
    }

    if ($null -ne $MinCoreCount) {
        $sel.Add("(core_count>=$MinCoreCount)")
    }
    if ($null -ne $MinCpuCount) {
        $sel.Add("(cpu_count>=$MinCpuCount)")
    }
    if (![string]::IsNullOrEmpty($CpuArch)) {
        $sel.Add("(lower(cpuarch) like lower('$CpuArch'))")
    }
    if ($null -ne $MinCorePerCpu) {
        $sel.Add("(cpucore>=$MinCorePerCpu)")
    }
    if ($null -ne $MinCpuFreq) {
        $sel.Add("(cpufreq>=$MinCpuFreq)")
    }
    if (![string]::IsNullOrEmpty($CpuType)) {
        $sel.Add("(lower(cputype) like lower('$CpuType'))")
    }
    if ($null -ne $MinDiskReservationCount) {
        $sel.Add("(disk_reservation_count>=$MinDiskReservationCount)")
    }
    if (![string]::IsNullOrEmpty($DiskType)) {
        $sel.Add("(lower(disktype) like lower('$DiskType'))")
    }
    elseif ($HasSsd) {
        $sel.Add("(lower(disktype) like '%/ssd')")
    }
    elseif ($PSBoundParameters.ContainsKey("HasSsd")) {
        $sel.Add("(lower(disktype) not like '%/ssd')")
    }
    if ($null -ne $MinEthCount) {
        $sel.Add("(eth_count>=$MinEthCount)")
    }
    if ($null -ne $MinEthKavlanCount) {
        $sel.Add("(eth_kavlan_count>=$MinEthKavlanCount)")
    }
    if ($null -ne $MinEthRate) {
        $sel.Add("(eth_rate>=$MinEthRate)")
    }
    if ($null -ne $MinGpuCount) {
        $sel.Add("(gpu_count>=$MinGpuCount)")
    }
    if (![string]::IsNullOrEmpty($GpuModel)) {
        $sel.Add("(lower(gpu_model) like lower('$GpuModel'))")
    }
    if (![string]::IsNullOrEmpty($Infiniband)) {
        $sel.Add("(lower(ib) like lower('$Infiniband'))")
    }
    elseif ($HasInfiniband) {
        $sel.Add("(ib<>'NO')")
    }
    elseif ($PSBoundParameters.ContainsKey("HasInfiniband")) {
        $sel.Add("(ib='NO')")
    }
    if ($null -ne $MinInfinibandCount) {
        $sel.Add("(ib_count>=$MinInfinibandCount)")
    }
    if ($null -ne $MinInfinibandRate) {
        $sel.Add("(ib_rate>=$MinInfinibandRate)")
    }
    if ($null -ne $MinMemPerCore) {
        $sel.Add("(memcore>=$MinMemPerCore)")
    }
    if ($null -ne $MinMemPerCpu) {
        $sel.Add("(memcpu>=$MinMemPerCpu)")
    }
    if ($null -ne $MinMemPerNode) {
        $sel.Add("(memnode>=$MinMemPerNode)")
    }
    if (![string]::IsNullOrEmpty($Mic)) {
        $sel.Add("(lower(mic) like lower('$Mic'))")
    }
    if ($null -ne $MinOpaCount) {
        $sel.Add("(opa_count>=$MinOpaCount)")
    }
    if ($null -ne $MinOpaRate) {
        $sel.Add("(opa_rate>=$MinOpaRate)")
    }
    if ($null -ne $MinThreadCount) {
        $sel.Add("(thread_count>=$MinThreadCount)")
    }
    if (![string]::IsNullOrEmpty($Virtual)) {
        $sel.Add("(lower(virtual) like lower('$Virtual'))")
    }
    elseif ($HasVirtual) {
        $sel.Add("(virtual<>'NO')")
    }
    elseif ($PSBoundParameters.ContainsKey("HasVirtual")) {
        $sel.Add("(virtual='NO')")
    }

    if (![string]::IsNullOrEmpty($HostName)) {
        $sel.Add("(lower(host) like lower('$HostName'))")
    }

    if ($Exotic) {
        $sel.Add("(exotic<>'NO')")
    }
    elseif ($PSBoundParameters.ContainsKey("Exotic")) {
        $sel.Add("(exotic='NO')")
    }
    if (![string]::IsNullOrEmpty($State)) {
        $sel.Add("(lower(state) like lower('$State'))")
    }
    elseif ($IsAlive) {
        $sel.Add("(state<>'Dead')")
    }
    elseif ($PSBoundParameters.ContainsKey("IsAlive")) {
        $sel.Add("(state='Dead')")
    }
    if ($Wattmeter) {
        $sel.Add("(wattmeter<>'NO')")
    }
    elseif ($PSBoundParameters.ContainsKey("Wattmeter")) {
        $sel.Add("(wattmeter='NO')")
    }

    foreach ($e in $Filters) {
        $sel.Add("($e)")
    }
    if ($null -ne $Selector) {
        if ($Union -and $Any) {
            foreach ($e in $Selector) {
                $sel.Add($e)
            }
        }
        elseif ($Union) {
            # implied -All
            $parent = [G5KSelectorOr]::new()
            $parent.Add($Selector)
            $parent.Add($sel)
            $sel = $parent
        }
        elseif ($Any) {
            # implied -Intersect
            $parent = [G5KSelectorAnd]::new()
            $parent.Add($Selector)
            $parent.Add($sel)
            $sel = $parent
        }
        else {
            # default (-Intersect -All)
            foreach ($e in $Selector) {
                $sel.Add($e)
            }
        }
    }

    if ($List) {
        Write-Information "Filter: $($sel.ToString())" -InformationAction Continue
        oarnodes -J --sql $sel.ToString() | jq '[.[].host]|unique'
    }
    else {
        [PSCustomObject]@{
            Selector       = $sel;
            SelectorString = $sel.ToString()
        }
    }
}
Export-ModuleMember -Function Select-OarNode
