# 04 — Group Policy

**Goal:** three working GPOs of increasing scope, plus fluency in the two commands every support tech uses to debug policy: `gpupdate` and `gpresult`.

## GPOs to build (in the Group Policy Management console on DC01)

1. **Password policy** — edit the **Default Domain Policy** (password settings only apply domain-wide from there):
   Computer Config → Policies → Windows Settings → Security Settings → Account Policies.
   Set: min length 12, history 24, max age 365, lockout threshold 5.
2. **`GPO-HR-DriveMap`** — linked to the **HR OU**:
   User Config → Preferences → Windows Settings → Drive Maps → New → `H:` → `\\dc01\HRShare` (share exists after milestone 5; create the GPO now, watch it fail, fix it later — instructive on its own).
   Use item-level targeting on group `GG-HR` to see targeting in action.
3. **`GPO-Workstation-Lockdown`** — linked to the **Departments OU**:
   - Computer Config → Policies → Admin Templates → System → Removable Storage Access → "All Removable Storage classes: Deny all access" = Enabled
   - Interactive logon message (Security Options → "Message text for users attempting to log on") — instant visual proof a GPO landed.

## Apply and inspect (on CLIENT01)

```powershell
gpupdate /force
gpresult /r                  # which GPOs applied, which were filtered out and why
gpresult /h C:\gp.html       # full readable report
```

## Verify

- Log in as an HR user → `H:` drive appears; log in as IT → it doesn't (targeting works).
- Plug in / attach a USB stick → access denied.
- The logon message appears for everyone under Departments.

## If it breaks

- GPO not applying: check the **link** (right OU?), **security filtering** (Authenticated Users present?), and whether the setting is Computer vs User side — user-side settings need the *user* in scope, computer-side the *computer object*.
- `gpresult /r` says "Filtering: Not Applied (Empty)" → the GPO has settings on the other side (user/computer) than you think.
- Slow logons after adding drive maps: set drive maps to "Replace" not "Recreate".

## What I learned

_(fill in after completing this milestone)_
