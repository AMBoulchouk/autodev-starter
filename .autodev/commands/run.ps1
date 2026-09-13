$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Application Run Adapter"
Write-Host "========================================="

if (Test-Path "package.json") {
    try {
        $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
        if ($pkg.scripts) {
            if ($pkg.scripts.dev) {
                Write-Host "[run] Launching: npm run dev"
                npm run dev
                exit $LASTEXITCODE
            } elseif ($pkg.scripts.start) {
                Write-Host "[run] Launching: npm start"
                npm start
                exit $LASTEXITCODE
            }
        }
    } catch {
        # ignore parse error
    }
}

if (Test-Path "main.py") {
    Write-Host "[run] Launching: python main.py"
    python main.py
    exit $LASTEXITCODE
}

if (Test-Path "app.py") {
    Write-Host "[run] Launching: python app.py"
    python app.py
    exit $LASTEXITCODE
}

if (Test-Path "Cargo.toml") {
    Write-Host "[run] Launching: cargo run"
    cargo run
    exit $LASTEXITCODE
}

if (Test-Path "go.mod") {
    Write-Host "[run] Launching: go run ."
    go run .
    exit $LASTEXITCODE
}

Write-Host "[run:notice] No standard entrypoint detected yet (e.g. npm dev/start, main.py, go run)."
Write-Host "========================================="
exit 0
