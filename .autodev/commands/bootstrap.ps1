$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Engine Bootstrap"
Write-Host "========================================="

# 1. Initialize Git repository if missing
if (-not (Test-Path ".git")) {
    Write-Host "[bootstrap] Initializing Git repository..."
    git init
} else {
    Write-Host "[bootstrap] Git repository already present."
}

# 2. Ensure core directories exist
$directories = @(
    ".autodev/state",
    ".autodev/evidence",
    ".autodev/features",
    ".autodev/domain",
    ".autodev/policies"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "[bootstrap] Created directory: $dir"
    }
}

# 3. Initialize or Migrate State Machine (progress.json Schema v2)
$progressFile = ".autodev/state/progress.json"
$needsInit = $true

if (Test-Path $progressFile) {
    try {
        $existing = Get-Content $progressFile -Raw | ConvertFrom-Json
        if ($existing.version -eq 2) {
            $needsInit = $false
            Write-Host "[bootstrap] State machine Schema v2 verified."
        }
    } catch {
        $needsInit = $true
    }
}

if ($needsInit) {
    $initialState = [ordered]@{
        version = 2
        phase = "specification"
        current_feature = $null
        features = [ordered]@{}
        last_cycle = [ordered]@{
            validate = $null
            test = $null
            build = $null
            verify = $null
        }
        last_updated = (Get-Date -Format "o")
    }
    $initialState | ConvertTo-Json -Depth 10 | Set-Content $progressFile
    Write-Host "[bootstrap] Initialized progress.json (phase: specification)."
} else {
    # Advance phase if in bootstrap
    $prog = Get-Content $progressFile -Raw | ConvertFrom-Json
    if ($prog.phase -eq "bootstrap") {
        $prog.phase = "specification"
        $prog.last_updated = (Get-Date -Format "o")
        $prog | ConvertTo-Json -Depth 10 | Set-Content $progressFile
        Write-Host "[bootstrap] Phase transitioned from bootstrap to: specification"
    }
}

# 4. Ensure runtime.yaml template exists
if (-not (Test-Path ".autodev/runtime.yaml")) {
    $runtimeTemplate = @"
version: 1

environment:
  setup: ""
  install: ""

commands:
  validate: ""
  test: ""
  build: ""
  run: ""
  verify: ""
  preview: ""

health:
  command: ""
  expected_exit_code: 0
"@
    Set-Content ".autodev/runtime.yaml" $runtimeTemplate
    Write-Host "[bootstrap] Created driver template: .autodev/runtime.yaml"
}

Write-Host "`n[bootstrap:agent-responsibilities]"
Write-Host "AutoDev Engine bootstrap complete. The Agent must now:"
Write-Host "1. Read PRODUCT_BRIEF.md (or inspect existing code if brownfield)."
Write-Host "2. Model domain (.autodev/domain/) and record ADRs (.autodev/state/decisions.md)."
Write-Host "3. Configure project commands in .autodev/runtime.yaml."
Write-Host "4. For greenfield, create walking skeleton spec (F001) and run .autodev/commands/plan."
Write-Host "========================================="
exit 0
