# Lab 02 — Active Directory Integration

**Status:** Not started
**Scenario:** Connecting Canyon Peak's `corp.canyonpeaktech.com` domain to the Okta tenant, and bringing the employee population in from the directory that owns it.

## Objective

Install the Okta AD Agent, import Canyon Peak's employees from Active Directory, switch their authentication to delegated so AD validates passwords rather than Okta, and prove that directory changes flow through without manual intervention.

The interesting part isn't the plumbing. It's what happens to the group rules written in Lab 01: they were built against two Okta-native contractors, with two of the four rules matching nobody. When the AD staff arrive carrying `department` values, those dormant rules fire on identities from an entirely different source, with no additional configuration. That's the clearest demonstration there is that attribute-driven access doesn't care where an identity came from.

## The two populations

After this lab the tenant holds both halves of a real hybrid deployment:

| Population | Source | Created | Lifecycle managed in |
|---|---|---|---|
| Dana Whitfield, Theo Marsh | Okta-native | Lab 01, by hand | Okta |
| Alex Rivera, Priya Nair, Marcus Webb, Jordan Lee | Active Directory | This lab, via import | Active Directory |

Contractors were never in the corporate directory and never will be. Employees belong to AD because that's where their employment lifecycle lives — hiring, role changes, and termination all happen there, which is exactly what Lab 06 automates.

## Prerequisites

- Lab 00 complete — `corp.canyonpeaktech.com` DC live, the three `CanyonPeak-*` OUs in place, `canyonpeaktech.com` registered as an alternative UPN suffix
- Lab 01 complete — Okta tenant with groups, group rules, and policies configured
- **`Resolve-DnsName okta.com` succeeds on the domain controller.** The agent has to reach Okta over the internet, and a DC that resolves its own zone but nothing external fails the install in a way that looks like an agent problem. This is Lab 00 step 8; confirm it before going further.
- A current VMware snapshot of the DC. The agent install modifies the machine, and rolling back is easier than uninstalling cleanly.

### Watch the user budget

This lab takes you from 3 active users to 8 of your 10: four employees imported, plus one throwaway JIT test account. Deactivate the test account when step 11 is done rather than leaving it consuming a slot.

## Environment & technologies

- Okta AD Agent
- Windows Server 2022, Active Directory Domain Services
- Active Directory Users and Computers (ADUC), Delegation of Control
- Okta Admin Console — Directory Integrations, Profile Editor, Global Session Policy

---

## Steps

### 1. Create a dedicated service account for the agent

The installer will offer to create an account called `OktaService` for you, or run as a Domain Admin. Neither is what you want. Okta's own guidance is explicit that a scoped account "avoids making your service account a full admin," and after deliberately delegating `svc-labautomation` in Lab 00 it would be odd to hand the agent the keys to the domain now.

This also stays separate from `svc-labautomation`. The two accounts do different jobs — one syncs a directory, one runs lifecycle scripts — and a compromise of either shouldn't grant the other's rights.

In ADUC, create a user in the domain root:

| Field | Value |
|---|---|
| Full name | `svc-oktaagent` |
| User logon name | `svc-oktaagent` @ `corp.canyonpeaktech.com` |
| Password never expires | Yes |
| User must change password at next logon | No |

Record the password in your credentials file.

**Delegate the permissions it actually needs.** The two OUs take different wizard paths, because the built-in task list only covers user objects.

**On `CanyonPeak-Users`** — right-click → **Delegate Control** → **Next** → **Add** `svc-oktaagent` → **Next** → choose **Delegate the following common tasks**, and tick:

- **Read all user information** — required for import
- **Reset user passwords and force password change at next logon** — required for delegated authentication and later self-service password reset

**Next → Finish.**

**On `CanyonPeak-Groups`** — the common task list offers only *Create, delete and manage groups* and *Modify the membership of a group*, both of which are far more than the agent needs. Take the other branch instead: right-click → **Delegate Control** → **Next** → **Add** `svc-oktaagent` → **Next** → **Create a custom task to delegate** → **Only the following objects in the folder** → tick **Group objects** → **Next** → under **General**, tick **Read** → **Next → Finish**.

Read-only is enough because nothing writes groups back to AD. The group objects themselves get created by hand in Lab 03.

