<#
.SYNOPSIS
    Files a screenshot into the right lab folder with a consistent name, and
    prints the Markdown line to paste into the lab write-up.

.DESCRIPTION
    Takes the most recent image from your Windows screenshots folder, moves it
    into labs/<lab>/screenshots/ as NN-description.png (auto-numbered in capture
    order), and emits the Markdown image reference.

    Intended workflow: press Win+PrtScn while working through a lab (which saves
    straight to Pictures\Screenshots), then run this once per shot with a short
    description. Avoids the save-as / navigate / rename dance entirely.

.PARAMETER Lab
    Lab number or folder name. "00", "0", and "00-domain-controller-setup" all
    resolve to the same folder.

.PARAMETER Name
    Short description of what the screenshot shows. Spaces and capitals are fine;
    it gets slugified (e.g. "Forest promotion complete" -> forest-promotion-complete).

.PARAMETER SourceFolder
    Where to look for the incoming screenshot. Defaults to the standard Windows
    location used by Win+PrtScn.

.PARAMETER File
    Use a specific image file instead of the newest one in SourceFolder.

.PARAMETER Oldest
    Take the OLDEST image in the folder rather than the newest. Use this when
    filing several screenshots at once: without it the newest is consumed first,
    so a batch ends up named in reverse order.

.PARAMETER KeepOriginal
    Copy instead of move, leaving the original in place.

.EXAMPLE
    ./Add-LabScreenshot.ps1 -Lab 00 -Name "forest promotion complete"

    Capture-then-file-immediately. Takes the newest screenshot.

.EXAMPLE
    ./Add-LabScreenshot.ps1 -Lab 00 -Name "first thing I captured"  -Oldest
    ./Add-LabScreenshot.ps1 -Lab 00 -Name "second thing I captured" -Oldest
    ./Add-LabScreenshot.ps1 -Lab 00 -Name "third thing I captured"  -Oldest

    Filing a batch after the fact, in the order the shots were taken.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Lab,

    [Parameter(Mandatory)]
    [string]$Name,

    [string]$SourceFolder = (Join-Path $HOME 'Pictures\Screenshots'),

    [string]$File,

    [string]$RepoRoot,

    [switch]$Oldest,

    [switch]$KeepOriginal
)

$ErrorActionPreference = 'Stop'

# Repo root defaults to the parent of the tools/ folder this script lives in
if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}
$labsRoot = Join-Path $RepoRoot 'labs'
if (-not (Test-Path $labsRoot)) {
    throw "Could not find a 'labs' folder under '$RepoRoot'. Pass -RepoRoot explicitly."
}

# --- resolve the lab folder from a number or a partial name ---
$labDirs = Get-ChildItem -Path $labsRoot -Directory
if ($Lab -match '^\d+$') {
    # Numeric input matches only on the numeric prefix, so "0" cannot also hit "02-..."
    $pattern = '^0*{0}-' -f [int]$Lab
    $candidates = @($labDirs | Where-Object { $_.Name -match $pattern })
} else {
    $candidates = @($labDirs | Where-Object { $_.Name -eq $Lab -or $_.Name -like "$Lab*" })
}
if ($candidates.Count -eq 0) {
    $available = (Get-ChildItem -Path $labsRoot -Directory | Select-Object -ExpandProperty Name) -join ', '
    throw "No lab folder matched '$Lab'. Available: $available"
}
if ($candidates.Count -gt 1) {
    throw "'$Lab' is ambiguous, matched: $(($candidates.Name) -join ', ')"
}
$labFolder  = $candidates[0]
$shotFolder = Join-Path $labFolder.FullName 'screenshots'
if (-not (Test-Path $shotFolder)) { New-Item -ItemType Directory -Path $shotFolder | Out-Null }

# --- pick the source image ---
if ($File) {
    if (-not (Test-Path $File)) { throw "File not found: $File" }
    $source = Get-Item -Path $File
} else {
    if (-not (Test-Path $SourceFolder)) {
        throw "Screenshot folder not found: $SourceFolder`nPress Win+PrtScn to capture, or pass -File / -SourceFolder."
    }
    # Default picks the NEWEST image, which is right for capture-then-file-immediately.
    # -Oldest picks the oldest instead, which is what you want when filing a batch of
    # shots in the order you took them - otherwise the names end up reversed.
    $candidates = Get-ChildItem -Path $SourceFolder -File |
                  Where-Object { $_.Extension -in '.png', '.jpg', '.jpeg' } |
                  Sort-Object LastWriteTime
    if (-not $candidates) { throw "No image files found in $SourceFolder" }

    $source = if ($Oldest) { @($candidates)[0] } else { @($candidates)[-1] }

    $ageMinutes = ([DateTime]::Now - $source.LastWriteTime).TotalMinutes
    if ($ageMinutes -gt 30) {
        Write-Warning ("That screenshot was taken {0:N0} minutes ago. Is it the one you meant?" -f $ageMinutes)
    }
}

# --- build the target name ---
$slug = ($Name.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if (-not $slug) { throw "-Name produced an empty slug; use some letters or numbers." }

$existing = @(Get-ChildItem -Path $shotFolder -File | Where-Object { $_.Name -match '^(\d+)-' })
$nextIndex = 1
if ($existing.Count -gt 0) {
    $indices = @($existing | ForEach-Object { [int]($_.Name -replace '^(\d+)-.*$', '$1') })
    # Cast is required: Measure-Object returns a Double, which the D2 specifier rejects
    $nextIndex = [int](($indices | Measure-Object -Maximum).Maximum) + 1
}
$targetName = '{0:D2}-{1}{2}' -f $nextIndex, $slug, $source.Extension.ToLower()
$targetPath = Join-Path $shotFolder $targetName

if (Test-Path $targetPath) { throw "Target already exists: $targetPath" }

if ($KeepOriginal) {
    Copy-Item -Path $source.FullName -Destination $targetPath
} else {
    Move-Item -Path $source.FullName -Destination $targetPath
}

# --- report ---
$sizeKB = [math]::Round((Get-Item $targetPath).Length / 1KB)
Write-Host ""
Write-Host ("  Took : {0}  (captured {1:HH:mm:ss})" -f $source.Name, $source.LastWriteTime) -ForegroundColor DarkGray
Write-Host "  Filed: $targetName  (${sizeKB} KB)" -ForegroundColor Green
Write-Host "  Into : labs/$($labFolder.Name)/screenshots/" -ForegroundColor Gray
if ($sizeKB -gt 1024) {
    Write-Warning "That file is over 1 MB. Git keeps every version of a binary forever - consider cropping to the relevant window before committing."
}

$markdown = "![{0}](screenshots/{1})" -f $Name, $targetName
Write-Host ""
Write-Host "  Paste this into labs/$($labFolder.Name)/README.md :" -ForegroundColor Cyan
Write-Host "  $markdown" -ForegroundColor White
Write-Host ""

# Put it on the clipboard too, when that's available
try { Set-Clipboard -Value $markdown; Write-Host "  (copied to clipboard)" -ForegroundColor DarkGray } catch { }
