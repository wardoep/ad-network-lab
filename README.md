# Active Directory + Network Lab

A Windows domain and segmented network I am building and operating in VirtualBox, documented as runbooks — the same way I'd document production infrastructure.

## Overview

This lab exists to practice the core of enterprise IT support: a Windows Server domain controller, a domain-joined client, group-based access control, Group Policy, delegated helpdesk rights, PowerShell user provisioning, and a pfSense firewall segmenting the lab network. Every milestone is a runbook in [`runbooks/`](runbooks/), written so the lab can be rebuilt from scratch by following them. Deliberate break/fix drills — and their diagnoses — are logged in [`runbooks/09-break-fix-log.md`](runbooks/09-break-fix-log.md).

The runbooks are the *how*; **[TAKEAWAYS.md](TAKEAWAYS.md) is the *why*** — what each milestone builds, why real organizations work this way, and the transferable idea behind it.

## Topology

```
                    (host machine, VirtualBox)
                            │
                       [NAT / WAN]
                            │
                     ┌──────┴──────┐
                     │   pfSense   │  10.0.10.1   (milestone 8)
                     │  fw/router  │
                     └──────┬──────┘
              lab network 10.0.10.0/24 (isolated)
              ┌─────────────┼─────────────────┐
       ┌──────┴──────┐             ┌──────────┴────────┐
       │    DC01     │             │     CLIENT01      │
       │ Win Server  │ 10.0.10.5   │    Windows 11     │ DHCP
       │ AD DS · DNS │             │  domain-joined    │ (scope
       │ DHCP · file │             │                   │  .100–.199)
       └─────────────┘             └───────────────────┘
                    domain: corp.lab
```

## Milestones

| # | Runbook | Status |
|---|---------|--------|
| 0 | [Lab setup — VMs, network, ISOs](runbooks/00-lab-setup.md) | ✅ 2026-07-16 |
| 1 | [Build the domain controller](runbooks/01-domain-controller.md) | ✅ 2026-07-16 |
| 2 | [OUs, users, and groups](runbooks/02-ous-users-groups.md) | ☐ |
| 3 | [Join the client to the domain](runbooks/03-client-join.md) | ☐ |
| 4 | [Group Policy](runbooks/04-group-policy.md) | ☐ |
| 5 | [File shares with AGDLP permissions](runbooks/05-file-server-agdlp.md) | ☐ |
| 6 | [Helpdesk delegation (RBAC)](runbooks/06-helpdesk-delegation.md) | ☐ |
| 7 | [PowerShell user provisioning](runbooks/07-powershell-automation.md) | ☐ |
| 8 | [pfSense firewall + packet captures](runbooks/08-pfsense-network.md) | ☐ |
| 9 | [Break/fix drill log](runbooks/09-break-fix-log.md) | ongoing |

Statuses get checked off as each milestone is completed and verified; the runbooks are corrected wherever reality differed from the plan.

## What's in `scripts/`

- [`New-LabUsers.ps1`](scripts/New-LabUsers.ps1) — bulk-provisions AD users from a CSV: derives usernames, places each user in their department OU, adds them to their department group, forces a password change at first logon, and skips accounts that already exist so the script is safe to re-run.
- [`Disable-OffboardedUser.ps1`](scripts/Disable-OffboardedUser.ps1) — offboarding: disables the account, records the date and operator in the description, strips group memberships, and moves the account to a Disabled OU.
- [`users.sample.csv`](scripts/users.sample.csv) — sample input.

## Skills this lab exercises

Active Directory (forest/domain design, OUs, security groups), DNS and DHCP administration, Group Policy creation and troubleshooting (`gpupdate`, `gpresult`), NTFS/share permissions via the AGDLP model, delegated administration, PowerShell automation with the ActiveDirectory module, firewalling and network segmentation with pfSense, and protocol-level troubleshooting with Wireshark (DHCP, DNS, Kerberos).

## What I learned

Filled in per milestone as the lab progresses — see the closing section of each runbook, and the diagnosis notes in the [break/fix log](runbooks/09-break-fix-log.md). The goal of this repo is not a screenshot gallery; it's proof that I can build, document, break, and repair a Windows domain environment.

---
Built and maintained by **Edward J. Penna** — [github.com/wardoep](https://github.com/wardoep)
