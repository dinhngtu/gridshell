# SPDX-License-Identifier: GPL-3.0-only

function Remove-EmptyValues {
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)][ValidateNotNull()][System.Collections.IDictionary]$InputObject
    )
    $ret = @{}
    foreach ($kv in $InputObject.GetEnumerator()) {
        if (![string]::IsNullOrEmpty($kv.Value -as [string])) {
            $ret.Add($kv.Key, $kv.Value)
        }
    }
    return $ret
}
