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

## VM specs

| VM | vCPU | RAM | Disk (dynamic) | Notes |
|---|---|---|---|---|
| DC01 | 2 | 4096 MB | 60 GB | Server 2022, Desktop Experience |
| CLIENT01 | 2 | 4096 MB | 80 GB | Win11 needs EFI + TPM 2.0 + Secure Boot — auto-set when OS type is Windows 11 |
| pfSense (milestone 8) | 1 | 1024 MB | 8 GB | two adapters: WAN=NAT, LAN=`ADLAB` |

Host budget: ~8 GB free RAM with both Windows VMs running, ~60 GB free disk (dynamic disks only consume what's written). If RAM is tight, 3072 MB each is workable; don't go lower on the DC.

## Steps

1. **Create the lab network.** VirtualBox → File → Tools → Network Manager → NAT Networks → Create:
   - Name: `ADLAB`, IPv4 prefix: `10.0.10.0/24`
   - **Untick "Enable DHCP"** — DC01 will be the DHCP server; two DHCP servers on one subnet is a classic outage. (Until milestone 1 is done, CLIENT01 simply won't get a lease; that's expected.)
2. **Create DC01** (Machine → New): attach the Server 2022 ISO, **tick "Skip Unattended Installation"** (VirtualBox 7 otherwise installs Windows for you — doing it manually is the point), specs per the table, then Settings → Network → Adapter 1 → NAT Network `ADLAB` before first boot. During Windows setup pick the **Desktop Experience** edition.
3. **Create CLIENT01:** same flow with the Win11 ISO (OS type *Windows 11 (64-bit)* makes VirtualBox enable EFI/TPM/Secure Boot automatically), adapter on `ADLAB`. The lab has no internet gateway until milestone 8, so at setup's network screen use `Shift+F10` → `start ms-cxh:localonly`, which pops a local-account dialog directly. (The old `oobe\bypassnro` trick is removed from current Win11 builds — verified the hard way on the 2026 eval ISO; see runbook 03.)
4. **After each OS install:** Devices → Insert Guest Additions CD → run installer (clipboard, display, time sync).
5. **Snapshot discipline:** take a snapshot named `pre-<milestone>` before starting every milestone. A broken lab you can roll back is a lab you'll actually experiment on.

## Verify

- Both VMs boot from their ISOs.
- Both adapters show `ADLAB` as the attached network.

## Notes / gotchas

- Do **not** build these VMs nested inside another VM — build them on the physical host. Nested virtualization is slow at best and often unavailable.
- Keep the lab on the NAT network, not bridged: it isolates the domain's DHCP/DNS from the real LAN, so lab mistakes can't affect the home network.

## What I learned

*Completed.*

- **Ctrl+Alt+Del never reaches a VM** — the host OS intercepts it at a level VirtualBox can't grab. The substitute is Host key + Del (Right Ctrl + Delete, *without* Alt), or Input → Keyboard → Insert Ctrl-Alt-Del. I lost ten minutes to this because I kept adding Alt out of habit.
- **Setup guides rot.** The runbook originally said `oobe\bypassnro` for the Win11 local-account bypass; Microsoft removed it from current builds, and `start ms-cxh:localonly` is the working replacement. Lesson: when a documented trick fails, check whether the vendor killed it before assuming I did it wrong — and then fix the doc.
- **Defaults are silent.** I forgot to move DC01's adapter to the `ADLAB` NAT network before installing, so it sat on VirtualBox's default NAT the whole time. Nothing errored — the install even activated itself thanks to the accidental internet — but the machine was quietly on the wrong network. Now I check Settings → Network before first boot, every VM.
- **Terminology precision matters:** a VM is a machine you virtualize anywhere; a VPS is specifically a VM you *rent*. I'd been using them interchangeably, and being sloppy with the words made it harder to reason about where things should run.
