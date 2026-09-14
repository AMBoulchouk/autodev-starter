$ErrorActionPreference = "Stop"
. "$PSScriptRoot/driver_helper.ps1"

Write-Host "========================================="
Write-Host " [autodev] Autonomous Feature Cycle"
Write-Host "========================================="

$progressFile = ".autodev/state/progress.json"
if (-not (Test-Path $progressFile)) {
    Write-Host "[cycle:error] progress.json missing. Run .autodev/commands/bootstrap.ps1 first." -ForegroundColor Red
    exit 1
}

$progress = Get-Content $progressFile -Raw | ConvertFrom-Json

# Helper: Save state
function Save-ProgressState {
    $progress.last_updated = (Get-Date -Format "o")
    $progress | ConvertTo-Json -Depth 10 | Set-Content $progressFile
}

# 1. Check current phase
Write-Host "Current Phase: $($progress.phase)"

if ($progress.phase -eq "bootstrap") {
    Write-Host "[cycle] In bootstrap phase. Running bootstrap contract..."
    & "$PSScriptRoot/bootstrap.ps1"
    exit $LASTEXITCODE
}

if ($progress.phase -eq "specification") {
    Write-Host "[cycle] In specification phase. Running plan contract..."
    & "$PSScriptRoot/plan.ps1"
    exit $LASTEXITCODE
}

if ($progress.phase -eq "complete") {
    Write-Host "[cycle:done] All features completed! Milestone reached." -ForegroundColor Green
    exit 0
}

# 2. Select active feature if none assigned
if (-not $progress.current_feature -or $progress.current_feature -eq "") {
    $targetId = $null
    foreach ($prop in $progress.features.PSObject.Properties) {
        if ($prop.Value.status -in @("ready", "failed", "implementing")) {
            $targetId = $prop.Name
            break
        }
    }

    if (-not $targetId) {
        Write-Host "[cycle:notice] No feature is ready for development. Running plan to refresh dependencies..."
        & "$PSScriptRoot/plan.ps1"
        $progress = Get-Content $progressFile -Raw | ConvertFrom-Json
        foreach ($prop in $progress.features.PSObject.Properties) {
            if ($prop.Value.status -in @("ready", "failed", "implementing")) {
                $targetId = $prop.Name
                break
            }
        }
    }

    if (-not $targetId) {
        Write-Host "[cycle:notice] No features are in 'ready' state. Development paused." -ForegroundColor Yellow
        exit 0
    }

    $progress.current_feature = $targetId
    if ($progress.features.$targetId.status -eq "ready") {
        $progress.features.$targetId.status = "implementing"
    }
    Save-ProgressState
    Write-Host "[cycle] Assigned active feature: $targetId ($($progress.features.$targetId.name))"
}

$activeId = $progress.current_feature
$activeFeat = $progress.features.$activeId

Write-Host "[cycle] Active Feature: $activeId ($($activeFeat.name))"
Write-Host "[cycle] Current Status: $($activeFeat.status)"

# Transition to validating
$activeFeat.status = "validating"
Save-ProgressState

# 3. Execute Contract Pipeline (validate -> test -> build -> verify)
$contracts = @("validate", "test", "build", "verify")
$cycleResults = [ordered]@{
    validate = $null
    test = $null
    build = $null
    verify = $null
}

$failedContract = $null

foreach ($c in $contracts) {
    Write-Host "`n>>> Contract: $c <<<"
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    if ($c -eq "verify") {
        powershell -ExecutionPolicy Bypass -File "$PSScriptRoot/verify.ps1" $activeId
    } else {
        powershell -ExecutionPolicy Bypass -File "$PSScriptRoot/$c.ps1"
    }
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    if ($exitCode -ne 0) {
        $cycleResults[$c] = "failed"
        $failedContract = $c
        Write-Host "[cycle:fail] Contract '$c' FAILED with exit code $exitCode." -ForegroundColor Red
        break
    } else {
        $cycleResults[$c] = "passed"
        Write-Host "[cycle:ok] Contract '$c' PASSED." -ForegroundColor Green
    }
}

# Update last cycle
$progress.last_cycle = [PSCustomObject]$cycleResults

# If any contract failed: Transition to failed -> implementing
if ($failedContract) {
    $activeFeat.attempts = [int]$activeFeat.attempts + 1
    $activeFeat.status = "failed"
    Save-ProgressState
    
    # Ready for agent retry
    $activeFeat.status = "implementing"
    Save-ProgressState
    
    Write-Host "`n========================================="
    Write-Host "[cycle:error] Feature $activeId failed on contract '$failedContract' (Attempt #$($activeFeat.attempts))." -ForegroundColor Red
    Write-Host "[cycle:action] The Agent must inspect errors, fix implementation, and rerun cycle."
    Write-Host "========================================="
    exit 1
}

# 4. All Contracts Passed -> Run Git Safety Checks
Write-Host "`n>>> Checking Git Safety Policies <<<"

$forbiddenPatterns = @(".env*", "*.pem", "*.key", "*.pfx", "secrets.*")
$protectedPatterns = @(".autodev/policies/*", ".autodev/manifest.yaml")
$maxChangedFiles = 50

