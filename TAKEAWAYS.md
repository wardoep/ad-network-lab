# What this lab is really teaching — and why

The runbooks say *how*. This document says *why* — what each milestone builds, why the real world works this way, and the transferable idea to walk away with. If I can explain everything on this page without notes, the lab did its job.

## The big picture

This lab is a miniature of the system almost every organization on earth runs its IT on: a **Windows domain**. One server (the domain controller) holds the master database of every user, computer, group, and permission; every other machine defers to it. Nearly the entire workload of an IT support role — password resets, lockouts, "I can't access the shared drive," onboarding, offboarding, "my drive mapping is gone" — is an operation against this system. Building it from nothing is how you stop memorizing answers and start understanding the machine that generates the tickets.

A mental model that holds up well: **the domain controller is the brain; a client PC is just a desk.** Employees (user accounts) live in the brain, not at any desk — which is why anyone can sit anywhere, why disabling one account locks someone out of everything, and why a desk that can't reach the brain suddenly can't do anything at all.

## Milestone-by-milestone: what, why, takeaway

### 0 — VMs and an isolated network
**Built:** two VMs on a NAT network with no DHCP and (initially) no internet.
**Why:** infrastructure experiments belong in a padded room. A misconfigured DHCP server on a real network takes the network down — on `ADLAB`, it can only take down the lab.
**Takeaway:** isolation first, then experiments. Also: snapshots are what make it safe to be curious.

### 1 — The domain controller
**Built:** static IP → DNS → Active Directory forest `corp.lab` → DHCP.
**Why each piece:**
- **Static IP** — clients get random addresses from DHCP; *infrastructure gets fixed ones*. The machine everything else must find cannot move around.
- **DNS on the DC, clients pointed only at it** — AD is built on DNS: a client logging in literally asks DNS "who holds the login service for corp.lab?" This is why the majority of "can't reach the domain" problems are DNS problems in a costume.
- **AD DS / the forest** — replaces per-machine accounts with one central database: one account, working everywhere, revocable in one place.
- **DHCP, authorized in AD** — hands each new machine its address plus the "welcome packet" (your DNS, your gateway, your domain). The authorization step exists because rogue DHCP servers are a classic outage *and* a classic attack — domain DHCP refuses to serve until the directory blesses it.
**Takeaway:** four services (identity, DNS, DHCP, policy) form the spine of every office network, and their order of construction matters.

### 2 — OUs, users, groups
**Built:** a folder structure (OUs) mirroring departments, security groups per department, users created under a naming convention.
**Why:** none of this is for looks. OUs are where Group Policy attaches; groups are how access gets granted (never to individuals); conventions are what make an environment supportable by someone who didn't build it — which is the actual definition of professional infrastructure.
**Takeaway:** structure and convention are not bureaucracy; they are what makes "who has access to what, and why?" an answerable question.

### 3 — Client joins the domain
**Built:** CLIENT01 becomes a domain member; a domain user logs in at it.
**Why it works:** the client found the DC through DNS, proved the user's password to it, and received a **Kerberos ticket** — a cryptographic hall pass it then shows to every service instead of re-sending the password. Tickets are time-stamped, which is why a clock more than 5 minutes off breaks logins in bizarre-looking ways.
**Takeaway:** "I can't log in" almost always decomposes into: can't *find* the brain (DNS), can't *agree on time* with it (Kerberos), or the account itself changed (lockout/disable). Check in that order.

### 4 — Group Policy
**Built:** password rules domain-wide, an HR-only mapped drive, USB storage disabled, a logon banner.
**Why:** policy is how one admin manages a thousand machines — declare the rule once at the brain, every desk enforces it. The debugging pair `gpupdate` (pull rules now) and `gpresult` (show me which rules landed and why not) is daily-driver tooling in real support work.
**Takeaway:** manage by policy, not by walking to machines. And when a setting "mysteriously" doesn't apply, it's link, scope, or user-vs-computer side — in that order.

### 5 — File shares (AGDLP)
**Built:** department shares where **A**ccounts go into **G**lobal groups, into **D**omain **L**ocal groups, which hold the **P**ermissions. HR writes, IT reads, Sales gets nothing.
**Why the indirection:** granting users directly onto folders works — once — and then the environment rots into something unauditable. With AGDLP, access review means reading group membership; a job change means swapping one group. This is the exact structure corporate access audits (like the ones I supported at Broadridge) review.
**Takeaway:** access flows through roles, not people. Also: new group membership takes effect at *next logon*, because it's stamped into the Kerberos ticket — a fact that resolves a whole category of confusing tickets.

### 6 — Helpdesk delegation
**Built:** a Helpdesk group that can reset passwords and unlock accounts in one OU — and provably nothing else.
**Why:** this is **least privilege** made real, and it's the permission set an actual entry-level IT job runs on. The verification step (confirming the denied actions are denied) matters as much as the grant.
**Takeaway:** power in AD is delegable at any granularity; a role is a bundle of exactly the rights the job needs, and no more.

### 7 — PowerShell provisioning
**Built:** onboarding from a CSV and a one-command offboarding script.
**Why:** clicking through user creation works for one user; the tenth is a script. The details are the lesson: idempotence (safe to re-run), naming collisions handled, and offboarding that *disables and quarantines instead of deleting* — because deletion destroys the SID and the audit trail.
**Takeaway:** repeated admin work becomes scripts; good scripts are safe to run twice; never delete what an auditor might ask about.

### 8 — pfSense and packet captures
**Built:** a real network edge — firewall, egress rules, and Wireshark captures of DHCP, DNS, and Kerberos.
**Why:** everything up to now trusted the network; this milestone makes the network itself something I control and can *see*. Watching the DHCP Discover→Offer→Request→Ack handshake and the Kerberos AS/TGS exchange turns protocols from vocabulary words into things I've watched happen.
**Takeaway:** default posture is inside-out allowed, outside-in denied; and when behavior is confusing, the packets don't lie.

### 9 — Break/fix drills
**Built:** deliberately sabotaged systems, diagnosed from symptoms without peeking.
**Why:** this is the whole job. Anyone can follow a build guide; support work is *starting from a symptom* and walking the layers to a cause. Doing drills days after setting them up (so I've genuinely forgotten) is the closest a lab gets to a real ticket queue.
**Takeaway:** a repeatable diagnostic order beats memorized fixes. Symptom → what changed → which layer (physical/IP/DNS/auth/permissions) → root cause → fix → write it down.

## If I only remember five things

1. Infrastructure gets static addresses; clients get leases. The phone book can't move.
2. Active Directory stands on DNS. When the domain acts haunted, exorcise DNS first.
3. Access flows through groups and roles, never direct grants — that's what makes systems auditable.
4. Least privilege is implementable, not aspirational: delegation proves it in one wizard.
5. Tickets are symptoms of layers. Walk the layers in order and any ticket becomes tractable.

---
Built and maintained by **Edward J. Penna** — [github.com/wardoep](https://github.com/wardoep)
