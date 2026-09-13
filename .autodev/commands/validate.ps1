$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Validation Contract"
Write-Host "========================================="

$errors = 0

# 1. Validate Core Governance Files
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

# 2. Validate progress.json schema
if (Test-Path ".autodev/state/progress.json") {
    try {
        $progress = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
        if (-not $progress.phase) {
            Write-Host "[validate:error] progress.json missing 'phase' field" -ForegroundColor Red
            $errors++
        } else {
            Write-Host "[validate:ok] progress.json is valid (current phase: $($progress.phase))"
        }
    } catch {
        Write-Host "[validate:error] progress.json is not valid JSON: $_" -ForegroundColor Red
        $errors++
    }
}

# 3. If a linter is configured in package.json, run it
if (Test-Path "package.json") {
    try {
        $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
        if ($pkg.scripts -and $pkg.scripts.lint) {
            Write-Host "[validate] Running npm run lint..."
            npm run lint
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[validate:error] Code linter failed" -ForegroundColor Red
                $errors++
            } else {
                Write-Host "[validate:ok] Code linter passed"
            }
        }
    } catch {
        Write-Host "[validate:warn] Could not parse package.json"
    }
}

Write-Host "========================================="
if ($errors -gt 0) {
    Write-Host "[validate] FAILED: $errors validation issue(s) found." -ForegroundColor Red
    exit 1
}

Write-Host "[validate] SUCCESS: All structural and code checks passed." -ForegroundColor Green
exit 0
