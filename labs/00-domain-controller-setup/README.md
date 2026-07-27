# Lab 00 — Domain Controller & AD Foundation

**Status:** In progress
**Scenario:** Standing up the `corp.canyonpeaktech.com` domain from a bare VM, before any Okta work begins.

## Objective

Provision a dedicated Windows Server 2022 VM, promote it to the first domain controller of a new forest, and lay down the OU structure and service account the rest of the series depends on. This is deliberately a **separate environment** from the home lab I already run day to day — Canyon Peak gets its own isolated forest so nothing here disturbs an environment I depend on.

## A note on the domain name

The AD domain is `corp.canyonpeaktech.com` — a subdomain of the public domain Canyon Peak owns — rather than something like `canyonpeak.local`. Microsoft has advised against `.local` for Active Directory for years: it's reserved for multicast DNS (mDNS/Bonjour), so it can collide with name resolution on any network running Apple devices or Linux hosts with Avahi, and no public CA will issue a certificate for it if you later need one. Delegating a subdomain of a domain you actually control is the current recommended pattern and handles split-brain DNS cleanly.

Staff still sign in as `first.last@canyonpeaktech.com` rather than the longer `@corp.canyonpeaktech.com`, using an alternative UPN suffix added in step 8. That keeps AD logon names identical to the email addresses and to the Okta usernames from Lab 01 — which matters, because Lab 02 matches AD accounts to existing Okta profiles by username.

## Prerequisites

- VMware Workstation (or Player) with ~60 GB free disk and 4–8 GB RAM to spare
- Windows Server 2022 evaluation ISO from the [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022) — 180-day eval, roughly 5 GB
- Around two hours; the OS install and the forest promotion are both slow

## Environment & technologies

- VMware Workstation — VM on the **NAT** network (VMnet8), isolated from the physical LAN
- Windows Server 2022 Standard, Desktop Experience
- Active Directory Domain Services (AD DS)
- DNS Server role (installed alongside AD DS)

### Why NAT rather than bridged

The VM sits on VMware's NAT network instead of being bridged onto the physical LAN. Bridging would put a second domain controller — with its own DNS service — directly onto the same network as my existing home lab, which is a good way to get two DCs answering DNS queries for clients that didn't ask for it. NAT gives the VM its own subnet with outbound internet (needed by the Okta AD Agent in Lab 02) while keeping it away from anything else on the network.

---

## Steps

### 1. Create the VM

In VMware Workstation: **File → New Virtual Machine → Custom (advanced)**.

| Setting | Value |
|---|---|
| Installation source | **I will install the operating system later** |
| Guest OS | Microsoft Windows → Windows Server 2022 |
| VM name | `CANYONPEAK-DC01` |
| Firmware | UEFI |
| Processors | 2 cores |
| Memory | 4096 MB minimum, 8192 MB if you can spare it |
| Network | **NAT** |
| Disk | 60 GB, *Store virtual disk as a single file* |

Choosing "install the OS later" matters — it skips VMware Easy Install, which otherwise auto-creates an account and picks an edition for you, and you want to make both of those choices deliberately.

After the wizard finishes: **Edit virtual machine settings → CD/DVD → Use ISO image file**, and point it at the Server 2022 ISO.

### 2. Install Windows Server 2022

Power on and press a key when prompted to boot from the ISO.

1. Language/keyboard → **Next** → **Install now**
2. Edition: **Windows Server 2022 Standard (Desktop Experience)** — the plain "Standard" entry is Server Core, which has no GUI. Desktop Experience is much easier to work in and to screenshot for a lab.
3. Accept the license terms → **Custom: Install Windows only**
4. Select the 60 GB disk → **Next**, then wait out the install and reboot
5. Set the local Administrator password when prompted. Record it — after promotion this becomes the *domain* Administrator account.

Then install VMware Tools (**VM → Install VMware Tools**, run setup from the mounted drive) for proper display scaling and mouse integration, and reboot.

📸 *Screenshot: Server Manager on first boot, showing the Desktop Experience install.*

### 3. Find the NAT subnet

VMware assigns a random subnet to VMnet8 per installation, so check yours rather than assuming.

On the **host**: **Edit → Virtual Network Editor** (needs admin) → select **VMnet8 (NAT)**. Note the subnet address, then open **NAT Settings** to see the gateway IP.

