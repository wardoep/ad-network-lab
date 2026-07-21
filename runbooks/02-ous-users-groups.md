# 02 — OUs, users, and groups

**Goal:** an OU structure that mirrors a small company, department security groups, and first users — with a naming convention, because conventions are what make an environment supportable.

## Conventions

- Usernames: first initial + last name, lowercase (`jsmith`)
- Global groups: `GG-<Dept>` (`GG-IT`, `GG-HR`, `GG-Sales`)
- Domain-local resource groups: `DL-<resource>-<right>` (`DL-HRShare-RW`) — used in milestone 5
- Every user lives in their department OU, never in the default Users container

## Steps (on DC01, elevated PowerShell)

1. **OU structure:**
   ```powershell
   New-ADOrganizationalUnit -Name "Departments" -Path "DC=corp,DC=lab"
   "IT","HR","Sales" | ForEach-Object {
       New-ADOrganizationalUnit -Name $_ -Path "OU=Departments,DC=corp,DC=lab"
   }
   New-ADOrganizationalUnit -Name "Groups"   -Path "DC=corp,DC=lab"
   New-ADOrganizationalUnit -Name "Disabled" -Path "DC=corp,DC=lab"
   ```
2. **Department groups:**
   ```powershell
   "IT","HR","Sales" | ForEach-Object {
       New-ADGroup -Name "GG-$_" -GroupScope Global -Path "OU=Groups,DC=corp,DC=lab"
   }
   New-ADGroup -Name "GG-Helpdesk" -GroupScope Global -Path "OU=Groups,DC=corp,DC=lab"
   ```
3. **Create one user by hand** to understand every field (ADUC or `New-ADUser`), then bulk-create the rest in milestone 7 with `New-LabUsers.ps1`:
   ```powershell
   New-ADUser -Name "Jordan Smith" -GivenName Jordan -Surname Smith `
     -SamAccountName jsmith -UserPrincipalName jsmith@corp.lab `
     -Path "OU=IT,OU=Departments,DC=corp,DC=lab" `
     -AccountPassword (Read-Host -AsSecureString "Initial password") `
     -ChangePasswordAtLogon $true -Enabled $true
   Add-ADGroupMember -Identity GG-IT -Members jsmith
   ```

## Verify

```powershell
Get-ADOrganizationalUnit -Filter * | Select-Object DistinguishedName
Get-ADGroupMember GG-IT
Get-ADUser jsmith -Properties MemberOf | Select-Object -ExpandProperty MemberOf
```

## If it breaks

- `New-ADUser` password errors: the initial password must satisfy the domain password policy (complexity is on by default).
- User created in the wrong place: `Get-ADUser jsmith | Move-ADObject -TargetPath "OU=IT,OU=Departments,DC=corp,DC=lab"`.

## What I learned

- **OUs are for management, not tidiness.** An OU is the unit you link Group Policy to (milestone 4) and the unit you delegate admin rights over (milestone 6), so the tree has to mirror how the environment is *administered*, not just the org chart. Putting users in department OUs now is what makes those later milestones possible at all — you can't scope a GPO or a delegation to users scattered in the default `Users` container.
- **A naming convention is infrastructure.** `jsmith` and `GG-<Dept>` aren't cosmetic — they make objects *derivable*, which is what lets a script (or another admin) find and act on them predictably. `New-LabUsers.ps1` in milestone 7 only works because a username can be computed from a person's name.
- **Group scope is decided before any permission exists.** Department membership goes in **Global** groups (`GG-`); resource access will go in **Domain-Local** groups (`DL-`) in milestone 5. That separation *is* the AGDLP model: when someone changes departments I edit group membership, never the permissions on the share. Getting the `GG-`/`DL-` split right up front is what keeps access control maintainable later.
- **Small defaults make it a governed directory, not a sandbox.** `-ChangePasswordAtLogon $true` and the on-by-default password-complexity policy (which is why a weak initial password is rejected) are the details that make the domain behave like a real environment.

_Correction (found in milestone 3): `jsmith` was created here but landed **disabled**, because the initial password I typed failed the domain complexity policy — `New-ADUser -Enabled $true` creates the account anyway but won't enable one it couldn't assign a valid password to. My verify step only checked that the user **existed**, so I missed it; it surfaced later as "your account has been disabled" at first domain login. Fix and full write-up in the [break/fix log](09-break-fix-log.md). Lesson carried forward: always verify `Enabled` state, not just existence, and make initial passwords satisfy complexity (three of upper/lower/digit/symbol)._
