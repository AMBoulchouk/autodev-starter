$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host " [autodev] Deterministic Spec Coordinator"
Write-Host "========================================="

$progressFile = ".autodev/state/progress.json"
if (-not (Test-Path $progressFile)) {
    Write-Host "[plan:error] progress.json missing. Run .autodev/commands/bootstrap.ps1 first." -ForegroundColor Red
    exit 1
}

$progress = Get-Content $progressFile -Raw | ConvertFrom-Json

# 1. Scan feature files in .autodev/features/
$featureFiles = Get-ChildItem -Path ".autodev/features" -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "template" -and $_.Name -ne "example-feature.md" }

if ($featureFiles.Count -eq 0) {
    Write-Host "[plan:notice] No custom specifications found in .autodev/features/."
    Write-Host "[plan:notice] The Agent must decompose PRODUCT_BRIEF.md into feature files (e.g. F001-walking-skeleton.md)."
    Write-Host "========================================="
    exit 0
}

Write-Host "[plan] Discovered $($featureFiles.Count) feature file(s)."

# Ensure features object exists
if (-not $progress.features) {
    $progress | Add-Member -MemberType NoteProperty -Name "features" -Value ([PSCustomObject]@{})
}

$discoveredIds = @()
$autoIndex = 1

# 2. Parse metadata from each feature file
foreach ($file in $featureFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Determine Feature ID
    $featId = $null
    if ($file.BaseName -match "^(F\d+)") {
        $featId = $Matches[1]
    } elseif ($content -match "(?m)^id:\s*[""']?(F\d+)[""']?") {
        $featId = $Matches[1]
    } else {
        $featId = ("F{0:D3}" -f $autoIndex)
        $autoIndex++
    }
    $discoveredIds += $featId

    # Determine Title
    $featTitle = $file.BaseName
    if ($content -match "(?m)^#\s*Feature(?:\s+[A-Za-z0-9_-]+)?:\s*(.+)$") {
        $featTitle = $Matches[1].Trim()
    } elseif ($file.BaseName -match "^F\d+-(.+)$") {
        $featTitle = $Matches[1].Replace("-", " ")
    }

    # Determine Dependencies
    $deps = @()
    if ($content -match "(?m)^depends_on:\s*\[(.*?)\]") {
        $rawDeps = $Matches[1].Split(',')
        foreach ($d in $rawDeps) {
            $cleaned = $d.Trim().Trim('"').Trim("'")
            if ($cleaned -ne "") { $deps += $cleaned }
        }
    }

    # Check if feature already exists in progress.json
    $existing = $null
    if ($progress.features.PSObject.Properties[$featId]) {
        $existing = $progress.features.$featId
    }

    if ($null -eq $existing) {
        # New feature
        $newFeat = [ordered]@{
            name = $featTitle
            spec = ".autodev/features/$($file.Name)"
            status = "pending"
            attempts = 0
            depends_on = @($deps)
        }
        $progress.features | Add-Member -MemberType NoteProperty -Name $featId -Value ([PSCustomObject]$newFeat) -Force
    } else {
        # Update spec file & deps, preserve status and attempts
        $existing.name = $featTitle
        $existing.spec = ".autodev/features/$($file.Name)"
        $existing.depends_on = @($deps)
    }
}

# 3. Resolve Dependencies and Calculate 'ready' / 'blocked' statuses
foreach ($prop in $progress.features.PSObject.Properties) {
    $fid = $prop.Name
    $feat = $prop.Value
    
    # Don't touch completed, implementing, validating, or approval_required
    if ($feat.status -in @("completed", "skipped", "implementing", "validating", "approval_required")) {
        continue
    }

    $allDepsSatisfied = $true
    $hasInvalidDep = $false

    if ($feat.depends_on -and $feat.depends_on.Count -gt 0) {
        foreach ($dep in $feat.depends_on) {
            if (-not $progress.features.PSObject.Properties[$dep]) {
                Write-Host "[plan:warn] Feature $fid depends on non-existent feature: $dep" -ForegroundColor Yellow
                $hasInvalidDep = $true
                $allDepsSatisfied = $false
                break
            }
            $depStatus = $progress.features.$dep.status
            if ($depStatus -ne "completed" -and $depStatus -ne "skipped") {
                $allDepsSatisfied = $false
            }
        }
    }

    if ($hasInvalidDep) {
        $feat.status = "blocked"
    } elseif ($allDepsSatisfied) {
        $feat.status = "ready"
    } else {
        $feat.status = "pending"
    }
}

# 4. Check global phase progression
$allCompleted = $true
$hasReady = $false
foreach ($prop in $progress.features.PSObject.Properties) {
    $st = $prop.Value.status
    if ($st -ne "completed" -and $st -ne "skipped") {
        $allCompleted = $false
    }
    if ($st -eq "ready") {
        $hasReady = $true
    }
}

if ($allCompleted -and ($progress.features.PSObject.Properties | Measure-Object).Count -gt 0) {
    $progress.phase = "complete"
    Write-Host "`n[plan:complete] All features are completed!" -ForegroundColor Green
} elseif ($progress.phase -eq "specification" -and $hasReady) {
    $progress.phase = "development"
    Write-Host "`n[plan] Transitioned phase to: development" -ForegroundColor Green
}

$progress.last_updated = (Get-Date -Format "o")
$progress | ConvertTo-Json -Depth 10 | Set-Content $progressFile

# 5. Display Work Graph & Next Unit of Work
Write-Host "`n--- Feature Work Graph ---"
$nextUnit = $null
foreach ($prop in $progress.features.PSObject.Properties) {
    $f = $prop.Value
    $depStr = if ($f.depends_on.Count -gt 0) { " [depends: $($f.depends_on -join ', ')]" } else { "" }
    Write-Host ("{0,-6} | {1,-14} | {2,-30} | Attempts: {3}{4}" -f $prop.Name, $f.status, $f.name, $f.attempts, $depStr)
    
    if (-not $nextUnit -and $f.status -eq "ready") {
        $nextUnit = $prop.Name
    }
}

Write-Host "--------------------------"
if ($nextUnit) {
    Write-Host "[plan:next] Next ready unit of work: $nextUnit ($($progress.features.$nextUnit.name))" -ForegroundColor Cyan
} else {
    if (-not $allCompleted) {
        Write-Host "[plan:notice] No feature is currently in 'ready' state. Check blocked/pending dependencies." -ForegroundColor Yellow
    }
}

Write-Host "========================================="
exit 0
