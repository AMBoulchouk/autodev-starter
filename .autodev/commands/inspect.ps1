$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Project Inspection Diagnostic"
Write-Host "========================================="

# 1. Inspect Workspace & OS
$rootDir = (Get-Item -Path ".").FullName
Write-Host "Directory: $rootDir"
Write-Host "Platform : Windows (PowerShell)"

# 2. Check Git status
if (Test-Path ".git") {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    Write-Host "Git      : Initialized (branch: $branch)"
} else {
    Write-Host "Git      : Not initialized"
}

# 3. Detect Tech Stack
$stack = "unknown/empty"
$details = @()

if (Test-Path "package.json") {
    $stack = "Node.js / JavaScript / TypeScript"
    $details += "package.json detected"
    if (Test-Path "tsconfig.json") { $details += "TypeScript configured" }
} elseif (Test-Path "pyproject.toml") {
    $stack = "Python"
    $details += "pyproject.toml detected"
} elseif (Test-Path "requirements.txt") {
    $stack = "Python"
    $details += "requirements.txt detected"
} elseif (Test-Path "go.mod") {
    $stack = "Go"
    $details += "go.mod detected"
} elseif (Test-Path "Cargo.toml") {
    $stack = "Rust"
    $details += "Cargo.toml detected"
} elseif ((Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue).Count -gt 0) {
    $stack = ".NET / C#"
    $details += "C# project file detected"
}

Write-Host "Stack    : $stack"
if ($details.Count -gt 0) {
    Write-Host "Details  : $($details -join ', ')"
}

# 4. Check AutoDev State
if (Test-Path ".autodev/state/progress.json") {
    try {
        $progress = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
        Write-Host "Phase    : $($progress.phase)"
        Write-Host "Features : $($progress.features_completed.Count) completed, $($progress.features_pending.Count) pending"
        if ($progress.current_feature) {
            Write-Host "Current  : $($progress.current_feature)"
        }
    } catch {
        Write-Host "Phase    : Error reading progress.json"
    }
} else {
    Write-Host "Phase    : Uninitialized (no progress.json)"
}

# 5. Check Product Brief
if (Test-Path "PRODUCT_BRIEF.md") {
    Write-Host "Brief    : PRODUCT_BRIEF.md present"
} else {
    Write-Host "Brief    : None (Create PRODUCT_BRIEF.md to define the product)"
}

Write-Host "========================================="
exit 0
