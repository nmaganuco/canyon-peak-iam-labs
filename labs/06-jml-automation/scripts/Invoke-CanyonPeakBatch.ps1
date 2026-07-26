<#
.SYNOPSIS
    Runs a batch of joiner/mover/leaver events from a CSV file.

.DESCRIPTION
    Reads a CSV where each row describes one lifecycle event and dispatches
    it to the appropriate action (Join, Move, Leave). Written for Lab 06 of
    the IAM Lab Series to simulate an HR-feed-driven batch process.

    Expected CSV columns:
      Action        - "Join", "Move", or "Leave"
      FirstName     - required for Join
      LastName      - required for Join
      SamAccountName- required for Move and Leave
      Department    - used by Join and optionally by Move
      OldGroup      - required for Move
      NewGroup      - required for Join (as the initial group) and Move

.PARAMETER CsvPath
    Path to the batch CSV file.

.EXAMPLE
    ./Invoke-CanyonPeakBatch.ps1 -CsvPath ./sample-batch.csv
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath
)

if (-not (Test-Path $CsvPath)) {
    throw "CSV file not found at path: $CsvPath"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rows = Import-Csv -Path $CsvPath

Write-Host "Loaded $($rows.Count) lifecycle event(s) from $CsvPath" -ForegroundColor Cyan

foreach ($row in $rows) {
    Write-Host "----"
    switch ($row.Action.Trim().ToLower()) {
        "join" {
            & "$scriptDir\New-CanyonPeakJoiner.ps1" `
                -FirstName $row.FirstName `
                -LastName $row.LastName `
                -Department $row.Department `
                -Groups @($row.NewGroup)
        }
        "move" {
            & "$scriptDir\Update-CanyonPeakMover.ps1" `
                -SamAccountName $row.SamAccountName `
                -RemoveFromGroup $row.OldGroup `
                -AddToGroup $row.NewGroup `
                -NewDepartment $row.Department
        }
        "leave" {
            & "$scriptDir\Disable-CanyonPeakLeaver.ps1" `
                -SamAccountName $row.SamAccountName
        }
        default {
            Write-Warning "Unrecognized Action '$($row.Action)' - skipping row."
        }
    }
}

Write-Host "----"
Write-Host "Batch complete. Run a full import in Okta to sync everything at once." -ForegroundColor Cyan