That's deliberately narrower than Okta's full provisioning permission set. Creating and deleting AD accounts from Okta would additionally need write access to `sAMAccountName`, `userPrincipalName`, `userAccountControl` and others — but nothing in this series provisions *into* AD from Okta. Lab 06 writes to AD via PowerShell as `svc-labautomation` instead, so the agent never needs those rights.

One gap worth knowing about: the common task grants *Reset Password* and write on `pwdLastSet`, but not write on `lockoutTime`. If you later want Okta to perform self-service account **unlock** as well as password reset, that needs adding through the custom-task path against user objects.

<details>
<summary>PowerShell equivalent</summary>

```powershell
New-ADUser -Name "svc-oktaagent" -SamAccountName "svc-oktaagent" `
    -UserPrincipalName "svc-oktaagent@corp.canyonpeaktech.com" `
    -Path "DC=corp,DC=canyonpeaktech,DC=com" `
    -AccountPassword (Read-Host -AsSecureString "Okta agent service account password") `
    -PasswordNeverExpires $true -Enabled $true
```

Delegation is clearer through the wizard than through `dsacls` here, because the reset-password control access right is awkward to express on the command line.
</details>

📸 *Screenshot: the Delegation of Control wizard showing the two permissions granted to `svc-oktaagent`.*

### 2. Create the Canyon Peak employees in Active Directory

**ADUC → `CanyonPeak-Users` → right-click → New → User**, four times.

| First | Last | User logon name | UPN suffix | Department | Job title |
|---|---|---|---|---|---|
| Alex | Rivera | `alex.rivera` | `@canyonpeaktech.com` | IT Operations | Systems Administrator |
| Priya | Nair | `priya.nair` | `@canyonpeaktech.com` | Security Operations | Security Analyst |
| Marcus | Webb | `marcus.webb` | `@canyonpeaktech.com` | Client Services | Support Technician |
| Jordan | Lee | `jordan.lee` | `@canyonpeaktech.com` | Finance | Financial Analyst |

**Select `canyonpeaktech.com` from the UPN suffix drop-down, not `corp.canyonpeaktech.com`.** This is why Lab 00 registered the alternative suffix. The UPN becomes the Okta username, and using the short form keeps employees consistent with the contractors created in Lab 01 — everyone is `first.last@canyonpeaktech.com` regardless of where their identity lives.

Set `department` and `title` on each user's **Organization** tab after creation. `department` is the one that matters — it's what the Lab 01 group rules key on, and step 6 depends on it being populated before the first import.

**A mapping note worth understanding.** `department` and `title` exist natively in the AD schema and map straight through. `costCenter` and `clientAccount` don't — AD has no equivalent, so imported employees will have those fields empty in Okta. Carrying them would mean mapping AD's `extensionAttribute1`–`15` onto Okta attributes, which is exactly how this gets solved in real deployments and is worth knowing exists. Leave them empty here; the contractors have them because they were created natively.

<details>
<summary>PowerShell equivalent</summary>

```powershell
$ou = "OU=CanyonPeak-Users,DC=corp,DC=canyonpeaktech,DC=com"
$staff = @(
    @{First="Alex";   Last="Rivera"; Dept="IT Operations";       Title="Systems Administrator"}
    @{First="Priya";  Last="Nair";   Dept="Security Operations"; Title="Security Analyst"}
    @{First="Marcus"; Last="Webb";   Dept="Client Services";     Title="Support Technician"}
    @{First="Jordan"; Last="Lee";    Dept="Finance";             Title="Financial Analyst"}
)

foreach ($s in $staff) {
    $sam = ("{0}.{1}" -f $s.First, $s.Last).ToLower()
    New-ADUser -Name "$($s.First) $($s.Last)" -GivenName $s.First -Surname $s.Last `
        -SamAccountName $sam -UserPrincipalName "$sam@canyonpeaktech.com" -Path $ou `
        -AccountPassword (ConvertTo-SecureString (Read-Host "Password for $sam") -AsPlainText -Force) `
        -ChangePasswordAtLogon $true -Enabled $true `
        -OtherAttributes @{ department = $s.Dept; title = $s.Title }
}
```
</details>

### 3. Install and register the AD Agent

