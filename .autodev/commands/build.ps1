$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Build Contract Runner"
Write-Host "========================================="

# 1. Check phase
if (Test-Path ".autodev/state/progress.json") {
    try {
        $progress = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
        if ($progress.phase -eq "bootstrap" -or $progress.phase -eq "specification") {
            Write-Host "[build:info] Project is in '$($progress.phase)' phase. Skipping build."
            exit 0
        }
    } catch {
        # ignore parse error
    }
}

# 2. Node.js
if (Test-Path "package.json") {
    try {
        $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
        if ($pkg.scripts -and $pkg.scripts.build) {
            Write-Host "[build] Executing: npm run build"
            npm run build
            exit $LASTEXITCODE
        } else {
            Write-Host "[build:info] No build script in package.json (interpreted JS/Node)."
            exit 0
        }
    } catch {
        Write-Host "[build:warn] Could not parse package.json"
    }
}

# 3. Rust
if (Test-Path "Cargo.toml") {
    Write-Host "[build] Executing: cargo build"
    cargo build
    exit $LASTEXITCODE
}

# 4. Go
if (Test-Path "go.mod") {
    Write-Host "[build] Executing: go build ./..."
    go build ./...
    exit $LASTEXITCODE
}

Write-Host "[build:info] No compilation step required for this stack. Build passed."
Write-Host "========================================="
exit 0
