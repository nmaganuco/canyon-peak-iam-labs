<#
.SYNOPSIS
    Offboards a Canyon Peak Technologies employee in Active Directory.

.DESCRIPTION
    Disables the account, removes it from every group except Domain Users,
    and moves it into the CanyonPeak-Disabled OU. Written for Lab 06 of the
    IAM Lab Series - the goal is to prove that a leaver's Okta access
    disappears entirely off the back of AD-side changes alone.

.PARAMETER SamAccountName
    The user's AD logon name (e.g. "sam.okafor").

.EXAMPLE
    ./Disable-CanyonPeakLeaver.ps1 -SamAccountName sam.okafor
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SamAccountName
)

Import-Module ActiveDirectory -ErrorAction Stop

$disabledOU = "OU=CanyonPeak-Disabled,DC=corp,DC=canyonpeaktech,DC=com"

$user = Get-ADUser -Identity $SamAccountName -Properties MemberOf -ErrorAction Stop

Write-Host "Offboarding $($user.Name)" -ForegroundColor Cyan

# Disable sign-in first
Disable-ADAccount -Identity $SamAccountName
Write-Host "  Account disabled" -ForegroundColor Yellow

# Strip every group membership except the implicit Domain Users
$groups = $user.MemberOf
foreach ($groupDN in $groups) {
    try {
        Remove-ADGroupMember -Identity $groupDN -Members $SamAccountName -Confirm:$false -ErrorAction Stop
        Write-Host "  Removed from: $groupDN" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "  Could not remove from '$groupDN': $($_.Exception.Message)"
    }
}

# Relocate to the disabled OU so offboarded accounts are easy to find/audit
Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU
Write-Host "  Moved to: $disabledOU" -ForegroundColor Yellow

Write-Host "Done. Run an incremental import in Okta to confirm the account deactivates and drops all group access." -ForegroundColor Cyan
