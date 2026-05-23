#Requires -Version 5.1
<#
.SYNOPSIS
    Organize Samsung EDL Firehose loaders into model-based folders with SHA256 deduplication.
#>
param(
    [string]$LocalSource = "g:\programing\Challenge\samsung 2024 edl\loader",
    [string]$RepoRoot = "g:\programing\Challenge\samsung 2024 edl\SAMSUNG-EDL-Loaders",
    [switch]$SkipDocs
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DeviceMapPath = Join-Path $ScriptDir "device-map.json"
$DeviceMapRaw = Get-Content -LiteralPath $DeviceMapPath -Raw | ConvertFrom-Json
$DeviceMap = @{}
$DeviceMapRaw.PSObject.Properties | ForEach-Object { $DeviceMap[$_.Name] = $_.Value }

$GenericFolder = "Generic Samsung Firehose"
$ExcludeLocal = @(
    "kamal_mate50_p60_series_Loader.elf",
    "A235M_LOADER_NEW(1).elf"
)

$LegacyFolderMap = @{
    "Samsung A52 4G"                          = "A525F"
    "Samsung Galaxy A52 4G"                   = "A525F"
    "Samsung Galaxy A72"                      = $null
    "Samsung Galaxy Note 10 (SM-(SM-N970U)"   = "N970U"
    "Samsung galaxy S22 (SM-S906U)"           = "S906U"
    "Samsung galaxy S22+ Plus (SM-S906U)"     = "S906U"
}

function Get-ModelFromFilename {
    param([string]$Name)

    if ($Name -match '(?i)^prog_firehose_ddr_smd') { return $null }
    if ($Name -match '(?i)(?:SM[-_])?([A-Z]\d{3}[A-Z0-9]*)') {
        $code = $matches[1].ToUpper()
        if ($code -match '^D\d') { return $null }
        if ($code -eq "A057") { return "A057F" }
        return $code
    }
    return $null
}

function Get-ModelFromLegacyFolder {
    param([string]$FolderName, [string]$FileName)

    if ($LegacyFolderMap.ContainsKey($FolderName)) {
        $mapped = $LegacyFolderMap[$FolderName]
        if ($mapped) { return $mapped }
    }

    if ($FolderName -match 'SM-([A-Z]\d{3}[A-Z0-9]*)') {
        return $matches[1].ToUpper()
    }

    if ($FileName -match '(?i)(?:SM[-_])?([A-Z]\d{3}[A-Z0-9]*)') {
        $code = $matches[1].ToUpper()
        if ($code -notmatch '^D\d') { return $code }
    }

    if ($FileName -match '(?i)([a-z]\d{3}[a-z0-9]*)') {
        return $matches[1].ToUpper()
    }

    return $null
}

function Get-MarketingName {
    param([string]$ModelCode)
    if ($DeviceMap.ContainsKey($ModelCode)) {
        return $DeviceMap[$ModelCode]
    }
    return "Device"
}

function Get-DeviceFolderName {
    param([string]$ModelCode)
    $marketing = Get-MarketingName -ModelCode $ModelCode
    if ($marketing -like "Galaxy *") {
        $marketing = $marketing.Substring(7)
    }
    return "Samsung Galaxy $marketing (SM-$ModelCode)"
}

function Get-FileCategory {
    param([string]$Name)

    $ext = [IO.Path]::GetExtension($Name).ToLowerInvariant()
    if ($Name -match '(?i)LOADER_BIT|_BIT\d|LOADER_NEW') { return "loader_bit" }
    if ($ext -eq ".tar" -and $Name -match '(?i)LOADER') { return "loader_bit" }
    if ($ext -in @(".zip", ".tgz", ".rar", ".7z")) { return "firmware_packages" }
    if ($ext -in @(".elf", ".mbn")) { return "firehose" }
    if ($ext -eq ".tar") { return "loader_bit" }
    return "firehose"
}

function Get-DestinationRelativePath {
    param(
        [string]$ModelCode,
        [string]$FileName,
        [bool]$IsGeneric
    )

    if ($IsGeneric) {
        return Join-Path $GenericFolder $FileName
    }

    $category = Get-FileCategory -Name $FileName
    $folder = Get-DeviceFolderName -ModelCode $ModelCode
    return Join-Path (Join-Path $folder $category) $FileName
}

function Get-FileScore {
    param(
        [string]$RelativePath,
        [string]$FileName,
        [string]$ModelCode,
        [string]$SourceKind
    )

    $score = 0
    if ($RelativePath -match '\\firehose\\|\\loader_bit\\|\\firmware_packages\\') { $score += 100 }
    if ($FileName -notmatch '\(\d+\)') { $score += 50 }
    if ($SourceKind -eq "local") { $score += 10 }
    if ($RelativePath -like "*SM-$ModelCode*") { $score += 25 }
    if ($FileName -like "*$ModelCode*") { $score += 15 }
    $score -= ($FileName.Length / 10)
    return $score
}

function Add-FileCandidate {
    param(
        [hashtable]$Registry,
        [string]$SourcePath,
        [string]$RelativePath,
        [string]$ModelCode,
        [string]$SourceKind,
        [bool]$IsGeneric
    )

    $fileName = Split-Path -Leaf $SourcePath
    $hash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
    $score = Get-FileScore -RelativePath $RelativePath -FileName $fileName -ModelCode $ModelCode -SourceKind $SourceKind

    $entry = @{
        SourcePath   = $SourcePath
        RelativePath = $RelativePath
        FileName     = $fileName
        ModelCode    = $ModelCode
        Hash         = $hash
        Score        = $score
        IsGeneric    = $IsGeneric
        Category     = if ($IsGeneric) { "generic" } else { (Get-FileCategory -Name $fileName) }
    }

    if (-not $Registry.ContainsKey($hash)) {
        $Registry[$hash] = $entry
        return
    }

    if ($score -gt $Registry[$hash].Score) {
        $Registry[$hash] = $entry
    }
}

Write-Host "=== Samsung EDL Loader Organizer ===" -ForegroundColor Cyan
Write-Host "Local source: $LocalSource"
Write-Host "Repo root:    $RepoRoot"

$registry = @{}
$skipped = @()
$deleted = @()

foreach ($name in $ExcludeLocal) {
    $path = Join-Path $LocalSource $name
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
        $deleted += $name
        Write-Host "Deleted excluded file: $name" -ForegroundColor Yellow
    }
}

