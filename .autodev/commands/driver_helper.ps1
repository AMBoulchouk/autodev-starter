# driver_helper.ps1 - Centralized Contract Execution & Utilities for AutoDev PowerShell scripts
$ErrorActionPreference = "Stop"

function Get-YamlCommand {
    param([string]$ContractName)
    $yamlPath = ".autodev/runtime.yaml"
    if (-not (Test-Path $yamlPath)) { return $null }
    
    $content = Get-Content $yamlPath -Raw
    # Extract command under 'commands:' section
    if ($content -match "(?ms)^commands:\s*(.*?)(^health:|^environment:|\Z)") {
        $commandsBlock = $Matches[1]
        if ($commandsBlock -match "(?m)^\s*${ContractName}:\s*[""']?(.*?)[""']?\s*$") {
            $cmd = $Matches[1].Trim()
            return $cmd
        }
    }
    return $null
}

function Get-ProgressPhase {
    $progressPath = ".autodev/state/progress.json"
    if (Test-Path $progressPath) {
        try {
            $json = Get-Content $progressPath -Raw | ConvertFrom-Json
            if ($json.phase) { return $json.phase }
        } catch {
            return "unknown"
        }
    }
    return "bootstrap"
}

function Invoke-RuntimeContract {
    param(
        [string]$ContractName,
        [string]$FeatureId = $null
    )
    
    Write-Host "========================================="
    Write-Host " [autodev] Contract: $ContractName"
    Write-Host "========================================="

    $phase = Get-ProgressPhase
    $hasRuntime = Test-Path ".autodev/runtime.yaml"

    # Lifecycle bypass check: only valid if bootstrap/specification AND runtime.yaml not present
    if ((-not $hasRuntime) -and ($phase -eq "bootstrap" -or $phase -eq "specification")) {
        Write-Host "[autodev:$ContractName:bypass] Phase is '$phase' and runtime.yaml not yet configured. Contract does not apply yet."
        Write-Host "========================================="
        exit 0
    }

    if (-not $hasRuntime) {
        Write-Host "[autodev:$ContractName:error] Missing .autodev/runtime.yaml. The Agent must configure the project driver." -ForegroundColor Red
        Write-Host "========================================="
        exit 1
    }

    $cmd = Get-YamlCommand -ContractName $ContractName
    if ($null -eq $cmd -or $cmd -eq "") {
        Write-Host "[autodev:$ContractName:info] Contract '$ContractName' is empty in runtime.yaml. No operation performed."
        Write-Host "========================================="
        exit 0
    }

    if ($FeatureId) {
        $cmd = $cmd.Replace("{FEATURE}", $FeatureId).Replace('$FEATURE', $FeatureId)
    }

    Write-Host "[autodev:$ContractName:exec] $cmd"
    
    $exitCode = 0
    try {
        & cmd.exe /c $cmd
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
    } catch {
        Write-Host "[autodev:$ContractName:error] Execution failed: $_" -ForegroundColor Red
        $exitCode = 1
    }

    Write-Host "========================================="
    if ($exitCode -ne 0) {
        Write-Host "[autodev:$ContractName:failed] Exit code: $exitCode" -ForegroundColor Red
        exit $exitCode
    } else {
        Write-Host "[autodev:$ContractName:passed] Contract completed successfully." -ForegroundColor Green
        exit 0
    }
}
