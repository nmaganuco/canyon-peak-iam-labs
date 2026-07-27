# Tools

## `Add-LabScreenshot.ps1`

Files a screenshot into the correct lab folder with consistent numbering and prints the Markdown line to paste into the write-up.

**Workflow while running a lab:**

1. Press `Win + PrtScn` to capture. Windows saves straight to `Pictures\Screenshots` — no save dialog, no interruption to what you're doing.
2. When you reach a natural stopping point, file the shots in the order you took them:

```powershell
cd F:\Claude-Github
.\tools\Add-LabScreenshot.ps1 -Lab 00 -Name "forest promotion complete"
.\tools\Add-LabScreenshot.ps1 -Lab 00 -Name "Get-ADDomain output"
```

Each run takes the **newest** image from `Pictures\Screenshots`, moves it to `labs/00-domain-controller-setup/screenshots/` as `01-forest-promotion-complete.png`, `02-get-addomain-output.png`, and so on, then copies the Markdown reference to your clipboard. It prints which source file it consumed and when that was captured, so a mismatch is obvious immediately.

**Filing a batch after the fact? Use `-Oldest`.** The default takes the newest image, which is right when you capture one shot and file it straight away. But if you take several and then file them in one go, the newest gets consumed first and your names end up attached to the wrong images, in reverse. `-Oldest` walks the folder oldest-first so a batch lines up with the order you took them:

```powershell
.\tools\Add-LabScreenshot.ps1 -Lab 00 -Name "first thing I captured"  -Oldest
.\tools\Add-LabScreenshot.ps1 -Lab 00 -Name "second thing I captured" -Oldest
.\tools\Add-LabScreenshot.ps1 -Lab 00 -Name "third thing I captured"  -Oldest
```

3. Paste the Markdown into the lab's `README.md` at the step it illustrates.

**Options:**

| Flag | Purpose |
|------|---------|
| `-Lab` | Lab number or folder name. `00`, `0`, and `00-domain-controller-setup` all work. |
| `-Name` | Short description; gets slugified into the filename. |
| `-File` | Use a specific file instead of the newest screenshot. |
| `-Oldest` | Take the oldest image rather than the newest. Use when filing a batch in capture order. |
| `-SourceFolder` | Override where incoming screenshots are read from. |
| `-KeepOriginal` | Copy rather than move, leaving the original in place. |

Use `Win + Shift + S` (region snip) instead when you only want part of the screen — save it to `Pictures\Screenshots`, or pass the file explicitly with `-File`.

---

## Before you commit: redaction checklist

Git history is permanent. A secret committed and then "removed" in a later commit is still in the history, and on a repo that eventually goes public it is still readable. Scrub **before** `git add`, not after.

Check every screenshot for:

- **Your home/office public IP address.** Lab 05 has you create a network zone from your own public IP. That is your home address to anyone who looks it up. Blur it, or use a documentation-range placeholder like `203.0.113.10/32` in the screenshot annotation.
- **The Okta AD Agent registration token / API tokens.** Shown once during agent setup and during any API token creation. Never capture these.
- **Passwords in plain text.** The DSRM password, the `svc-labautomation` password, temporary user passwords echoed by the joiner script. Crop them out.
- **Your real Okta tenant URL** (`dev-XXXXXXXX.okta.com`). It's a live tenant — worth blurring even though it isn't a secret by itself.
- **Anything from your actual employer.** Capture the specific window, not the whole desktop — a stray Outlook, Teams, or ticketing window in the background is the most common way real company data leaks into a portfolio repo.
- **Machine names, serial numbers, license keys** visible in system properties or activation screens.

Everything in this repo about Canyon Peak Technologies is fictional and safe to show. The risk is only ever the real infrastructure sitting behind the lab.

---

## Keeping the repo light

Git stores a **complete copy of every version** of a binary file, forever. Replacing one 3 MB screenshot five times leaves 15 MB in history that never goes away, and there's no easy fix short of rewriting history.

So:

- Crop to the relevant window before filing the shot rather than capturing a 4K desktop. The script warns above 1 MB.
- Get the screenshot right before committing it, instead of committing and re-shooting.
- PNG is the correct format here — lossless and crisp for UI text. JPEG artifacts make console output hard to read.

At a few hundred KB per shot and roughly a dozen shots per lab, the whole series lands well under 100 MB, so Git LFS isn't needed.
