# 00 — Lab setup: VMs, network, ISOs

**Goal:** VirtualBox host prepared, isolated lab network created, both VMs built and ready for OS install.

## Downloads (all free)

| What | Where | Notes |
|---|---|---|
| Windows Server 2022 Evaluation ISO | Microsoft Evaluation Center | 180-day eval, can be rearmed |
| Windows 11 Enterprise Evaluation ISO | Microsoft Evaluation Center | 90-day eval |
| pfSense CE ISO (milestone 8) | pfsense.org | AMD64 installer |

## Addressing plan

| Host | IP | Role |
|---|---|---|
| pfSense (later) | 10.0.10.1 | Gateway/firewall |
| DC01 | 10.0.10.5 (static) | AD DS, DNS, DHCP, file shares |
| CLIENT01 | DHCP 10.0.10.100–199 | Domain workstation |

Domain: `corp.lab` · Subnet: `10.0.10.0/24` · DNS for all lab machines: `10.0.10.5`

## Steps

1. **Create the lab network.** VirtualBox → Tools → Network → NAT Networks → Create:
   - Name: `ADLAB`, IPv4 prefix: `10.0.10.0/24`
   - **Disable VirtualBox's built-in DHCP** — DC01 will be the DHCP server. (Until milestone 1 is done, CLIENT01 simply won't get a lease; that's expected.)
2. **Create DC01:** Windows 2022 (64-bit), 2 vCPU, 4096 MB RAM, 60 GB dynamically-allocated disk, network adapter attached to NAT Network `ADLAB`.
3. **Create CLIENT01:** Windows 11 (64-bit), 2 vCPU, 4096 MB RAM, 60 GB disk, adapter on `ADLAB`. If the host lacks a TPM, enable VirtualBox's TPM 2.0 emulation in the VM settings (Win11 requires it).
4. **Snapshot discipline:** take a snapshot named `pre-<milestone>` before starting every milestone. A broken lab you can roll back is a lab you'll actually experiment on.

## Verify

- Both VMs boot from their ISOs.
- Both adapters show `ADLAB` as the attached network.

## Notes / gotchas

- Do **not** build these VMs nested inside another VM — build them on the physical host. Nested virtualization is slow at best and often unavailable.
- Keep the lab on the NAT network, not bridged: it isolates the domain's DHCP/DNS from the real LAN, so lab mistakes can't affect the home network.

## What I learned

_(fill in after completing this milestone)_
