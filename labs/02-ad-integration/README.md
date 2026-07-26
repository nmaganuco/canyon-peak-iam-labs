# Lab 02 — Active Directory Integration

**Status:** Not started
**Scenario:** Connecting Canyon Peak's new `canyonpeak.local` domain to the Okta tenant built in Lab 01.

## Objective

Move Canyon Peak from Okta-native identities to a hybrid model where Active Directory is the source of truth. This means installing the Okta AD Agent, syncing users and groups in, switching authentication to delegated (AD validates the password, not Okta), and proving that AD changes flow through to Okta without manual intervention.

## Prerequisites

- Lab 00 complete (`canyonpeak.local` domain controller live, with `CanyonPeak-Users`, `CanyonPeak-Groups`, and `CanyonPeak-Disabled` OUs in place)
- Lab 01 complete (Okta tenant with users/groups/policies)
- The four Lab 01 users and four department groups recreated as AD objects inside the `CanyonPeak-Users`/`CanyonPeak-Groups` OUs, matching the same names/attributes as the Okta side

## Environment & technologies

- Okta AD Agent
- Windows Server 2022, Active Directory Domain Services
- Active Directory Users and Computers (ADUC)
- VMware (matches home lab hypervisor)

## Steps

### 1. Install and register the AD Agent

From Okta: Directory → Directory Integrations → Add Directory → Active Directory, download the agent installer, and run it on the `canyonpeak.local` domain controller. Authenticate the agent against the Okta org during setup, and scope it to just the two OUs created above — no reason to expose the whole domain to sync.

### 2. Full import and confirm assignments

Run a Full Import from the Directory Integrations page. Review the matched users (Okta should offer to link each AD account to its existing Okta profile from Lab 01 by username match) and confirm the assignments. Enable auto-activation so confirmed users go straight to Active status.

### 3. Incremental import sanity check

Run an Incremental Import immediately after with no AD changes made. It should report zero changes — this is the baseline that proves the delta mechanism works before relying on it later.

### 4. Delegated authentication

Enable delegated authentication on the directory integration so Okta forwards password checks to `canyonpeak.local` instead of storing its own copy. Test it against one of the four existing users before rolling it out further.

### 5. Just-in-Time provisioning

Turn on JIT provisioning so a brand-new AD account can sign into Okta and get auto-created on first login, without waiting for a scheduled import. Validate this by creating a throwaway test account in AD (not one of the named scenario staff) and signing in as them before any import runs.

### 6. Attribute mapping check

Change one attribute on an AD user (e.g., update Jordan Lee's title in AD), run an incremental import, and confirm the change lands on the Okta profile. This proves the mapping between AD schema fields and the Okta custom attributes from Lab 01 is actually wired up correctly, not just coincidentally matching on initial import.

### 7. Group sync verification and cleanup

After AD groups sync in, Okta will likely end up with duplicate groups: the AD-linked ones and the original Okta-native ones from Lab 01. Compare membership, then delete the native (non-AD) versions of IT Operations, Security Operations, Client Services, Finance, and Canyon Peak Employees so AD becomes the single source going forward — keep only the AD-synced copies.

## Verification

- Directory Integrations page shows a healthy, recently-synced connection
- All four users' profiles show "Profile sourced by Active Directory"
- A brand-new AD test account can sign in and gets JIT-provisioned without a manual import
- An AD attribute edit reaches the Okta profile after an incremental import
- Only one copy of each department group remains, and it's AD-linked

## Notes

_(fill in as completed)_

## Key takeaways

_(fill in once complete)_

---

⬅ [Lab 01 — Tenant Setup](../01-tenant-setup) | [Lab 03 — RBAC Design & Implementation ➡](../03-rbac-design)
