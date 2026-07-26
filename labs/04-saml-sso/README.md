# Lab 04 — SAML SSO Application Integration

**Status:** Not started
**Scenario:** Standing up the app portfolio Canyon Peak's staff actually needs, with access gated by the role groups from Lab 03.

## Objective

Configure custom SAML 2.0 app integrations in Okta and wire them up to group-based access instead of individual assignment, so the least-privilege model from Lab 03 is enforced automatically at the application layer. Three apps, three different access footprints, to build a real access matrix rather than a single toy example.

## Prerequisites

- Labs 01–03 complete
- Systems Administrators and Security Analysts groups populated from Lab 03

## Environment & technologies

- Okta Application Integration Network (custom SAML 2.0 apps)
- Okta Universal Directory (group-based assignment)

## Apps for this lab

Picked to reflect tools Canyon Peak (an MSP) would realistically run, and loosely tied to tools already in my own resume/home lab:

| App | Purpose | Assigned groups |
|-----|---------|------------------|
| Freshservice PSA | Ticketing/service desk | Canyon Peak Employees (everyone) |
| Confluence Wiki | Internal documentation | IT Operations, Security Operations, Systems Administrators, Security Analysts |
| AWS Management Console | Cloud infrastructure access | Systems Administrators, Security Analysts only |

## Steps

### 1. Create the Freshservice SAML integration

Create App Integration → SAML 2.0. Configure a placeholder ACS URL and Audience URI (real values aren't needed for a lab — anything consistent works), NameID format of email, and application username mapped to email. Mark it as an internal app you've created when prompted.

### 2. Assign Freshservice to everyone

Assign the app to Canyon Peak Employees — this is the one tool the whole company touches, so it doesn't need role-based gating.

### 3. Create and scope Confluence

Repeat the SAML app creation for Confluence Wiki, this time assigning it to four groups: IT Operations, Security Operations, Systems Administrators, and Security Analysts. Client Services and Finance shouldn't see it — this creates the first real differentiation in the access matrix.

### 4. Create and scope AWS Console

Repeat again for AWS Management Console, assigned only to Systems Administrators and Security Analysts. This is the most sensitive app in the scenario and gets tightened further with step-up auth in Lab 05.

### 5. Verify from two different user perspectives

Sign in (incognito, or as a second browser profile) as a Client Services user and confirm only Freshservice appears on their dashboard. Then sign in as the Systems Administrator from Lab 03 and confirm all three apps appear.

## Verification

- Three SAML apps exist, each with a distinct ACS URL/Audience URI
- The access matrix table above matches what each test user actually sees on sign-in
- No app is assigned to an individual user directly — everything routes through groups

## Notes

_(fill in as completed)_

## Key takeaways

_(fill in once complete)_

---

⬅ [Lab 03 — RBAC Design & Implementation](../03-rbac-design) | [Lab 05 — MFA & Adaptive Authentication ➡](../05-mfa-adaptive-auth)
