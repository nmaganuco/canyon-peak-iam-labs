# Lab 01 — Tenant Setup & Configuration

**Status:** Not started
**Scenario:** Standing up the Canyon Peak Technologies Okta tenant and its initial identity foundation.

## Objective

Build a production-shaped Okta org from an empty tenant: organization profile, branding, a custom attribute schema, the Canyon Peak staff, department groups with automated membership, and baseline security policy. Everything here is what the rest of the series — AD integration, RBAC, SSO, adaptive MFA, lifecycle automation — gets layered on top of.

This lab is entirely in the Okta Admin Console, so it's all GUI. That's not a compromise: the Okta Certified Professional exam is performance-based in this same console, so the clicking *is* the practice. Everything below can also be done through the Okta API or Terraform, which is how it would be managed at scale — see Key takeaways.

## Prerequisites

- Lab 00 complete (the domain controller isn't touched until Lab 02, but the labs build in order)
- An email address you can receive mail at, for the Okta org signup

## Environment & technologies

- Okta Identity Engine — Integrator Free Plan
- Okta Admin Console, Universal Directory, Profile Editor
- Okta Group Rules (Okta Expression Language)
- Okta Authentication Policies, Global Session Policy, Authenticator Enrollment Policy

### Watch the user budget

The Integrator Free Plan allows **10 active users**. The series needs most of them: four staff here, a throwaway JIT test account in Lab 02, two role-based hires in Lab 03, and Sam Okafor plus a batch hire in Lab 06 — plus your own admin account. Deactivated users don't count against the cap, so the leaver exercises in Labs 03 and 06 give headroom back. Just don't create spare test accounts casually.

Also worth knowing: an Integrator org deactivates if nobody signs in for 180 consecutive days. Not a concern mid-series, but don't be surprised if you come back to this in a year.

---

## Steps

### 1. Create the Okta org

Sign up for an Integrator Free Plan org at [developer.okta.com](https://developer.okta.com/signup/). You'll get an org URL of the form `https://dev-XXXXXXXX.okta.com` and an activation email.

Activate the account, sign in, and **enable MFA on your own admin account immediately** if you aren't prompted to. It's the keys to the entire tenant, and every later lab assumes you still have access to it.

Record the org URL, admin email, and admin password in your credentials file — outside the repo.

### 2. Organization profile

**Settings → Account → Organization Contact → Edit.**

| Field | Value |
|---|---|
| Company name | Canyon Peak Technologies |
| Address | 400 W Canyon Ridge Dr |
| City / State / Zip | Salt Lake City, UT 84101 |
| Country | United States |

These values appear in Okta-generated emails and in the audit trail, which is why it's worth setting before anything else exists to be audited.

### 3. Branding

**Customizations → Brands → Create Brand**, named `Canyon Peak Technologies`.

On the **Theme** tab set a primary colour — `#2F5D50`, a muted canyon green, works and looks deliberate rather than default. Upload a simple logo and favicon if you have one; a plain wordmark is fine.

On the **Pages** tab, open **Sign-In Page → Configure**, choose the solid background option, then **Save and Publish**. Do the same for the **End-User Dashboard** and **Error Pages**.

Sign out and load your org URL to see the result. A branded sign-in page is a small thing that makes the tenant read as a real deployment rather than a trial.

📸 *Screenshot: the branded Canyon Peak sign-in page.*

### 4. Custom profile attributes

Do this **before** creating users, so the fields exist to be populated at creation rather than needing a second pass.

**Directory → Profile Editor → User (default) → Add Attribute.**

| Display name | Variable name | Data type | Description |
|---|---|---|---|
| Department | `department` | string | Drives the group rules in step 7 |
| Cost Center | `costCenter` | string | Internal billing code |
| Job Title | `title` | string | May already exist in the default schema — check first |

`department` is the one that matters: it's the attribute the group rules key off, and in Lab 02 it's the attribute that has to map cleanly from Active Directory. The others are there because a real MSP directory carries more than the minimum.

📸 *Screenshot: Profile Editor showing the custom attributes on the default user profile.*

### 5. Create the Canyon Peak staff

**Directory → People → Add Person**, four times. Sam Okafor joins in Lab 06 — don't create him yet.

| First | Last | Username / email | Department | Job Title | Cost Center |
|---|---|---|---|---|---|
| Alex | Rivera | alex.rivera@canyonpeaktech.com | IT Operations | Systems Administrator | CC-1010 |
| Priya | Nair | priya.nair@canyonpeaktech.com | Security Operations | Security Analyst | CC-1020 |
| Marcus | Webb | marcus.webb@canyonpeaktech.com | Client Services | Support Technician | CC-2010 |
| Jordan | Lee | jordan.lee@canyonpeaktech.com | Finance | Financial Analyst | CC-3010 |

For each: tick **I will set password**, set a temporary password, and tick **User must change password on first login**. Record the temporary passwords in your credentials file.

The custom attributes appear further down the Add Person form once you've created them in step 4. If they don't, you've likely added them to a different profile than **User (default)**.

📸 *Screenshot: Directory → People showing all four staff, and one user's profile with department, title, and cost center populated.*

### 6. Create groups

**Directory → Groups → Add Group**, five times:

- `Canyon Peak Employees` — everyone, used as the target for session and enrollment policy
- `IT Operations`
- `Security Operations`
- `Client Services`
- `Finance`

Then open **Canyon Peak Employees → People → Assign People** and add all four staff manually. This one stays manual because it's the catch-all; the department groups get automated next.

### 7. Group rules

This is the interesting part of the lab. Rather than assigning department groups by hand, let Okta do it from the `department` attribute.

**Directory → Groups → Rules tab → Add Rule.**

| Rule name | Condition | Assign to |
|---|---|---|
| Assign IT Operations | User Attribute `department` equals `IT Operations` | IT Operations |
| Assign Security Operations | User Attribute `department` equals `Security Operations` | Security Operations |
| Assign Client Services | User Attribute `department` equals `Client Services` | Client Services |
| Assign Finance | User Attribute `department` equals `Finance` | Finance |

Save each, then **Actions → Activate** — a rule does nothing until it's activated, which is easy to miss.

**Prove it works rather than assuming.** Edit Marcus Webb's profile, change `department` from `Client Services` to `Finance`, save, and watch him leave one group and join the other without you touching group membership. Then change it back. That's the whole point of attribute-driven access, and seeing it happen is worth more than reading about it.

📸 *Screenshot: the four rules showing Active, and Marcus Webb's group membership changing after the attribute edit.*

### 8. Baseline authentication policy

**Security → Authentication Policies → Create Policy**, named `Standard Access Policy`, described as *Baseline access requirements for Canyon Peak staff*.

Add two rules:

| Rule name | Access is | User must authenticate with |
|---|---|---|
| Password only | Allowed after successful authentication | Password |
| Require MFA | Allowed after successful authentication | Password + Another factor |

Leave it unassigned to any application for now. Lab 05 builds the real adaptive logic on top of this — network zones, step-up authentication, passwordless — and assigning it prematurely just means undoing it later.

📸 *Screenshot: the Standard Access Policy with both rules.*

### 9. Global session policy

**Security → Global Session Policy → Add Policy**, named `Canyon Peak Standard Session`, assigned to the **Canyon Peak Employees** group. Then add a rule:

| Setting | Value |
|---|---|
| Maximum Okta session lifetime | 8 hours |
| Maximum idle time | 30 minutes |
| Persist session cookies across browser sessions | Disabled |

Tighter than Okta's defaults, deliberately. Canyon Peak is an MSP with access to client environments, so an unattended session is a bigger problem than it would be at a company whose data is only its own. Being able to explain *why* a value was chosen matters more than the value.

### 10. Authenticator enrollment policy

**Security → Authenticators → Enrollment tab → Add a Policy**, named `Canyon Peak Enrollment`, assigned to **Canyon Peak Employees**.

For now, allow enrollment in Okta Verify and leave Password required. Lab 05 tightens this — disabling email as a fallback factor and making Okta Verify mandatory — once adaptive policy is in place to support it.

### 11. Verify as an end user

Open a private/incognito window, go to your org URL, and sign in as one of the four staff with their temporary password. You should be forced to change the password, then land on the branded end-user dashboard.

This is the first time the tenant is exercised as a user rather than an admin, and it's the check that catches policy mistakes that look fine from the admin console.

📸 *Screenshot: the end-user dashboard for a Canyon Peak staff member.*

---

## Verification

- [ ] Sign-in page shows Canyon Peak branding
- [ ] `department`, `costCenter`, and `title` exist on the default user profile
- [ ] Four staff exist with all attributes populated
- [ ] Five groups exist; Canyon Peak Employees contains all four staff
- [ ] All four group rules show **Active**
- [ ] Changing a user's `department` moves them between groups automatically
- [ ] Standard Access Policy exists with both rules
- [ ] Global session policy applies to Canyon Peak Employees at 8h / 30m
- [ ] A staff member can sign in and reach the branded dashboard

## Before you commit screenshots

Your org URL (`dev-XXXXXXXX.okta.com`) is visible in the browser bar of nearly every screenshot in this lab. It isn't a secret — it's not usable without credentials — but it is a live tenant you control, and blurring it costs nothing. Decide once and be consistent.

Nothing else here is sensitive: the staff are fictional, and the temporary passwords should never appear on screen if you set them in the form rather than displaying them afterward.

**This is also the lab to test Scribe.** It's entirely browser-based, which is where Scribe works best. Export a Scribe to Markdown and check whether the `![...]()` references point at local image files or at Scribe-hosted URLs. If they're hosted URLs, don't commit them — the evidence wouldn't actually live in this repo, and it would break the day the Scribe is deleted.

## Notes

_(fill in as completed — Okta UI quirks, anything that didn't match the plan)_

## Key takeaways

_(fill in once complete. Worth thinking about: why attribute-driven group membership beats manual assignment; what happens to these Okta-native groups once Active Directory becomes the source of truth in Lab 02; and how this configuration would be managed as code — Okta's API or the Terraform provider — in an environment with more than four users.)_

---

⬅ [Lab 00 — Domain Controller & AD Foundation](../00-domain-controller-setup) | [Lab 02 — Active Directory Integration ➡](../02-ad-integration)