**In Okta: Directory → Directory Integrations → Add Directory → Add Active Directory.** Follow the **Set Up Active Directory** prompt, then **Download Agent** — or copy the download link and paste it into a browser on the domain controller, which saves transferring the installer.

On the DC, run the installer:

- When asked for the service account, choose **use an existing account** and supply `svc-oktaagent` with its password. Don't let it create `OktaService`, and don't give it a Domain Admin.
- When prompted, sign in with your **Okta org admin credentials** to register the agent against the tenant.
- Accept the default proxy settings unless your network needs otherwise.

Back in Okta, the new directory appears under **Directory Integrations**. Open it and check the agent shows as connected.

📸 *Screenshot: Directory Integrations showing the agent connected and healthy.*

### 4. Scope the integration

Immediately after registration, Okta walks you through configuration.

On the **Connect an Organizational Unit to Okta** page, select **only** `CanyonPeak-Users` and `CanyonPeak-Groups`. Leave `CanyonPeak-Disabled` and every built-in container unticked — there's no reason to expose the whole domain to sync, and scoping tightly here is what makes the leaver exercises in Labs 03 and 06 behave predictably.

On the **Select Attributes** page, accept the defaults. `department` and `title` are among them.

Finish the wizard.

**Note that no AD groups get synced in this lab.** `CanyonPeak-Groups` is scoped for later, but it's currently empty — Lab 03 creates the role-based groups that live there. Employee group membership in Okta comes from the Lab 01 group rules instead, which is the whole point of step 6.

### 5. Run the first full import

**Directory → Directory Integrations →** your directory **→ Import tab → Import Now → Full Import.**

When it completes, Okta lists the users it found. Tick all four, then **Confirm Assignments**, and check **Auto-activate users after confirmation** so they land Active rather than pending.

Then open **Directory → People → Alex Rivera → Profile** and confirm it reads **sourced by Active Directory**. That phrase is the whole point of the lab — his profile is no longer editable in Okta, because AD owns it now.

📸 *Screenshot: the import results, and a profile showing "sourced by Active Directory".*

### 6. Watch the Lab 01 group rules fire

This is the step worth slowing down for.

**Directory → Groups.** Without touching a single group assignment, you should find:

| Group | Members |
|---|---|
| IT Operations | Alex Rivera |
| Security Operations | Priya Nair, Dana Whitfield |
| Client Services | Marcus Webb, Theo Marsh |
| Finance | Jordan Lee |

The IT Operations and Finance rules were dormant in Lab 01 with nobody to catch. Security Operations and Client Services now hold one contractor and one employee each — identities from two different sources, assigned by the same rule, with no configuration added between then and now.

That's what attribute-driven access buys you. The rule expresses intent — *people in Finance get the Finance group* — and stays correct as the population changes underneath it. A manually maintained membership list would have needed four edits.

📸 *Screenshot: a department group containing both a contractor and an AD-sourced employee.*

### 7. Populate the employee group and give it a session policy

**Directory → Groups → Canyon Peak Employees → Assign People**, and add the four staff.

Manual, deliberately, and for the same reason Canyon Peak Contractors was manual in Lab 01: "is an employee" is a statement about the employment relationship, not something derivable from a profile attribute. Group rules are the right tool for attributes and the wrong tool for facts about a person's contract.

Then **Security → Global Session Policy → Add Policy**, named `Canyon Peak Employee Session`, assigned to **Canyon Peak Employees**:

| Setting | Value |
|---|---|
| Maximum Okta session lifetime | 8 hours |
| Maximum idle time | 1 hour |
| Persist session cookies across browser sessions | Disabled |
| Multifactor authentication | Not required |

Twice the lifetime and four times the idle allowance the contractors get. Employees work on managed devices, on a corporate network, with an employment relationship behind them — the risk of a stale session is genuinely lower. Being able to articulate that difference is more useful than either number.

Check the policy priority. Canyon Peak Contractors should evaluate before Canyon Peak Employees, so that if anyone ever lands in both, the tighter policy wins.

### 8. Incremental import baseline

**Import tab → Import Now → Incremental Import**, with no AD changes made.

It should report zero users and zero groups scanned. That's the point — you're establishing that the delta mechanism works while you know there's nothing to find, so that when it reports nothing later you can trust it rather than wonder.

### 9. Delegated authentication

