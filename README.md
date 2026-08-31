# IAM Lab Series — Canyon Peak Technologies

A hands-on Okta/Active Directory series I'm building while studying for the **Okta Certified Professional Performance Exam**: one environment-build lab (Lab 00) followed by six Okta-focused labs. Every lab runs against a fictional company scenario — Canyon Peak Technologies — so the write-ups read as a real IAM portfolio project rather than a checklist.

The series walks the full identity lifecycle end to end — tenant → directory → access model → SSO → adaptive auth → automation — which is how these skills actually get used in an IAM Analyst role, not just how they get graded. Each lab's write-up records what I configured, what broke, and how I worked it out.

## The scenario

**Canyon Peak Technologies** is a fictional managed IT services company headquartered in Salt Lake City, UT — a nod to home turf. Canyon Peak supports client environments with a small internal team spread across IT Operations, Security Operations, Client Services, and Finance. As the "IAM Engineer" for this scenario, I'm standing up Canyon Peak's Okta tenant, integrating it with a dedicated Active Directory domain, and building out the access model, SSO, adaptive MFA, and lifecycle automation a growing MSP would actually need.

Fictional domain: `corp.canyonpeaktech.com` (AD) / `canyonpeaktech.com` (UPN suffix / email)

Fictional staff used throughout the labs (all invented, no real people):

| Name | Department | Role |
|------|-----------|------|
| Alex Rivera | IT Operations | Systems Administrator |
| Priya Nair | Security Operations | Security Analyst |
| Marcus Webb | Client Services | Support Technician |
| Jordan Lee | Finance | Financial Analyst |
| Sam Okafor | IT Operations | Joins mid-series (Lab 6) |

## Environment

This series gets its **own dedicated domain and VM**, deliberately kept separate from the home lab I already run day to day — so nothing here disturbs an environment I depend on.

- **Okta tenant:** Okta Integrator Free Plan (Identity Engine)
- **Domain controller:** new Windows Server 2022 VM, `corp.canyonpeaktech.com`
- **Hypervisor:** VMware (matches my existing home lab tooling)
- **Directory sync:** Okta AD Agent installed on the new domain controller

Full build steps for the VM and domain are in [Lab 00](labs/00-domain-controller-setup).

## Labs

| # | Lab | What it covers | Loosely maps to OCP exam domain |
|---|-----|-----------------|----------------------------------|
| 00 | [Domain Controller & AD Foundation](labs/00-domain-controller-setup) | New VM, Windows Server 2022, AD DS forest promotion, base OU structure, lab automation service account | Prerequisite — not a graded use case |
| 01 | [Tenant Setup & Configuration](labs/01-tenant-setup) | Org init, branding, users, custom attributes, groups, group rules, auth/session/enrollment policy basics | Account Creation & User Management (26%) |
| 02 | [Active Directory Integration](labs/02-ad-integration) | AD Agent install, full/incremental import, delegated auth, JIT provisioning, attribute & group sync | Prerequisite skill, feeds all later domains |
| 03 | [RBAC Design & Implementation](labs/03-rbac-design) | Role-based AD groups, access sprawl detection via System Log, leaver access revocation | Account Management (26%) + Troubleshooting (12%) |
| 04 | [SAML SSO Application Integration](labs/04-saml-sso) | Custom SAML app integrations, group-based access, multi-app access matrix | Application Setup with OIN (10%) |
| 05 | [MFA & Adaptive Authentication](labs/05-mfa-adaptive-auth) | Passwordless sign-in, network zones, risk-based policy, step-up auth, enrollment policy | Security Enforcement (38% — the big one) |
| 06 | [JML Lifecycle Management](labs/06-jml-automation) | Full joiner/mover/leaver cycle plus a batch of events, processed in AD and propagated to Okta | Attribute Mapping & Offboarding (8%) |

Weights reference the official [Okta Certified Professional Performance Exam Study Guide](https://certification.okta.com/page/professional-performance-exam-study-guide).

## Structure

```
labs/
  00-domain-controller-setup/ ... 06-jml-automation/
    README.md          objective, environment, steps, verification, notes
    screenshots/        supporting screenshots as I complete each lab
tools/
  Add-LabScreenshot.ps1        files screenshots into the right lab, numbered
RESOURCES.md
```

## Status

All seven labs complete, run end to end in the live environment. Each write-up carries verification steps, screenshots from the actual build, and Notes on what broke or surprised me along the way — the deviations are documented rather than reshot, because working out why something didn't behave is most of what these labs were for.