Typical layout, with `x` being your subnet's third octet:

| Address | Role |
|---|---|
| `192.168.x.1` | Host's virtual adapter |
| `192.168.x.2` | NAT gateway — this is the VM's default gateway |
| `192.168.x.128` – `.254` | VMware's DHCP pool |

Anything from `.3` to `.127` is outside the DHCP pool and safe to use statically. This walkthrough uses **`.10`**. Substitute your actual subnet everywhere below.

### 4. Set a static IP and hostname

A domain controller needs a stable address — its own DNS records point at it, and clients that can't resolve it can't log in.

In the guest, open PowerShell as Administrator:

```powershell
# Confirm the adapter name and current address (usually "Ethernet0" on VMware)
Get-NetIPConfiguration

# Drop DHCP, then assign the static address (substitute your subnet)
Set-NetIPInterface   -InterfaceAlias "Ethernet0" -Dhcp Disabled
New-NetIPAddress     -InterfaceAlias "Ethernet0" -IPAddress 192.168.x.10 -PrefixLength 24 -DefaultGateway 192.168.x.2

# Point DNS at itself - a DC must be authoritative for its own zone
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 192.168.x.10
```

Then rename the machine and reboot:

```powershell
Rename-Computer -NewName "CANYONPEAK-DC01" -Restart
```

📸 *Screenshot: `Get-NetIPConfiguration` showing the static address, gateway, and self-referencing DNS.*

### 5. Install the AD DS role

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```

Expect `Success : True` and `Exit Code : Success`. This installs the role but does **not** make the machine a domain controller yet.

### 6. Promote to a new forest

```powershell
Install-ADDSForest `
    -DomainName "corp.canyonpeaktech.com" `
    -DomainNetbiosName "CANYONPEAK" `
    -InstallDns `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM password") `
    -Force
```

Two deliberate choices here. `-InstallDns` adds and configures the DNS role as part of promotion, which is what you want for the first DC in a forest. And the DSRM password comes from `Read-Host` rather than being typed inline — that keeps it out of PowerShell history, out of any script file, and **out of your screenshots**. Directory Services Restore Mode is a separate break-glass credential used to boot the DC into recovery mode; give it its own password and store it somewhere you'll still have access to if the domain itself is broken.

The VM reboots automatically once promotion completes. This step takes several minutes.

📸 *Screenshot: the promotion completing, and the sign-in screen now showing `CANYONPEAK\Administrator`.*

### 7. Validate the forest before building on it

Don't move on until this is clean — every later lab assumes a healthy domain.

```powershell
Get-ADDomain  | Select-Object DNSRoot, NetBIOSName, DomainMode
Get-ADForest  | Select-Object Name, ForestMode, GlobalCatalogs
Get-Service ADWS, DNS, Netlogon, NTDS | Select-Object Name, Status
dcdiag /q
```

`Get-ADDomain` should return `corp.canyonpeaktech.com` / `CANYONPEAK`, all four services should be **Running**, and `dcdiag /q` should print nothing at all — it only reports failures, so silence is a pass.

📸 *Screenshot: `Get-ADDomain` output and the four services running.*

### 8. Fix DNS forwarding, then add the UPN suffix

**Forwarders first.** After promotion the DC resolves its own domain, but external lookups may not work — and in Lab 02 the Okta AD Agent has to reach Okta over the internet. Catching this now avoids a confusing failure later:

```powershell
Get-DnsServerForwarder
Set-DnsServerForwarder -IPAddress 1.1.1.1, 8.8.8.8
Resolve-DnsName okta.com    # must succeed before starting Lab 02
```

**Then the alternative UPN suffix.** By default every account's UPN would be `first.last@corp.canyonpeaktech.com`, but staff email — and the Okta usernames created in Lab 01 — use the shorter `@canyonpeaktech.com`. Registering it at the forest level lets accounts use the clean form:

```powershell
Set-ADForest -Identity (Get-ADForest) -UPNSuffixes @{Add="canyonpeaktech.com"}
Get-ADForest | Select-Object -ExpandProperty UPNSuffixes
```

GUI equivalent: Active Directory Domains and Trusts → right-click the forest root → Properties → UPN Suffixes → Add.

Once registered, `canyonpeaktech.com` appears in the UPN drop-down in ADUC, and the Lab 06 joiner script sets it automatically. Skip this and AD logon names won't match the Okta usernames, so the account matching in Lab 02 will fail.

📸 *Screenshot: `Resolve-DnsName okta.com` succeeding, and the UPN suffix listed.*

### 9. Build the base OU structure

```powershell
$base = "DC=corp,DC=canyonpeaktech,DC=com"
New-ADOrganizationalUnit -Name "CanyonPeak-Users"    -Path $base
New-ADOrganizationalUnit -Name "CanyonPeak-Groups"   -Path $base
New-ADOrganizationalUnit -Name "CanyonPeak-Disabled" -Path $base

