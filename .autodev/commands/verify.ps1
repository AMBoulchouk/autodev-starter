param(
    [Parameter(Position=0)]
    [string]$FeatureId
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot/driver_helper.ps1"

if (-not $FeatureId) {
    # Check progress.json for current_feature
    $progressPath = ".autodev/state/progress.json"
    if (Test-Path $progressPath) {
        try {
            $prog = Get-Content $progressPath -Raw | ConvertFrom-Json
            $FeatureId = $prog.current_feature
        } catch {}
    }
}

Invoke-RuntimeContract -ContractName "verify" -FeatureId $FeatureId
