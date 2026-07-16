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

_(fill in after completing this milestone)_
