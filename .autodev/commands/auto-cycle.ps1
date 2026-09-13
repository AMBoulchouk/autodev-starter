$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Autonomous Feature Cycle"
Write-Host "========================================="

$progressFile = ".autodev/state/progress.json"
if (-not (Test-Path $progressFile)) {
    Write-Host "[cycle:error] $progressFile does not exist. Run .autodev/commands/bootstrap.ps1 first." -ForegroundColor Red
    exit 1
}

$progress = Get-Content $progressFile -Raw | ConvertFrom-Json

Write-Host "Current Phase: $($progress.phase)"

if ($progress.phase -eq "bootstrap") {
    Write-Host "[cycle] In bootstrap phase. Running bootstrap contract..."
    & ".autodev/commands/bootstrap.ps1"
    exit $LASTEXITCODE
}

if ($progress.phase -eq "specification") {
    Write-Host "[cycle] In specification phase. Running plan contract..."
    & ".autodev/commands/plan.ps1"
    exit $LASTEXITCODE
}

if ($progress.phase -eq "complete") {
    Write-Host "[cycle:done] All features completed! Product MVP is ready." -ForegroundColor Green
    exit 0
}

# Development phase
if ($progress.phase -eq "development") {
    # If no current feature is assigned, assign next pending
    if (-not $progress.current_feature -or $progress.current_feature -eq "") {
        if ($progress.features_pending.Count -eq 0) {
            $progress.phase = "complete"
            $progress.last_updated = (Get-Date -Format "o")
            $progress | ConvertTo-Json -Depth 5 | Set-Content $progressFile
            Write-Host "[cycle:done] No pending features remaining! Phase marked complete." -ForegroundColor Green
            exit 0
        }
        $progress.current_feature = $progress.features_pending[0]
        $progress.last_updated = (Get-Date -Format "o")
        $progress | ConvertTo-Json -Depth 5 | Set-Content $progressFile
        Write-Host "[cycle] Selected next feature: $($progress.current_feature)"
    }

    $active = $progress.current_feature
    Write-Host "[cycle] Evaluating feature: $active"
    
    # 1. Run Validate
    Write-Host "`n--- Running Validate ---"
    & ".autodev/commands/validate.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[cycle:fail] Validate failed for feature $active. Please fix errors before advancing." -ForegroundColor Red
        exit 1
    }

    # 2. Run Tests
    Write-Host "`n--- Running Tests ---"
    & ".autodev/commands/test.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[cycle:fail] Tests failed for feature $active. Please fix failing tests." -ForegroundColor Red
        exit 1
    }

    # 3. Run Build
    Write-Host "`n--- Running Build ---"
    & ".autodev/commands/build.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[cycle:fail] Build failed for feature $active." -ForegroundColor Red
        exit 1
    }

    # Success! Advance state
    Write-Host "`n[cycle:pass] All contracts passed for feature: $active" -ForegroundColor Green
    
    # Update arrays
    $pendingList = [System.Collections.ArrayList]@($progress.features_pending)
    $pendingList.Remove($active)
    $progress.features_pending = @($pendingList)

    $completedList = [System.Collections.ArrayList]@($progress.features_completed)
    if (-not $completedList.Contains($active)) {
        $completedList.Add($active)
    }
    $progress.features_completed = @($completedList)
    $progress.current_feature = $null

    if ($progress.features_pending.Count -eq 0) {
        $progress.phase = "complete"
        Write-Host "[cycle:complete] All features are completed! Milestone reached." -ForegroundColor Green
    }

    $progress.last_updated = (Get-Date -Format "o")
    $progress | ConvertTo-Json -Depth 5 | Set-Content $progressFile

    # Git auto-commit if git is present
    if (Test-Path ".git") {
        git add .
        git commit -m "feat($active): verified contracts pass" 2>$null
        Write-Host "[cycle] Git commit created for $active."
    }
}

Write-Host "========================================="
exit 0
