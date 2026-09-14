$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Project Inspection Diagnostic"
Write-Host "========================================="

# 1. Environment & Platform
$rootDir = (Get-Item -Path ".").FullName
Write-Host "Directory     : $rootDir"
Write-Host "Platform      : Windows (PowerShell)"

# 2. Git Status
if (Test-Path ".git") {
    $branch = "initial"
    try {
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        $b = git branch --show-current 2>$null
        if ($b) { $branch = $b }
        $ErrorActionPreference = $prevEAP
    } catch {
        $branch = "initial"
    }
    Write-Host "Git           : Initialized (branch: $branch)"
} else {
    Write-Host "Git           : Not initialized"
}

# 3. AutoDev Governance Files
$govFiles = @(".autodev/manifest.yaml", ".autodev/architecture.md", "AGENTS.md")
$missingGov = @($govFiles | Where-Object { -not (Test-Path $_) })
if ($missingGov.Count -eq 0) {
    Write-Host "Governance    : All core governance files present"
} else {
    Write-Host "Governance    : Missing: $($missingGov -join ', ')"
}

# 4. Project Driver (.autodev/runtime.yaml)
if (Test-Path ".autodev/runtime.yaml") {
    Write-Host "Project Driver: .autodev/runtime.yaml present"
    $content = Get-Content ".autodev/runtime.yaml" -Raw
    $configured = @()
    foreach ($contract in @("validate", "test", "build", "run", "verify", "preview")) {
        if ($content -match "(?m)^\s*${contract}:\s*[""']?(.+?)[""']?\s*$") {
            $val = $Matches[1].Trim()
            if ($val -ne "") { $configured += $contract }
        }
    }
    if ($configured.Count -gt 0) {
        Write-Host "  Contracts   : $($configured -join ', ')"
    } else {
        Write-Host "  Contracts   : None configured (all empty)"
    }
} else {
    Write-Host "Project Driver: Not configured (missing .autodev/runtime.yaml)"
}

# 5. State Machine (.autodev/state/progress.json)
if (Test-Path ".autodev/state/progress.json") {
    try {
        $progress = Get-Content ".autodev/state/progress.json" -Raw | ConvertFrom-Json
        Write-Host "Phase         : $($progress.phase)"
        $featCount = ($progress.features.PSObject.Properties | Measure-Object).Count
        Write-Host "Features      : $featCount registered"
        if ($progress.current_feature) {
            Write-Host "Active Feature: $($progress.current_feature)"
        }
    } catch {
        Write-Host "Phase         : Error reading progress.json"
    }
} else {
    Write-Host "Phase         : Uninitialized"
}

# 6. Product Brief
if (Test-Path "PRODUCT_BRIEF.md") {
    Write-Host "Product Brief : PRODUCT_BRIEF.md present"
} else {
    Write-Host "Product Brief : Not found"
}

Write-Host "========================================="
exit 0
