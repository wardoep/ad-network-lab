# 06 — Helpdesk delegation (RBAC in practice)

**Goal:** members of `GG-Helpdesk` can reset passwords and unlock accounts in the Departments OU — and can do **nothing else**. Least privilege, implemented rather than described.

## Steps

1. **Create a helpdesk user** and add them to `GG-Helpdesk` (milestone 2 created the group):
   ```powershell
   New-ADUser -Name "Help Desk" -SamAccountName hdesk -UserPrincipalName hdesk@corp.lab `
     -Path "OU=IT,OU=Departments,DC=corp,DC=lab" `
     -AccountPassword (Read-Host -AsSecureString "Password") -Enabled $true
   Add-ADGroupMember -Identity GG-Helpdesk -Members hdesk
   ```
2. **Delegate** — in ADUC, right-click the **Departments** OU → *Delegate Control…*:
   - Principal: `GG-Helpdesk`
   - Task: **"Reset user passwords and force password change at next logon"** (predefined)
   - Run the wizard a second time with the custom task: User objects → read/write **lockoutTime** (unlock).
3. **Give the helpdesk user tools** on CLIENT01: install RSAT Active Directory tools
   (`Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0`).

## Verify (logged in as `hdesk` on CLIENT01)

```powershell
Set-ADAccountPassword jsmith -Reset -NewPassword (Read-Host -AsSecureString "New")   # WORKS
Unlock-ADAccount jsmith                                                              # WORKS
Set-ADUser jsmith -Description "test"        # ACCESS DENIED — out of scope
Remove-ADUser jsmith                         # ACCESS DENIED
New-ADUser -Name "Rogue User"                # ACCESS DENIED
```
The denied commands are the point: the delegation grants exactly two rights.

## If it breaks

- Reset works but unlock doesn't: the wizard's predefined task doesn't include `lockoutTime` — that's why step 2 runs it twice.
- To inspect what was actually granted: Departments OU → Properties → Security → Advanced, look for the `GG-Helpdesk` ACEs.
- To start over: same Advanced dialog, remove the `GG-Helpdesk` entries and re-run the wizard.

## What I learned

_(fill in after completing this milestone)_
