# Lab 06 — JML Lifecycle Automation

**Status:** Not started
**Scenario:** Automating joiner/mover/leaver events against `corp.canyonpeaktech.com` with PowerShell, synced to Okta through the AD Agent from Lab 02.

## Objective

Replace manual AD Users and Computers clicking with scripts for the three lifecycle events that come up constantly in real IAM/sysadmin work: onboarding a new hire, moving someone between roles, and offboarding a leaver — plus a CSV-driven batch script that runs several of these in one pass, the way a real HR-feed-driven automation would.

## Prerequisites

- Labs 01–05 complete
- PowerShell 7 and the ActiveDirectory module available on the `corp.canyonpeaktech.com` domain controller
- A `CanyonPeak-Disabled` OU already exists (created in Lab 03 for the leaver exercise)

## Environment & technologies

- PowerShell 7 + ActiveDirectory module
- Okta AD Agent (incremental/full import to pull changes through)

## Scripts

All four scripts live in [`scripts/`](scripts) — see that folder for the actual code. Each one is intentionally small and readable rather than a fully productionized tool, since the point of this lab is understanding the AD-to-Okta sync mechanics, not building enterprise tooling.

| Script | Purpose |
|--------|---------|
| `New-CanyonPeakJoiner.ps1` | Creates a new AD user in the right OU and adds them to their department + role groups |
| `Update-CanyonPeakMover.ps1` | Moves a user from one department/role group to another |
| `Disable-CanyonPeakLeaver.ps1` | Disables the account, strips all group memberships, and moves it to the disabled OU |
| `Invoke-CanyonPeakBatch.ps1` | Reads a CSV of lifecycle events and runs the appropriate action per row |

## Steps

### 1. Joiner — onboard Sam Okafor

Run `New-CanyonPeakJoiner.ps1` to create Sam Okafor (the fifth staff member introduced back in the series overview) in IT Operations. Run an incremental import in Okta afterward and confirm Sam appears, active, in the IT Operations group.

### 2. Mover — Sam changes roles

A few "weeks" into the scenario, Sam moves from IT Operations into the Security Analysts role group from Lab 03. Run `Update-CanyonPeakMover.ps1` to remove the old group and add the new one, then sync and confirm the group change landed on the Okta side and the old membership is gone.

### 3. Leaver — offboard Sam

Run `Disable-CanyonPeakLeaver.ps1` against Sam's account. Sync and confirm the account shows Deactivated in Okta with zero group memberships — same end state as the manual leaver exercise in Lab 03, just automated this time.

### 4. Batch processing

Build a small CSV (`scripts/sample-batch.csv` has a starting template) listing two or three lifecycle events at once — e.g., one join and one leave in the same file — and run `Invoke-CanyonPeakBatch.ps1` against it. Run a full import afterward and verify every row's outcome landed correctly in Okta.

## Verification

- Each script runs cleanly against `corp.canyonpeaktech.com` with no manual AD console steps
- Okta reflects every AD-side change after the appropriate import
- The batch script correctly handles at least two different event types in a single run

## Notes

_(fill in as completed — worth documenting any AD permission issues, since the account running these scripts needs delegated rights to create/disable/move objects)_

## Key takeaways

_(fill in once complete)_

---

⬅ [Lab 05 — MFA & Adaptive Authentication](../05-mfa-adaptive-auth) | [Series overview](../..)