Get-ADOrganizationalUnit -Filter 'Name -like "CanyonPeak-*"' | Select-Object Name, DistinguishedName
```

Three OUs, matching what Labs 02–06 expect: users, groups, and a holding area for offboarded accounts. Scoping the Okta AD Agent to just these in Lab 02 means the sync never touches built-in containers.

### 10. Create a delegated service account

The Lab 06 automation scripts need rights to create, modify, disable, and move AD objects. Running them as Domain Admin would work and would also be exactly the habit an IAM role is supposed to break — so this account gets rights over the three lab OUs and nothing else.

```powershell
New-ADUser -Name "svc-labautomation" -SamAccountName "svc-labautomation" `
    -UserPrincipalName "svc-labautomation@corp.canyonpeaktech.com" `
    -Path "DC=corp,DC=canyonpeaktech,DC=com" `
    -AccountPassword (Read-Host -AsSecureString "Service account password") `
    -PasswordNeverExpires $true -Enabled $true
```

Delegate control over each OU (`/I:T` applies to the OU and everything beneath it):

```powershell
foreach ($ou in "CanyonPeak-Users","CanyonPeak-Groups","CanyonPeak-Disabled") {
    dsacls "OU=$ou,DC=corp,DC=canyonpeaktech,DC=com" /I:T /G "CANYONPEAK\svc-labautomation:GA"
}
```

Confirm it took, and confirm the account is *not* privileged:

```powershell
dsacls "OU=CanyonPeak-Users,DC=corp,DC=canyonpeaktech,DC=com" | Select-String "svc-labautomation"
Get-ADUser svc-labautomation -Properties MemberOf | Select-Object -ExpandProperty MemberOf
```

That last command should return nothing — no Domain Admins, no privileged groups. `PasswordNeverExpires` is a lab convenience, not something to carry into production; a real deployment would use a Group Managed Service Account instead.

📸 *Screenshot: the three OUs in ADUC, and the delegation showing on `CanyonPeak-Users`.*

### 11. Snapshot the VM

With the forest, DNS, UPN suffix, OUs, and service account all verified: **VM → Snapshot → Take Snapshot**, named `post-promotion-baseline`.

If a later lab goes sideways, this is a two-minute recovery instead of rebuilding the domain. Worth noting the caveat, though: rolling a domain controller back from a snapshot is only safe here because this is a single-DC lab forest. In a multi-DC environment, restoring a DC snapshot risks USN rollback and needs a proper authoritative restore instead.

---

## Verification

- [ ] `Get-ADDomain` returns `corp.canyonpeaktech.com` / `CANYONPEAK`
- [ ] `dcdiag /q` produces no output
- [ ] AD DS, DNS, Netlogon, and ADWS are all Running
- [ ] `Resolve-DnsName okta.com` resolves — the Okta AD Agent depends on this in Lab 02
- [ ] `Get-ADForest | Select -ExpandProperty UPNSuffixes` lists `canyonpeaktech.com`
- [ ] `CanyonPeak-Users`, `CanyonPeak-Groups`, and `CanyonPeak-Disabled` exist
- [ ] `svc-labautomation` has delegated rights on those three OUs and belongs to no privileged group
- [ ] Snapshot `post-promotion-baseline` exists

## Notes

_(fill in as completed — VMware networking quirks, DNS resolution issues, anything that didn't go to plan)_

## Key takeaways

_(fill in once complete)_

---

[Series overview](../..) | [Lab 01 — Tenant Setup & Configuration ➡](../01-tenant-setup)
