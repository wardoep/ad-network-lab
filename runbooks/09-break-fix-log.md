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

_(added as drills are completed)_
