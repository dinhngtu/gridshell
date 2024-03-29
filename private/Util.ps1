# SPDX-License-Identifier: GPL-3.0-only

function Remove-EmptyValues {
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)][ValidateNotNull()][System.Collections.IDictionary]$InputObject
    )
    $ret = @{}
    foreach ($kv in $InputObject.GetEnumerator()) {
        if ($null -ne $kv.Value -and ![string]::IsNullOrEmpty($kv.Value -as [string])) {
            $ret.Add($kv.Key, $kv.Value)
        }
    }
    return $ret
}

function Format-G5KDate {
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)][datetime]$InputObject
    )
    return $InputObject.ToUniversalTime().ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss", [System.Globalization.DateTimeFormatInfo]::InvariantInfo)
}

function Split-PropertyKey {
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)][ValidateNotNull()][pscustomobject]$InputObject,
        [string]$KeyName = "Name"
    )
    foreach ($n in ($InputObject.PSObject.Properties | Where-Object MemberType -eq NoteProperty)) {
        $p = $n.Value
        $p.PSObject.Properties.Add((New-Object psnoteproperty($KeyName, $n.Name)))
        $p
    }
}
