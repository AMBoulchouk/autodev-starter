$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Product Specification & Plan"
Write-Host "========================================="

# 1. Ensure PRODUCT_BRIEF.md exists
if (-not (Test-Path "PRODUCT_BRIEF.md")) {
    Write-Host "[plan:warn] PRODUCT_BRIEF.md not found. Creating blank template..."
    Set-Content "PRODUCT_BRIEF.md" "# Product Brief`n`n## Objective`n`n## Core Features`n"
}

# 2. Inspect existing features
$features = Get-ChildItem -Path ".autodev/features" -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "example-feature.md" }
$featureNames = @($features | ForEach-Object { $_.BaseName })

Write-Host "[plan] Existing custom features: $($features.Count)"
foreach ($f in $features) {
    Write-Host "  - $($f.Name)"
}

# 3. Synchronize with progress.json
$progressFile = ".autodev/state/progress.json"
if (Test-Path $progressFile) {
    $progress = Get-Content $progressFile -Raw | ConvertFrom-Json
    
    # If features exist in folder, populate features_pending if empty
    if ($features.Count -gt 0 -and $progress.features_pending.Count -eq 0 -and $progress.features_completed.Count -eq 0) {
        $progress.features_pending = $featureNames
        $progress.features_total = $features.Count
        $progress.phase = "development"
        $progress.last_updated = (Get-Date -Format "o")
        $progress | ConvertTo-Json -Depth 5 | Set-Content $progressFile
        Write-Host "[plan] Synchronized $($features.Count) feature(s) to progress.json. Phase set to 'development'."
    }
}

Write-Host "`n[plan:agent-guide]"
Write-Host "1. Read PRODUCT_BRIEF.md."
Write-Host "2. Model entities in .autodev/domain/entities.md and rules in .autodev/domain/rules.md."
Write-Host "3. Create atomic feature files under .autodev/features/ (e.g. 01-scaffold.md, 02-core.md)."
Write-Host "4. Update .autodev/state/progress.json with the feature names and set phase to 'development'."
Write-Host "========================================="
exit 0
