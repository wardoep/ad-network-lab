# 09 — Break/fix drill log

Deliberately breaking the lab, then diagnosing it from symptoms — without peeking at what was broken. Each entry is written **after** the fix, in the format below. This page is the part of the lab most worth reading.

## Entry format

```
### <date> — <title>
Symptom:        what a user would report
First checks:   what I looked at, in order, and why
Root cause:     the actual break
Fix:            what resolved it
Time to fix:    <minutes>
Takeaway:       the reusable lesson
```

## Planned drills

| # | Break (do secretly, ideally days later) | Expected symptom |
|---|---|---|
| 1 | Point CLIENT01's DNS at 8.8.8.8 | "Can't log in with my work account" / no DC found |
| 2 | Skew CLIENT01's clock +10 min | Kerberos failures, share access denied, odd auth errors |
| 3 | Stop the DHCP service on DC01 | New/renewing clients get APIPA 169.254.x.x |
| 4 | Remove a user from GG-HR | "I could open the HR drive yesterday" |
| 5 | Unlink GPO-HR-DriveMap | "My H: drive is gone" (no error at all) |
| 6 | pfSense rule blocking 445/SMB inside LAN | Shares unreachable but ping/DNS fine |
| 7 | Disable "Register this connection's addresses in DNS" on DC01 NIC | Slow, intermittent domain weirdness — the nastiest one here |

## Entries

### 2026-07-21 — Client stranded on APIPA (169.254), couldn't find the domain
Symptom:        CLIENT01 had no usable IP (`169.254.151.191`, no gateway), `ipconfig /renew` hung, `nslookup corp.lab` failed, domain join impossible.
First checks:   read `ipconfig /all` — APIPA address = "no DHCP server answered"; `ipconfig /release` + `/renew`, the renew *hung* = broadcasting for a server that isn't replying; checked the VirtualBox Manager for DC01's power state.
Root cause:     **DC01 was powered off.** It is the only DHCP + DNS + AD server, so one dead box took out addressing, name resolution, and the domain simultaneously.
Fix:            started DC01, waited for services to come up, `ipconfig /renew` on CLIENT01 → got `10.0.10.100`, DNS `10.0.10.5`, suffix `corp.lab`.
Time to fix:    ~5 min.
Takeaway:       `169.254.x.x` (and a hanging renew) always means nothing is serving DHCP. A domain member has zero independence from its DC — which is exactly why real networks run ≥2 DCs plus DHCP failover. (Unplanned real-world version of planned drill #3.)

### 2026-07-21 — Domain user "account has been disabled" at first login
Symptom:        after a *successful* domain join, logging in as `CORP\jsmith` returned "Your account has been disabled, contact your system administrator."
First checks:   noted the message itself proves the join worked (the DC authenticated far enough to report account *state*); on DC01, `Get-ADUser jsmith -Properties Enabled,PasswordLastSet` → `Enabled : False`.
Root cause:     `jsmith` was created in milestone 2 with an initial password that failed the complexity policy; `New-ADUser` created the account but left it **disabled** (AD won't enable an account it couldn't give a valid password). It passed the earlier "does the user exist?" check but was never usable.
Fix:            on DC01 — `Set-ADAccountPassword -Reset` with a complex password, `Enable-ADAccount jsmith`, `Set-ADUser -ChangePasswordAtLogon $true`. Logged in fine, forced a password change on first logon.
Time to fix:    ~3 min.
Takeaway:       "account exists" ≠ "account works" — always verify the **Enabled** state, not just existence. A weak initial password silently disables a new account; this is the most common real-world version of this helpdesk ticket.
