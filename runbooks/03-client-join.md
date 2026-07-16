# 03 — Join CLIENT01 to the domain

**Goal:** the Windows 11 client gets its lease from DC01, resolves the domain, joins it, and a domain user can log in.

## Steps

1. **Install Windows 11 Enterprise** on CLIENT01. Local account, name the machine `CLIENT01` during setup (or rename after).
   - Tip for the eval ISO: when setup demands internet/a Microsoft account, press `Shift+F10` → `start ms-cxh:localonly` — a local-account dialog opens directly. (`oobe\bypassnro` is removed from current Win11 builds; the registry fallback is `reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f` then reboot.)
2. **Check networking** (should be automatic via DC01's DHCP):
   ```powershell
   ipconfig /all        # IP in 10.0.10.100–199, DNS = 10.0.10.5, domain suffix corp.lab
   nslookup corp.lab    # answers from 10.0.10.5
   ```
3. **Join the domain** (elevated PowerShell):
   ```powershell
   Add-Computer -DomainName corp.lab -Credential CORP\Administrator -Restart
   ```
4. **Log in as a domain user** — at the sign-in screen use `CORP\jsmith` (first login forces the password change set in milestone 2).

## Verify

```powershell
whoami                    # corp\jsmith
whoami /groups            # includes GG-IT
nltest /dsgetdc:corp.lab  # finds DC01
klist                     # Kerberos tickets from dc01.corp.lab
```
On DC01: `Get-ADComputer CLIENT01` exists, and the client appears in DHCP leases.

## If it breaks

- **"An Active Directory Domain Controller could not be contacted"** → it's DNS. Nearly always. Confirm the client's DNS server is `10.0.10.5` and nothing else (no public resolver alongside it).
- **Clock skew** → Kerberos tolerates ±5 minutes. `w32tm /resync` on the client; VirtualBox guests sometimes drift after host sleep.
- These two are drills #1 and #2 in the [break/fix log](09-break-fix-log.md) — break them on purpose after the happy path works.

## What I learned

_(fill in after completing this milestone)_
