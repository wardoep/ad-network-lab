# 07 — PowerShell user provisioning

**Goal:** onboarding and offboarding are scripts, not click-paths. The scripts live in [`../scripts/`](../scripts/).

## Onboarding: `New-LabUsers.ps1`

Reads a CSV (`First,Last,Department`), and for each row: derives the username from the naming convention, creates the account in the right department OU, adds it to `GG-<Department>`, sets a one-time password that must be changed at first logon, and **skips rows whose account already exists** — so re-running the script after fixing a bad row is safe (idempotence).

```powershell
# on DC01, elevated
cd <repo>\scripts
.\New-LabUsers.ps1 -CsvPath .\users.sample.csv
```

## Offboarding: `Disable-OffboardedUser.ps1`

Standard leaver process in one command: disable the account, stamp the description with the date and who ran it, remove all group memberships (access dies with the role), move the object to `OU=Disabled`.

```powershell
.\Disable-OffboardedUser.ps1 -SamAccountName jsmith
```

Disable-and-move rather than delete: deletion destroys the SID and with it the audit trail; a disabled account in a quarantine OU can be reviewed, re-enabled if the offboarding was a mistake, and purged later on a schedule.

## Verify

```powershell
Get-ADUser -Filter * -SearchBase "OU=Departments,DC=corp,DC=lab" |
  Measure-Object                                   # count matches the CSV
Get-ADGroupMember GG-Sales                         # sales hires present
Get-ADUser jsmith -Properties Enabled,Description,MemberOf   # after offboarding:
                                                   # disabled, stamped, no groups
```
Then re-run `New-LabUsers.ps1` and confirm it reports every row as skipped.

## If it breaks

- `New-ADUser : The password does not meet the length, complexity…` — the default password in the script must satisfy the milestone-4 policy; pass `-DefaultPassword` explicitly if you changed the policy.
- Duplicate names (two `jsmith`s): the script appends a digit and warns — check the warning output rather than assuming.

## What I learned

_(fill in after completing this milestone)_