Write-Host "`nScanning local loader files..." -ForegroundColor Green
Get-ChildItem -LiteralPath $LocalSource -File | ForEach-Object {
    $model = Get-ModelFromFilename -Name $_.Name
    $isGeneric = $false

    if ($_.Name -match '(?i)^prog_firehose_ddr_smd') {
        $isGeneric = $true
        $model = "GENERIC"
    }

    if (-not $model -and -not $isGeneric) {
        $skipped += $_.Name
        Write-Host "  SKIP (no model): $($_.Name)" -ForegroundColor DarkYellow
        return
    }

    $rel = Get-DestinationRelativePath -ModelCode $model -FileName $_.Name -IsGeneric $isGeneric
    Add-FileCandidate -Registry $registry -SourcePath $_.FullName -RelativePath $rel -ModelCode $model -SourceKind "local" -IsGeneric $isGeneric
}

Write-Host "`nScanning existing repo files..." -ForegroundColor Green
$preservePaths = @(".git", ".gitattributes", ".gitignore", "README.md", "DEVICE_SUPPORT.md", "scripts", "organize-report.json")
Get-ChildItem -LiteralPath $RepoRoot -Recurse -File | ForEach-Object {
    $relFromRoot = $_.FullName.Substring($RepoRoot.Length).TrimStart('\')
    $top = ($relFromRoot -split '\\')[0]

    if ($top -in $preservePaths -or $relFromRoot -like "scripts\*") { return }
    if ($_.Name -eq ".dummy") { return }

    $parentFolder = Split-Path -Parent $relFromRoot
    if (-not $parentFolder) { $parentFolder = $top }

    $folderName = ($parentFolder -split '\\')[0]
    $model = Get-ModelFromLegacyFolder -FolderName $folderName -FileName $_.Name

    if (-not $model) {
        $model = Get-ModelFromFilename -Name $_.Name
    }

    $isGeneric = $false
    if ($_.Name -match '(?i)^prog_firehose_ddr_smd') {
        $isGeneric = $true
        $model = "GENERIC"
    }

    if (-not $model -and -not $isGeneric) {
        $skipped += $relFromRoot
        return
    }

    $rel = Get-DestinationRelativePath -ModelCode $model -FileName $_.Name -IsGeneric $isGeneric
    Add-FileCandidate -Registry $registry -SourcePath $_.FullName -RelativePath $rel -ModelCode $model -SourceKind "repo" -IsGeneric $isGeneric
}

Write-Host "`nBuilding organized structure..." -ForegroundColor Green
$staging = Join-Path $RepoRoot "_staging_organize"
if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force
}
New-Item -ItemType Directory -Path $staging -Force | Out-Null

