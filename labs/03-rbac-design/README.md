# Lab 03 — RBAC Design & Implementation

**Status:** Not started
**Scenario:** Building a least-privilege access model on top of the AD/Okta integration from Lab 02, and proving it holds up under a real offboarding.

## Objective

Move beyond department groups (which are really just org-chart buckets) to role-based groups that actually gate access. Add two new role groups tied to functions Canyon Peak cares about — Systems Administrator and Security Analyst — assign users to exactly one role, verify the sync pipeline, then deliberately break and fix an access-sprawl scenario before running a full leaver offboarding.

## Prerequisites

- Labs 01–02 complete
- AD integration healthy, all four staff synced and active in Okta
- A SCIM-capable test app (Okta's SCIM 2.0 Test App works fine) added to the tenant for the access sprawl exercise

## Environment & technologies

- Active Directory Users and Computers
- Okta Universal Directory, System Log
- Okta AD Agent (already installed from Lab 02)

## Steps

### 1. Create role groups in AD

In `CanyonPeak-Groups`, create two new security groups: **Systems Administrators** and **Security Analysts**. These map directly to the two job families I'm actually targeting in my job search, which is part of why this lab matters beyond the exam.

### 2. Onboard two new role-based hires

Create two new AD users in `CanyonPeak-Users` — pick your own names or reuse the Lab 01 style — and assign one to Systems Administrators and one to Security Analysts. Add both to the Canyon Peak Employees group as well, same as every other staff member.

### 3. Sync and verify

Run a full import in Okta, confirm the new assignments, and check that both new hires appear in Canyon Peak Employees and in their respective role group — this time as AD-linked groups from the start, not native Okta groups that need cleanup later.

### 4. Manufacture and remediate access sprawl

Directly assign one existing user to the SCIM test app from the Okta Admin Console (bypassing group-based assignment entirely) — this simulates the kind of ad hoc access grant that erodes an RBAC model over time. Then go find it: filter the Okta System Log for `application.user_membership.add` events and locate the direct assignment. Remove it and confirm the app access model is clean again.

### 5. Full leaver offboarding

Pick one of the four original Lab 01 staff to leave the company. In AD: disable the account, move it to a `CanyonPeak-Disabled` OU, and remove them from every group. Run a sync in Okta and confirm the account moves to Deactivated status and drops out of every group — without touching anything in the Okta console directly. This is the point of the whole hybrid model: AD stays the single source of truth for lifecycle state.

## Verification

- Systems Administrators and Security Analysts groups exist in both AD and Okta with correct membership
- The manufactured direct app assignment is traceable in the System Log and has been removed
- The offboarded user shows Deactivated in Okta and has zero group memberships, driven entirely by the AD-side changes

## Notes

_(fill in as completed)_

## Key takeaways

_(fill in once complete — this is a good lab to reflect on how RBAC drift happens in real environments and what catches it)_

---

⬅ [Lab 02 — Active Directory Integration](../02-ad-integration) | [Lab 04 — SAML SSO Application Integration ➡](../04-saml-sso)
