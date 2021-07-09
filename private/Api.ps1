$defaultG5KApiRoot = "https://api.grid5000.fr"
$script:g5kApiRoot = $defaultG5KApiRoot

function Get-G5KApiRoot {
    [CmdletBinding()]
    param()
    return $script:g5kApiRoot
}
Export-ModuleMember -Function Get-G5KApiRoot

function Set-G5KApiRoot {
    [CmdletBinding(DefaultParameterSetName = "Value")]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Value")][ValidateNotNullOrEmpty()][string]$Value,
        [Parameter(Mandatory, ParameterSetName = "Default")][switch]$Default
    )
    if ($Default) {
        $Value = $defaultG5KApiRoot
    }
    $script:g5kApiRoot = $Value
}
Export-ModuleMember -Function Set-G5KApiRoot
