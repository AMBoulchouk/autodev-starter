$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Test Contract Runner"
Write-Host "========================================="

# 1. Check phase from progress.json
if (Test-Path ".autodev/state/progress.json") {
    try {
        $progress = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
        if ($progress.phase -eq "bootstrap" -or $progress.phase -eq "specification") {
            Write-Host "[test:info] Project is currently in '$($progress.phase)' phase."
            Write-Host "[test:info] Skipping test execution until first feature is under development."
            Write-Host "========================================="
            exit 0
        }
    } catch {
        # ignore parse error, continue
    }
}

# 2. Node.js project
if (Test-Path "package.json") {
    try {
        $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
        if ($pkg.scripts -and $pkg.scripts.test) {
            $testCmd = $pkg.scripts.test
            if ($testCmd -like "*no test specified*") {
                Write-Host "[test:warn] package.json has default placeholder test script."
                Write-Host "[test:warn] Please configure a real test runner (e.g., vitest, jest, node --test)."
                exit 0
            }
            Write-Host "[test] Executing: npm test"
            npm test
            exit $LASTEXITCODE
        }
    } catch {
        Write-Host "[test:warn] Could not parse package.json"
    }
}

# 3. Python project
if ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt")) {
    if (Get-Command pytest -ErrorAction SilentlyContinue) {
        Write-Host "[test] Executing: pytest"
        pytest
        exit $LASTEXITCODE
    } else {
        Write-Host "[test] Executing: python -m unittest discover"
        python -m unittest discover
        exit $LASTEXITCODE
    }
}

# 4. Go project
if (Test-Path "go.mod") {
    Write-Host "[test] Executing: go test ./..."
    go test ./...
    exit $LASTEXITCODE
}

# 5. Rust project
if (Test-Path "Cargo.toml") {
    Write-Host "[test] Executing: cargo test"
    cargo test
    exit $LASTEXITCODE
}

# 6. Fallback if no supported stack detected
Write-Host "[test:notice] No test framework detected for this stack yet."
Write-Host "[test:notice] If code has been written, ensure test commands are configured in package.json or project config."
Write-Host "========================================="
exit 0