# Inspect porcelain status
$gitStatus = git status --porcelain 2>$null
$changedFiles = @()
if ($gitStatus) {
    foreach ($line in ($gitStatus -split "`r?`n")) {
        if ($line.Length -gt 3) {
            $fpath = $line.Substring(3).Trim().Replace('\', '/')
            if ($fpath -match "->\s*(.+)$") {
                $fpath = $Matches[1].Trim()
            }
            if ($fpath -ne "") { $changedFiles += $fpath }
        }
    }
}

# Check for forbidden files
foreach ($file in $changedFiles) {
    foreach ($pat in $forbiddenPatterns) {
        if ($file -like $pat -or (Split-Path -Leaf $file) -like $pat) {
            Write-Host "[cycle:security] FORBIDDEN FILE DETECTED: $file" -ForegroundColor Red
            $activeFeat.status = "blocked"
            Save-ProgressState
            Write-Host "[cycle:halt] Feature marked as 'blocked'. Forbidden secrets must be removed." -ForegroundColor Red
            exit 1
        }
    }
}

# Check for protected files
foreach ($file in $changedFiles) {
    if ($file -eq ".autodev/manifest.yaml" -or $file.StartsWith(".autodev/policies/")) {
        Write-Host "[cycle:security] PROTECTED PATH MODIFIED: $file" -ForegroundColor Yellow
        $activeFeat.status = "approval_required"
        Save-ProgressState
        Write-Host "[cycle:halt] Feature marked as 'approval_required'. Requires human approval." -ForegroundColor Yellow
        exit 1
    }
}

# Check max changed files
if ($changedFiles.Count -gt $maxChangedFiles) {
    Write-Host "[cycle:security] Exceeded max changed files ($($changedFiles.Count) > $maxChangedFiles)" -ForegroundColor Yellow
    $activeFeat.status = "approval_required"
    Save-ProgressState
    Write-Host "[cycle:halt] Feature marked as 'approval_required'. Large change threshold exceeded." -ForegroundColor Yellow
    exit 1
}

# 5. Generate Auditable Evidence
Write-Host "`n>>> Generating Auditable Evidence <<<"
$evidenceDir = ".autodev/evidence"
if (-not (Test-Path $evidenceDir)) {
    New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
}

$evidenceFile = "$evidenceDir/$activeId.json"
$timestamp = (Get-Date -Format "o")

$evidenceData = [ordered]@{
    feature = $activeId
    spec = $activeFeat.spec
    timestamp = $timestamp
    verification = $cycleResults
    commit = $null
    changed_files = $changedFiles
    attempts = [int]$activeFeat.attempts + 1
    dependencies = $activeFeat.depends_on
    acceptance_criteria_verified = $true
}

# 6. Atomic Git Staging & Commit
$commitSha = "uncommitted"
if (Test-Path ".git") {
    # Write evidence file first so it gets committed together
    $evidenceData | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
    
    git add -A
    $commitMsg = "feat($activeId): verified acceptance criteria"
    git commit -m $commitMsg 2>$null | Out-Null
    $commitSha = (git rev-parse --short HEAD 2>$null)
    if ($commitSha) {
        $evidenceData.commit = $commitSha.Trim()
        # Update evidence file with actual commit SHA
        $evidenceData | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
        git add $evidenceFile
        git commit --amend -C HEAD 2>$null | Out-Null
    }
    Write-Host "[cycle:git] Atomic commit created: $commitSha" -ForegroundColor Green
} else {
    $evidenceData | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
}

# 7. Complete Feature & Unlock Dependent Features
$activeFeat.status = "completed"
$activeFeat.attempts = [int]$activeFeat.attempts + 1
$progress.current_feature = $null

Write-Host "[cycle:pass] Feature $activeId completed successfully!" -ForegroundColor Green

# Refresh dependencies across all features
foreach ($prop in $progress.features.PSObject.Properties) {
    $fid = $prop.Name
    $f = $prop.Value
    if ($f.status -eq "pending") {
        $allDepsDone = $true
        foreach ($dep in $f.depends_on) {
            if ($progress.features.$dep.status -ne "completed" -and $progress.features.$dep.status -ne "skipped") {
                $allDepsDone = $false
                break
            }
        }
        if ($allDepsDone) {
            $f.status = "ready"
            Write-Host "[cycle:unlock] Feature $fid unlocked -> status: ready" -ForegroundColor Cyan
        }
    }
}

# Check if entire backlog is done
$allDone = $true
foreach ($prop in $progress.features.PSObject.Properties) {
    if ($prop.Value.status -ne "completed" -and $prop.Value.status -ne "skipped") {
        $allDone = $false
        break
    }
}

if ($allDone -and ($progress.features.PSObject.Properties | Measure-Object).Count -gt 0) {
    $progress.phase = "complete"
    Write-Host "`n[cycle:milestone] ALL FEATURES ARE COMPLETED! Product is ready." -ForegroundColor Green
}

Save-ProgressState

Write-Host "========================================="
exit 0
