# test_engine.ps1 - Automated Verification Suite for AutoDev Engine
$ErrorActionPreference = "Stop"

Write-Host "================================================="
Write-Host " Running AutoDev Engine Verification Suite"
Write-Host "================================================="

$passedTests = 0
$failedTests = 0

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        Write-Host "[PASS] $Message" -ForegroundColor Green
        $script:passedTests++
    } else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        $script:failedTests++
    }
}

# Create Sandbox Workspace
$tempRoot = [System.IO.Path]::GetTempPath()
$sandbox = Join-Path $tempRoot ("autodev_test_" + [System.Guid]::NewGuid().ToString().Substring(0, 8))
New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
Write-Host "Sandbox: $sandbox`n"

try {
    # 1. Setup Sandbox (Copy AutoDev files, omit .git)
    Copy-Item -Path ".autodev" -Destination (Join-Path $sandbox ".autodev") -Recurse
    Copy-Item -Path "AGENTS.md" -Destination (Join-Path $sandbox "AGENTS.md")
    Copy-Item -Path "PRODUCT_BRIEF.md" -Destination (Join-Path $sandbox "PRODUCT_BRIEF.md")
    
    Push-Location $sandbox

    # Remove existing progress.json and runtime.yaml in sandbox to test cold start
    Remove-Item ".autodev/state/progress.json" -Force -ErrorAction SilentlyContinue
    Remove-Item ".autodev/runtime.yaml" -Force -ErrorAction SilentlyContinue
    Remove-Item ".autodev/evidence/*" -Force -ErrorAction SilentlyContinue

    # Test 1: Cold Start & Bootstrap
    Write-Host "--- Test 1: Cold Start & Bootstrap ---"
    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/bootstrap.ps1"
    Assert-Condition ($LASTEXITCODE -eq 0) "Bootstrap exited with code 0"
    Assert-Condition (Test-Path ".git") "Git initialized by bootstrap"
    Assert-Condition (Test-Path ".autodev/state/progress.json") "progress.json created"
    Assert-Condition (Test-Path ".autodev/runtime.yaml") "runtime.yaml created"
    $p = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
    Assert-Condition ($p.version -eq 2) "progress.json has version 2"
    Assert-Condition ($p.phase -eq "specification") "Phase transitioned to specification"

    # Test 2: Inspect Diagnostic
    Write-Host "`n--- Test 2: Inspect Diagnostic ---"
    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/inspect.ps1"
    Assert-Condition ($LASTEXITCODE -eq 0) "Inspect exited with code 0"

    # Test 3: Validate Governance
    Write-Host "`n--- Test 3: Validate Governance ---"
    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/validate.ps1"
    Assert-Condition ($LASTEXITCODE -eq 0) "Validate exited with code 0"

    # Test 4: Plan with Feature Dependencies (F001 & F002)
    Write-Host "`n--- Test 4: Plan & Dependency Graph ---"
    $f001Content = @"
# Feature F001: Walking Skeleton
id: F001
depends_on: []
## Scenario
Given app boots
"@
    Set-Content ".autodev/features/F001-walking-skeleton.md" $f001Content

    $f002Content = @"
# Feature F002: Customer Auth
id: F002
depends_on: [F001]
## Scenario
Given customer logs in
"@
    Set-Content ".autodev/features/F002-customer-auth.md" $f002Content

    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/plan.ps1"
    Assert-Condition ($LASTEXITCODE -eq 0) "Plan exited with code 0"
    $p = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
    Assert-Condition ($p.features.F001.status -eq "ready") "F001 is ready"
    Assert-Condition ($p.features.F002.status -eq "pending") "F002 is pending on F001"
    Assert-Condition ($p.phase -eq "development") "Phase transitioned to development"

    # Test 5: Missing Runtime in Development Phase
    Write-Host "`n--- Test 5: Missing runtime.yaml in Development ---"
    Move-Item ".autodev/runtime.yaml" ".autodev/runtime.yaml.bak"
    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/test.ps1"
    $testExit = $LASTEXITCODE
    $ErrorActionPreference = $prevErrorAction
    Assert-Condition ($testExit -ne 0) "test.ps1 failed with code 1 when runtime.yaml is missing in development phase"
    Move-Item ".autodev/runtime.yaml.bak" ".autodev/runtime.yaml"

    # Test 6: Contract Failure & Failed State Transition
    Write-Host "`n--- Test 6: Failing Contract Transition ---"
    $failingRuntime = @"
version: 1
commands:
  validate: ""
  test: "powershell -Command exit 42"
  build: ""
  run: ""
  verify: ""
"@
    Set-Content ".autodev/runtime.yaml" $failingRuntime
    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/auto-cycle.ps1"
    $cycleExit = $LASTEXITCODE
    $ErrorActionPreference = $prevErrorAction
    Assert-Condition ($cycleExit -ne 0) "auto-cycle exited with non-zero on test failure"
    $p = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
    Assert-Condition ($p.features.F001.attempts -eq 1) "F001 attempts incremented to 1"
    Assert-Condition ($p.last_cycle.test -eq "failed") "last_cycle recorded test failure"

    # Test 7: Successful Cycle, Verify & Evidence Generation
    Write-Host "`n--- Test 7: Passing Cycle & Evidence Generation ---"
    $passingRuntime = @"
version: 1
commands:
  validate: "powershell -Command Write-Host 'Validation OK'; exit 0"
  test: "powershell -Command Write-Host 'Tests OK'; exit 0"
  build: "powershell -Command Write-Host 'Build OK'; exit 0"
  run: ""
  verify: "powershell -Command Write-Host 'Verify OK'; exit 0"
"@
    Set-Content ".autodev/runtime.yaml" $passingRuntime

    # Stage initial files so git has a base commit
    git add -A
    git commit -m "initial test base" 2>$null | Out-Null

    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/auto-cycle.ps1"
    Assert-Condition ($LASTEXITCODE -eq 0) "auto-cycle passed successfully"
    $p = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
    Assert-Condition ($p.features.F001.status -eq "completed") "F001 status is completed"
    Assert-Condition ($p.features.F002.status -eq "ready") "F002 automatically unlocked to ready"
    Assert-Condition (Test-Path ".autodev/evidence/F001.json") "Evidence file F001.json generated"
    $evi = Get-Content ".autodev/evidence/F001.json" -Raw | ConvertFrom-Json
    Assert-Condition ($evi.verification.verify -eq "passed") "Evidence confirms verify passed"
    Assert-Condition ($evi.commit -ne $null) "Evidence records git commit SHA"

    # Test 8: Git Safety - Forbidden Secret Detection
    Write-Host "`n--- Test 8: Git Safety - Forbidden Secret Detection ---"
    Set-Content ".env.production" "DATABASE_PASSWORD=secret_123"
    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/auto-cycle.ps1"
    $secExit = $LASTEXITCODE
    $ErrorActionPreference = $prevErrorAction
    Assert-Condition ($secExit -ne 0) "auto-cycle blocked when forbidden file .env.production exists"
    $p = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
    Assert-Condition ($p.features.F002.status -eq "blocked") "F002 status set to blocked"
    Remove-Item ".env.production" -Force
    # Reset status back to ready
    $p.features.F002.status = "ready"
    $p.current_feature = $null
    $p | ConvertTo-Json -Depth 10 | Set-Content ".autodev/state/progress.json"

    # Test 9: Git Safety - Protected Policy Modification
    Write-Host "`n--- Test 9: Git Safety - Protected Policy Modification ---"
    Add-Content ".autodev/manifest.yaml" "`n# modified line"
    $prevErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/auto-cycle.ps1"
    $protExit = $LASTEXITCODE
    $ErrorActionPreference = $prevErrorAction
    Assert-Condition ($protExit -ne 0) "auto-cycle halted when protected file modified"
    $p = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
    Assert-Condition ($p.features.F002.status -eq "approval_required") "F002 status set to approval_required"
    git checkout -- .autodev/manifest.yaml
    $p.features.F002.status = "ready"
    $p.current_feature = $null
    $p | ConvertTo-Json -Depth 10 | Set-Content ".autodev/state/progress.json"

    # Test 10: Final Feature Completion & Backlog Completion
    Write-Host "`n--- Test 10: Complete Backlog & Milestone ---"
    & "powershell" -ExecutionPolicy Bypass -File ".autodev/commands/auto-cycle.ps1"
    Assert-Condition ($LASTEXITCODE -eq 0) "F002 completed successfully"
    $p = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
    Assert-Condition ($p.features.F002.status -eq "completed") "F002 is completed"
    Assert-Condition ($p.phase -eq "complete") "Entire project transitioned to complete phase"
    Assert-Condition (Test-Path ".autodev/evidence/F002.json") "Evidence file F002.json generated"

} finally {
    Pop-Location
    Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "`nCleaned up sandbox."
}

Write-Host "`n================================================="
Write-Host " Test Suite Summary: $passedTests Passed, $failedTests Failed"
Write-Host "================================================="

if ($failedTests -gt 0) {
    exit 1
} else {
    exit 0
}
