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

- **A domain member has zero independence from its domain controller.** DC01 is the client's DHCP server, DNS server, *and* the domain itself. When I had DC01 powered off while working on the client, CLIENT01 couldn't get an address (self-assigned APIPA `169.254.x.x`), couldn't resolve `corp.lab`, and couldn't be joined — all three failures traced to one dead box. This is *why real networks never run a single DC*: production runs at least two DCs (each also serving DNS), plus DHCP failover, so one machine going down doesn't blind every client. I met the single-point-of-failure that redundancy exists to prevent.
- **`169.254.x.x` always means "no DHCP server answered."** It's the address Windows invents when its lease request goes unanswered. `ipconfig /renew` *hanging* is the same signal — it's broadcasting for a server that isn't there. Reading those two symptoms told me the problem was network-layer (nothing serving DHCP), not the client.
- **A client finds its domain through DNS, not broadcast.** The client locates the DC by querying DNS for the domain's SRV records, which only DC01 serves — so the client's DNS *must* point at `10.0.10.5`. Point it at a public resolver and it'll have internet but be unable to find the domain. Kerberos then handles the actual authentication (visible in `klist`), which is why domain clocks must agree within ~5 minutes.
- **A machine joins AD under whatever name it currently has.** The VM was still the default `WIN-…` name; joining then would have put that ugly name in AD permanently. Renaming to `CLIENT01` *before* the join produced a clean directory object the first time.
- **Standard user vs. administrator, first-hand.** Logged in as a standard user (`eddie`), asking for an elevated PowerShell triggered *over-the-shoulder elevation* — Windows can't elevate an account that has no admin rights, so it prompted for a different admin account and ran as *that*. Only the first account created at OOBE is auto-admin; a second account is a plain user until explicitly added to the Administrators group (and the rights only apply after a fresh login, because the token is built at logon).
- **"Account exists" ≠ "account works."** `jsmith` existed but was *disabled* — because its initial password failed the complexity policy at creation, and AD refuses to enable an account it couldn't assign a valid password. It passed my "does the user exist?" check in milestone 2 yet was unusable. Lesson: verify the **Enabled** state, not just existence. (See break/fix log entries for both this and the APIPA incident.)
