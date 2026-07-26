<#
.SYNOPSIS
    Onboards a new Canyon Peak Technologies employee in Active Directory.

.DESCRIPTION
    Creates a new AD user under the CanyonPeak-Users OU and adds them to the
    Canyon Peak Employees group plus whichever department/role groups are
    supplied. Written for Lab 06 of the IAM Lab Series - intentionally simple,
    not a production onboarding tool.

.PARAMETER FirstName
    Employee first name.

.PARAMETER LastName
    Employee last name.

.PARAMETER Department
    Department value written to the department attribute (e.g. "IT Operations").

.PARAMETER Groups
    One or more AD group names to add the new user to, in addition to
    "Canyon Peak Employees".

.EXAMPLE
    ./New-CanyonPeakJoiner.ps1 -FirstName Sam -LastName Okafor -Department "IT Operations" -Groups "IT Operations"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$FirstName,

    [Parameter(Mandatory)]
    [string]$LastName,

    [Parameter(Mandatory)]
    [string]$Department,

    [Parameter(Mandatory)]
    [string[]]$Groups
)

Import-Module ActiveDirectory -ErrorAction Stop

$domain      = "canyonpeak.local"
$upnSuffix   = "canyonpeaktech.com"
$usersOU     = "OU=CanyonPeak-Users,DC=canyonpeak,DC=local"
$samAccount  = ("{0}.{1}" -f $FirstName, $LastName).ToLower()
$upn         = "$samAccount@$upnSuffix"
$displayName = "$FirstName $LastName"

if (Get-ADUser -Filter "SamAccountName -eq '$samAccount'" -ErrorAction SilentlyContinue) {
    throw "A user with SamAccountName '$samAccount' already exists. Aborting to avoid a duplicate account."
}

$tempPassword = ConvertTo-SecureString "ChangeMe!" + (Get-Random -Minimum 1000 -Maximum 9999) -AsPlainText -Force

Write-Host "Creating AD user: $displayName ($samAccount)" -ForegroundColor Cyan

New-ADUser `
    -Name $displayName `
    -GivenName $FirstName `
    -Surname $LastName `
    -SamAccountName $samAccount `
    -UserPrincipalName $upn `
    -Path $usersOU `
    -AccountPassword $tempPassword `
    -ChangePasswordAtLogon $true `
    -Enabled $true `
    -OtherAttributes @{ department = $Department }

$groupsToJoin = @("Canyon Peak Employees") + $Groups | Select-Object -Unique

foreach ($group in $groupsToJoin) {
    try {
        Add-ADGroupMember -Identity $group -Members $samAccount -ErrorAction Stop
        Write-Host "  Added to group: $group" -ForegroundColor Green
    }
    catch {
        Write-Warning "  Could not add '$samAccount' to group '$group': $($_.Exception.Message)"
    }
}

Write-Host "Done. Run an incremental import in Okta to sync $displayName." -ForegroundColor Cyan