foreach ($hash in $registry.Keys) {
    $entry = $registry[$hash]
    $dest = Join-Path $staging $entry.RelativePath
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $entry.SourcePath -Destination $dest -Force
}

Write-Host "`nRemoving legacy device folders..." -ForegroundColor Green
Get-ChildItem -LiteralPath $RepoRoot -Directory | Where-Object {
    $_.Name -notin @("scripts", "_staging_organize") -and $_.Name -ne $GenericFolder
} | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Recurse -Force
    Write-Host "  Removed: $($_.Name)"
}

Write-Host "`nPromoting staged folders to repo root..." -ForegroundColor Green
Get-ChildItem -LiteralPath $staging | ForEach-Object {
    $target = Join-Path $RepoRoot $_.Name
    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }
    Move-Item -LiteralPath $_.FullName -Destination $target
}
Remove-Item -LiteralPath $staging -Force -ErrorAction SilentlyContinue

$deviceStats = @{}
Get-ChildItem -LiteralPath $RepoRoot -Recurse -File | Where-Object {
    $_.FullName -notlike "*\scripts\*" -and
    $_.Name -notin @(".gitattributes", ".gitignore", "README.md", "DEVICE_SUPPORT.md", "organize-report.json")
} | ForEach-Object {
    $rel = $_.FullName.Substring($RepoRoot.Length).TrimStart('\')
    $parts = $rel -split '\\'
    if ($parts[0] -eq $GenericFolder) { return }

    if ($parts[0] -match 'SM-([A-Z0-9]+)\)') {
        $model = $matches[1]
        if (-not $deviceStats.ContainsKey($model)) {
            $deviceStats[$model] = @{ firehose = 0; loader_bit = 0; firmware_packages = 0; total = 0; folder = $parts[0] }
        }
        $cat = if ($parts.Count -ge 2) { $parts[1] } else { "firehose" }
        if ($deviceStats[$model].ContainsKey($cat)) {
            $deviceStats[$model][$cat]++
        }
        $deviceStats[$model].total++
    }
}

if (-not $SkipDocs) {
    Write-Host "`nGenerating DEVICE_SUPPORT.md..." -ForegroundColor Green
    $deviceSupportPath = Join-Path $RepoRoot "DEVICE_SUPPORT.md"
    $lines = @(
        "# Device Support List",
        "",
        "Samsung Qualcomm EDL Firehose loaders maintained by [Alephgsm](https://alephgsm.com).",
        "",
        "| Device | Model Number | Firehose | Loader BIT | Packages | Total |",
        "|--------|-------------|----------|------------|----------|-------|"
    )

    $sortedModels = $deviceStats.Keys | Sort-Object {
        $letter = $_.Substring(0, 1)
        $num = [int]($_.Substring(1, 3))
        "$letter|$num|$_"
    }

    foreach ($model in $sortedModels) {
        $stat = $deviceStats[$model]
        $marketing = Get-MarketingName -ModelCode $model
        $lines += "| $marketing | SM-$model | $($stat.firehose) | $($stat.loader_bit) | $($stat.firmware_packages) | $($stat.total) |"
    }

    $genericCount = (Get-ChildItem -LiteralPath (Join-Path $RepoRoot $GenericFolder) -File -ErrorAction SilentlyContinue).Count
    if ($genericCount -gt 0) {
        $lines += ""
        $lines += "## Generic Qualcomm Firehose Loaders"
        $lines += ""
        $lines += "The [$GenericFolder]($GenericFolder/) folder contains $genericCount chip-based firehose programmers (Snapdragon platform loaders)."
    }

    $lines += ""
    $lines += "---"
    $lines += "*Last updated: $(Get-Date -Format 'yyyy-MM-dd')*"
    Set-Content -LiteralPath $deviceSupportPath -Value ($lines -join "`n") -Encoding UTF8
}

$report = @{
    timestamp       = (Get-Date).ToString("o")
    filesOrganized  = $registry.Count
    deletedLocal    = $deleted
    skippedFiles    = $skipped
    deviceCount     = $deviceStats.Count
    genericFolder   = $GenericFolder
    devices         = $deviceStats
}
$reportPath = Join-Path $RepoRoot "organize-report.json"
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportPath -Encoding UTF8

Write-Host "`n=== Done ===" -ForegroundColor Cyan
Write-Host "Organized files: $($registry.Count)"
Write-Host "Device folders:  $($deviceStats.Count)"
Write-Host "Deleted local:     $($deleted.Count)"
Write-Host "Skipped:           $($skipped.Count)"
Write-Host "Report:            $reportPath"
