# 05 — File shares with AGDLP permissions

**Goal:** department shares where access is granted **only** through groups, following AGDLP: **A**ccounts → **G**lobal groups → **D**omain **L**ocal groups → **P**ermissions. This is the pattern behind every corporate access review — including the ones I supported professionally at Broadridge.

## Steps (on DC01)

1. **Resource groups** (domain-local, they hold the permissions):
   ```powershell
   New-ADGroup -Name "DL-HRShare-RW" -GroupScope DomainLocal -Path "OU=Groups,DC=corp,DC=lab"
   New-ADGroup -Name "DL-HRShare-R"  -GroupScope DomainLocal -Path "OU=Groups,DC=corp,DC=lab"
   Add-ADGroupMember -Identity DL-HRShare-RW -Members GG-HR        # G into DL
   Add-ADGroupMember -Identity DL-HRShare-R  -Members GG-IT        # IT can read, not write
   ```
2. **Folder + NTFS permissions:**
   ```powershell
   New-Item -ItemType Directory -Path C:\Shares\HR
   icacls C:\Shares\HR /inheritance:d
   icacls C:\Shares\HR /remove "BUILTIN\Users"
   icacls C:\Shares\HR /grant "CORP\DL-HRShare-RW:(OI)(CI)M" "CORP\DL-HRShare-R:(OI)(CI)RX"
   ```
3. **Share it** (share permissions stay simple; NTFS does the real work):
   ```powershell
   New-SmbShare -Name HRShare -Path C:\Shares\HR -FullAccess "Authenticated Users"
   ```

## Verify

- HR user on CLIENT01: can open `\\dc01\HRShare`, create and edit files (and the `H:` drive map from milestone 4 now works).
- IT user: can read files but gets Access Denied on write.
- Sales user: cannot open the share at all.
- `icacls C:\Shares\HR` shows only the two DL groups + admins/SYSTEM — no individual users.

## If it breaks

- User just added to a group still denied: group membership is stamped into the Kerberos ticket **at logon** — log off and back on (`klist purge` is not enough for share access).
- Everyone can access despite NTFS: check you didn't leave `Users` or `Everyone` in the NTFS ACL; effective access = most-restrictive of share vs NTFS.

## Why AGDLP and not direct grants

Because "who has access to what, and why" must be answerable by reading group membership. Granting users directly onto ACLs is how environments become unauditable.

## What I learned

_(fill in after completing this milestone)_
