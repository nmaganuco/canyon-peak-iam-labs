# Lab 01 — Tenant Setup & Configuration

**Status:** Not started
**Scenario:** Standing up the Canyon Peak Technologies Okta tenant and its initial identity foundation.

## Objective

Build a production-shaped Okta org from an empty tenant: organization profile, branding, a handful of user identities, a custom attribute schema, department groups with automated membership, and baseline security policy. Everything built here is what the rest of the series (AD integration, RBAC, SSO, MFA, automation) gets layered on top of.

## Prerequisites

- Okta Integrator Free Plan tenant created at developer.okta.com
- Lab 00 complete (this lab is Okta-side only — it doesn't touch the domain controller yet)

## Environment & technologies

- Okta Identity Cloud (Integrator Free Plan)
- Okta Admin Console, Universal Directory, Profile Editor
- Okta Group Rules (Okta Expression Language)
- Okta Authentication Policies, Global Session Policy, Authenticator Enrollment Policy

## Steps

### 1. Organization profile

Set the org's identity in Settings → Account → Organization Contact: company name **Canyon Peak Technologies**, Salt Lake City, UT address, and a support contact. This is what shows up in system emails and audit trail entries, so it's worth getting right before anything else is built.

### 2. Branding

Under Customizations → Brands, create a brand for Canyon Peak: a simple logo/wordmark, a primary accent color, and a favicon. Apply a solid-background theme to the sign-in page, end-user dashboard, and error pages so the tenant doesn't look like a stock Okta trial.

### 3. Custom attribute schema

Before creating users, extend the default profile schema in Directory → Profile Editor → User (default). Add:

- `department` (string) — drives the group rules in step 5
- `costCenter` (string) — internal cost-center code, unused for logic but realistic for an MSP's directory
- `title` (string, if not already present) — job title

### 4. Create user identities

Create the five Canyon Peak staff from the scenario table in the top-level README (Alex Rivera, Priya Nair, Marcus Webb, Jordan Lee — Sam Okafor joins later in Lab 06, don't create them yet). For each: first/last name, username/email on `canyonpeaktech.com`, a temporary password with "must change on first login" enabled, and their `department`/`title`/`costCenter` values filled in.

### 5. Department groups + group rules

Create four groups: **IT Operations**, **Security Operations**, **Client Services**, **Finance**, plus a catch-all **Canyon Peak Employees** group. Manually assign all four staff to Canyon Peak Employees. Then build group rules using the `department` attribute so IT Operations/Security Operations/Client Services/Finance membership is assigned automatically instead of by hand — this is the pattern that later gets replaced by AD-driven group sync in Lab 02, so it's worth seeing the "before" state.

### 6. Baseline authentication policy

Create an App Sign-In policy named **Standard Access Policy** with two rules: a permissive default (password only) and a stricter rule requiring password + a second factor. Don't assign it to anything yet — Lab 05 builds out the real adaptive logic on top of this.

### 7. Global session policy

Create a session policy assigned to Canyon Peak Employees with an 8-hour max session lifetime and a 30-minute idle timeout (tighter than a typical default, reflecting an MSP handling client data).

### 8. Authenticator enrollment policy

Create an enrollment policy assigned to Canyon Peak Employees that allows enrollment in Okta Verify and requires it be available as an option — full enforcement gets tightened in Lab 05 once adaptive policies are in place.

## Verification

- All four staff show up under Directory → People with correct department/title/cost center attributes
- Each of the four department groups shows the right members via the group rules (test this by editing one user's `department` and confirming they move groups automatically)
- Sign-in as one test user succeeds against the baseline policy

## Notes

_(fill in as completed — anything that didn't match the plan, any Okta UI quirks encountered, etc.)_

## Key takeaways

_(fill in once complete)_

---

⬅ Series overview | [Lab 02 — Active Directory Integration ➡](../02-ad-integration)
