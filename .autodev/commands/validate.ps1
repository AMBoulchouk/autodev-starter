$ErrorActionPreference = "Stop"
. "$PSScriptRoot/driver_helper.ps1"

Write-Host "========================================="
Write-Host " [autodev] Governance & Code Validation"
Write-Host "========================================="

$errors = 0

# 1. Structural Governance Checks
$requiredFiles = @(
    ".autodev/manifest.yaml",
    ".autodev/architecture.md",
    ".autodev/state/progress.json",
    "AGENTS.md"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "[validate:error] Missing required file: $file" -ForegroundColor Red
        $errors++
    } else {
        Write-Host "[validate:ok] $file is present"
    }
}

# 2. State Machine Schema Validation
if (Test-Path ".autodev/state/progress.json") {
    try {
        $progress = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
        if (-not $progress.phase -or -not $progress.features) {
            Write-Host "[validate:error] progress.json missing 'phase' or 'features' field" -ForegroundColor Red
            $errors++
        } else {
            Write-Host "[validate:ok] progress.json schema valid (phase: $($progress.phase))"
        }
    } catch {
        Write-Host "[validate:error] progress.json failed JSON parse: $_" -ForegroundColor Red
        $errors++
    }
}

if ($errors -gt 0) {
    Write-Host "[validate] FAILED: $errors governance issue(s) detected." -ForegroundColor Red
    exit 1
}

Write-Host "[validate:ok] Governance checks passed."

# 3. Delegate to Project Driver (runtime.yaml commands.validate)
Invoke-RuntimeContract -ContractName "validate"
