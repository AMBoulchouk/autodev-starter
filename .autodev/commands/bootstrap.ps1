$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Bootstrapping Environment"
Write-Host "========================================="

# 1. Initialize Git repository if missing
if (-not (Test-Path ".git")) {
    Write-Host "[bootstrap] Initializing git repository..."
    git init
}

# 2. Check if state file exists, create or update
$progressFile = ".autodev/state/progress.json"
if (-not (Test-Path $progressFile)) {
    $initialState = @{
        version = 1
        phase = "bootstrap"
        project_name = "autodev-project"
        detected_stack = "none"
        features_total = 0
        features_completed = @()
        current_feature = $null
        features_pending = @()
        last_updated = (Get-Date -Format "o")
    }
    $initialState | ConvertTo-Json -Depth 5 | Set-Content $progressFile
}

$progress = Get-Content $progressFile -Raw | ConvertFrom-Json

# 3. Detect current codebase
$detected = "none"
if (Test-Path "package.json") {
    $detected = "node"
} elseif ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt")) {
    $detected = "python"
} elseif (Test-Path "go.mod") {
    $detected = "go"
} elseif (Test-Path "Cargo.toml") {
    $detected = "rust"
}

$progress.detected_stack = $detected

# 4. Advance phase if bootstrap is complete
if ($progress.phase -eq "bootstrap") {
    $progress.phase = "specification"
    Write-Host "[bootstrap] Phase updated to: specification"
}

$progress.last_updated = (Get-Date -Format "o")
$progress | ConvertTo-Json -Depth 5 | Set-Content $progressFile

Write-Host "[bootstrap] Detected stack: $detected"
Write-Host "[bootstrap] Next step: Define product goals in PRODUCT_BRIEF.md and run .autodev/commands/plan"
Write-Host "========================================="
exit 0
