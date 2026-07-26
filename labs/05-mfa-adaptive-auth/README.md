# Lab 05 — MFA & Adaptive Authentication

**Status:** Not started
**Scenario:** Tightening Canyon Peak's authentication posture — this is the single biggest domain on the OCP exam (38%), so it gets the most lab time in the whole series.

## Objective

Layer adaptive, risk-based authentication on top of the app portfolio from Lab 04: passwordless sign-in where it's safe, network-aware policy that treats off-network sign-ins as higher risk, mandatory step-up re-authentication for the AWS Console specifically, and an enrollment policy that stops weak fallback factors from ever satisfying MFA in the first place.

## Prerequisites

- Labs 01–04 complete
- Okta Verify installed on a personal device for testing

## Environment & technologies

- Okta Authenticators (Okta Verify, FastPass)
- Okta Authentication Policies (App Sign-In)
- Okta Network Zones
- Okta Authenticator Enrollment Policy

## Steps

### 1. Confirm Okta Verify is active

Security → Authenticators → Setup tab. Okta Verify should already be Active by default on a fresh tenant; if not, activate it before building anything that depends on it.

### 2. Passwordless policy for low-risk sign-in

Create an App Sign-In policy, **Passwordless — Low Risk Apps**, with a rule that accepts Okta Verify FastPass or TOTP as the only required factor — no password needed once the device is enrolled. Assign it to Freshservice, since it's the lowest-sensitivity app in the portfolio.

The first sign-in for any user still requires a password, because there's no enrolled factor yet to satisfy the policy — that's expected, not a bug, and worth noting in the write-up since it trips people up.

### 3. Define network zones

Security → Networks. Create two IP zones: **Canyon Peak HQ** (your own public IP, /32, as a stand-in for a real office network) and **Restricted Range** (a placeholder CIDR block, configured to block rather than allow). These get referenced as conditions in policy rules — they don't do anything on their own.

### 4. Risk-based rule split on the baseline policy

Go back to the Standard Access Policy from Lab 01 and split it into two rules: one that allows single-factor auth when the sign-in originates from the Canyon Peak HQ zone, and one that requires password + a second factor for everything outside it. Assign Confluence Wiki to this policy so the split is actually exercised. Note that assigning an app to a new policy silently removes it from whatever policy it was on before — also worth calling out in the write-up.

### 5. Step-up authentication for AWS Console

Create a dedicated **High-Sensitivity Access Policy** with a rule requiring password + a second factor and forcing re-authentication on every single access attempt, regardless of an existing session. Assign this to the AWS Management Console app from Lab 04 — this is the one resource in the scenario that should never be reachable on a stale session.

### 6. Lock down the enrollment policy

Update the enrollment policy from Lab 01: require Okta Verify, disable email as a fallback factor entirely, for the Canyon Peak Employees group. Test this against a user who has never enrolled a factor before (a fresh AD account is the cleanest way to verify this — an existing user who already enrolled Okta Verify earlier in testing won't trigger the prompt).

## Verification

- A user signing in to Freshservice from anywhere is only prompted for Okta Verify (after initial enrollment)
- The same user signing in to Confluence from off the HQ IP zone is prompted for password + a second factor
- Signing in to AWS Console prompts for re-authentication even with an active session elsewhere
- A never-enrolled test user is forced into Okta Verify enrollment and cannot fall back to email

## Notes

_(fill in as completed)_

## Key takeaways

_(fill in once complete — given this is 38% of the exam, worth writing a more thorough retro here than the other labs)_

---

⬅ [Lab 04 — SAML SSO Application Integration](../04-saml-sso) | [Lab 06 — JML Lifecycle Automation ➡](../06-jml-automation)
