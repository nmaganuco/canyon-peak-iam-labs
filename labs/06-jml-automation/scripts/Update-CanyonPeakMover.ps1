<#
.SYNOPSIS
    Moves a Canyon Peak Technologies employee from one role/department group to another.

.DESCRIPTION
    Removes the user from a specified "old" group and adds them to a "new"
    group, and optionally updates the department attribute to match. Written
    for Lab 06 of the IAM Lab Series.

.PARAMETER SamAccountName
    The user's AD logon name (e.g. "sam.okafor").

.PARAMETER RemoveFromGroup
    The group the user is leaving.

.PARAMETER AddToGroup
    The group the user is joining.

.PARAMETER NewDepartment
    Optional - if supplied, updates the department attribute to match the move.

.EXAMPLE
    ./Update-CanyonPeakMover.ps1 -SamAccountName sam.okafor -RemoveFromGroup "IT Operations" -AddToGroup "Security Analysts" -NewDepartment "Security Operations"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SamAccountName,

    [Parameter(Mandatory)]
    [string]$RemoveFromGroup,

    [Parameter(Mandatory)]
    [string]$AddToGroup,

    [string]$NewDepartment
)

Import-Module ActiveDirectory -ErrorAction Stop

$user = Get-ADUser -Identity $SamAccountName -Properties department -ErrorAction Stop

Write-Host "Moving $($user.Name) from '$RemoveFromGroup' to '$AddToGroup'" -ForegroundColor Cyan

try {
    Remove-ADGroupMember -Identity $RemoveFromGroup -Members $SamAccountName -Confirm:$false -ErrorAction Stop
    Write-Host "  Removed from: $RemoveFromGroup" -ForegroundColor Yellow
}
catch {
    Write-Warning "  Could not remove from '$RemoveFromGroup': $($_.Exception.Message)"
}

try {
    Add-ADGroupMember -Identity $AddToGroup -Members $SamAccountName -ErrorAction Stop
    Write-Host "  Added to: $AddToGroup" -ForegroundColor Green
}
catch {
    Write-Warning "  Could not add to '$AddToGroup': $($_.Exception.Message)"
}

if ($NewDepartment) {
    Set-ADUser -Identity $SamAccountName -Replace @{ department = $NewDepartment }
    Write-Host "  Department updated to: $NewDepartment" -ForegroundColor Green
}

Write-Host "Done. Run an incremental import in Okta to sync the role change." -ForegroundColor Cyan