**Directory Integrations →** your directory **→ Provisioning tab → Integration.** Find **Delegated Authentication** and enable *Allow Delegated Authentication to Active Directory*, then **Save**.

From this point Okta stops storing a password for AD-sourced users and forwards credential checks to the domain controller. Employees sign in with their Windows password; contractors keep using Okta-held passwords, since they have no AD account.

Click **Test Delegated Authentication**, supply Alex Rivera's AD credentials, and confirm it returns success.

📸 *Screenshot: the delegated authentication test returning successful.*

**Worth thinking about:** this is a real availability trade. Employee sign-in now depends on the domain controller being reachable and the agent being healthy. If the DC is down, employees can't authenticate to anything behind Okta. Contractors still can — their credentials never left the cloud. That asymmetry is a genuine argument for keeping a break-glass admin account Okta-native.

### 10. Just-in-Time provisioning

**Provisioning tab → To Okta → General → Edit**, tick **Create and update users on login** under JIT Provisioning, and **Save**.

Test it properly: create a throwaway account in AD — `test.jit` in `CanyonPeak-Users`, not one of the named staff — and **without running any import**, sign in to your Okta org as that user in a private window.

Then check **Directory → People**. The account exists, created at the moment of sign-in rather than on an import schedule.

This is what makes AD the genuine source of truth. A new hire created in AD on Monday morning can reach Okta immediately, rather than waiting for the next scheduled import.

📸 *Screenshot: the JIT-provisioned account in Directory → People, created without an import.*

**Deactivate `test.jit` when you're done** — it's consuming one of your ten user slots.

### 11. Attribute mapping check

Initial imports can match by coincidence. This proves the mapping is actually wired.

In ADUC, open **Jordan Lee → Properties → Organization**, change **Job title** to `Senior Financial Analyst`, and apply.

Back in Okta, run an **Incremental Import**. Unlike step 8 it should report one user scanned. Then check **Directory → People → Jordan Lee → Profile** and confirm the title updated.

For a stronger version of the same test, change Marcus Webb's `department` in AD from `Client Services` to `Finance`, import, and watch the Lab 01 group rules move him between groups — a change made in Active Directory driving group membership in Okta with nothing in between. Change it back afterwards.

📸 *Screenshot: an AD attribute change reflected on the Okta profile after an incremental import.*

---

## Verification

- [ ] `svc-oktaagent` exists with delegated read and password-reset rights, and is not a Domain Admin
- [ ] Four employees exist in `CanyonPeak-Users` with `canyonpeaktech.com` UPNs and `department` populated
- [ ] Directory Integrations shows the agent connected and recently synced
- [ ] All four employees show **sourced by Active Directory**
- [ ] Department groups contain the correct mix of contractors and employees, assigned entirely by the Lab 01 rules
- [ ] Canyon Peak Employees contains the four staff
- [ ] Employee session policy applies at 8h / 1h, evaluated after the contractor policy
- [ ] An incremental import with no changes reports zero scanned
- [ ] Delegated authentication test succeeds against an AD credential
- [ ] A new AD account signs in and is JIT-provisioned without an import
- [ ] An AD attribute change reaches the Okta profile after an incremental import
- [ ] `test.jit` deactivated

## Before you commit screenshots

Same as Lab 01 for the org URL. New in this lab: the **agent registration token** appears once during installation — don't capture it, and don't record it anywhere. If you lose it, deregister the agent in Okta and re-run the installer.

Also avoid capturing the `svc-oktaagent` password during the installer's credential prompt, and be careful with any screenshot of the DC that includes the domain admin session.

## Notes

_(fill in as completed — agent install issues, certificate or proxy problems, attribute mapping surprises)_

## Key takeaways

_(fill in once complete. Worth thinking about: what "sourced by Active Directory" actually changes about who can edit a profile; why the agent gets its own scoped service account rather than reusing one or running as Domain Admin; what delegated authentication does to your availability model, and which accounts should deliberately stay independent of it; the difference between JIT provisioning and scheduled import, and when each matters; and why group rules kept working across a change of identity source without being touched.)_

---

⬅ [Lab 01 — Tenant Setup & Configuration](../01-tenant-setup) | [Lab 03 — RBAC Design & Implementation ➡](../03-rbac-design)
