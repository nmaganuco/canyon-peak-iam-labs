# Lab 00 — Domain Controller & AD Foundation

**Status:** Not started
**Scenario:** Standing up the `canyonpeak.local` domain from bare metal (well, bare VM) before any Okta work begins.

## Objective

Provision a dedicated Windows Server 2022 VM, promote it to the first domain controller of a brand-new forest (`canyonpeak.local`), and lay down the base OU structure the rest of the series depends on. This is deliberately a **separate environment** from my existing home lab domain — Canyon Peak gets its own clean forest so nothing here touches the AD/DNS/DHCP setup I already run day to day.

## Prerequisites

- VMware (Workstation/ESXi/whatever hosts the existing home lab) with enough free capacity for one more VM
- A Windows Server 2022 evaluation ISO (Microsoft Evaluation Center) or licensed media
- A private/internal virtual network in VMware for this VM to sit on — doesn't need internet access for AD DS itself, but does need outbound internet later for the Okta AD Agent (Lab 02), so plan NAT or bridged networking accordingly

## Environment & technologies

- VMware (hypervisor)
- Windows Server 2022 (Desktop Experience — easier to administer in a lab than Server Core)
- Active Directory Domain Services (AD DS)
- DNS Server role (installed automatically alongside AD DS)

## Steps

### 1. Create the VM

In VMware, create a new VM: 2 vCPU, 4–8 GB RAM, 60 GB disk (thin-provisioned is fine for a lab), attached to a dedicated internal/NAT network segment separate from the home lab's network. Name it something identifiable, e.g. `CANYONPEAK-DC01`.

### 2. Install Windows Server 2022

Boot from the ISO, choose the **Desktop Experience** edition, and complete a standard install. Set a strong local administrator password and note it somewhere safe — this becomes the domain's Enterprise Admin credential once the forest is promoted.

### 3. Networking and hostname

Before promoting to a DC, lock down the basics:

- Assign the VM a static internal IP (DNS will need a stable address to point to once AD DS is running)
- Rename the computer to `CANYONPEAK-DC01` (Server Manager → Local Server → Computer Name) and reboot
- Set the VM's own DNS to point at itself once the DNS role is installed in the next step (`127.0.0.1`, or the static IP) — a DC should be authoritative for its own zone, not relying on an external resolver for domain lookups

### 4. Install the AD DS role

Via Server Manager → Add Roles and Features, or PowerShell:

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```

### 5. Promote to a new forest

Run the AD DS configuration wizard (the notification flag in Server Manager after the role install finishes), or via PowerShell:

```powershell
Install-ADDSForest `
    -DomainName "canyonpeak.local" `
    -DomainNetbiosName "CANYONPEAK" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "SetAStrongDSRMPassword!" -AsPlainText -Force) `
    -Force:$true
```

The VM reboots as part of this step. Set and record a separate Directory Services Restore Mode (DSRM) password — don't reuse the local admin password.

### 6. Post-promotion validation

After reboot, confirm the forest actually came up healthy before building anything on top of it:

```powershell
Get-ADDomain
Get-Service ADWS, DNS, Netlogon, NTDS | Select-Object Name, Status
```

All four services should show Running, and `Get-ADDomain` should return `canyonpeak.local` with no errors.

### 7. Build the base OU structure

Create the organizational units the rest of the series will use — for users, groups, and disabled/offboarded accounts:

```powershell
New-ADOrganizationalUnit -Name "CanyonPeak-Users"    -Path "DC=canyonpeak,DC=local"
New-ADOrganizationalUnit -Name "CanyonPeak-Groups"   -Path "DC=canyonpeak,DC=local"
New-ADOrganizationalUnit -Name "CanyonPeak-Disabled" -Path "DC=canyonpeak,DC=local"
```

### 8. Create a service account for lab automation

The PowerShell scripts in Lab 06 need an account with rights to create/modify/disable/move AD objects. Rather than running everything as Domain Admin, create a dedicated account and delegate just the OU control needed:

```powershell
New-ADUser -Name "svc-labautomation" -SamAccountName "svc-labautomation" `
    -Path "DC=canyonpeak,DC=local" -Enabled $true `
    -AccountPassword (ConvertTo-SecureString "SetAStrongServiceAccountPassword!" -AsPlainText -Force) `
    -PasswordNeverExpires $true
```

Then delegate control over the three OUs above to `svc-labautomation` via Delegation of Control Wizard in ADUC (or `dsacls`), scoped to create/delete/modify user and group objects — not full Domain Admin.

### 9. Snapshot the VM

Once the forest, OUs, and service account are confirmed working, take a clean VMware snapshot (`post-promotion-baseline`) before starting Lab 01. If a later lab goes sideways, this is the fast way back to a known-good state instead of rebuilding from scratch.

## Verification

- `Get-ADDomain` returns `canyonpeak.local` with no errors
- AD DS, DNS, Netlogon, and ADWS services are all Running
- Three OUs exist under the domain root: `CanyonPeak-Users`, `CanyonPeak-Groups`, `CanyonPeak-Disabled`
- `svc-labautomation` exists and has delegated (not Domain Admin) rights over those three OUs
- A clean VMware snapshot exists before any lab-specific configuration begins

## Notes

_(fill in as completed — VMware networking quirks, DNS resolution issues, anything that didn't go as planned)_

## Key takeaways

_(fill in once complete)_

---

[Series overview](../..) | [Lab 01 — Tenant Setup & Configuration ➡](../01-tenant-setup)
