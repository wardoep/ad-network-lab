# 08 — pfSense firewall + packet captures

**Goal:** the lab gets a real network edge — pfSense routes and filters traffic between the lab subnet and the outside — and I capture the protocols I've been using all along (DHCP, DNS, Kerberos) with Wireshark.

## Build

1. **pfSense VM:** 1 vCPU, 1 GB RAM, 8 GB disk, **two adapters**:
   - Adapter 1 (WAN): NAT (plain VirtualBox NAT — this is the "internet" side)
   - Adapter 2 (LAN): NAT Network `ADLAB`
2. Install pfSense; assign WAN = adapter 1, LAN = adapter 2; set LAN IP to `10.0.10.1/24` and **disable pfSense's DHCP server** (DC01 owns DHCP).
3. From CLIENT01, open `https://10.0.10.1` for the web UI and finish setup.
4. DC01/clients already point at `10.0.10.1` as gateway (set in milestones 1–2) — outbound internet from the lab now works through pfSense.

## Firewall exercises

- **Read the default rules:** LAN→any allowed, WAN→LAN blocked. Explain why that's the standard posture.
- **Egress filtering:** block outbound DNS (TCP/UDP 53) from LAN except from DC01 — clients must use the domain's resolver. Verify with `nslookup google.com 8.8.8.8` from CLIENT01 (times out) vs plain `nslookup google.com` (works, via DC01).
- **Logging:** enable logging on the block rule, watch hits arrive in Status → System Logs → Firewall.
- **Port forward (optional):** forward a WAN port to a lab service and explain the NAT + firewall-rule pair it creates.

## Wireshark captures (on CLIENT01)

Store annotated captures in [`../captures/`](../captures/):

| Capture | How to trigger | What to identify |
|---|---|---|
| `dhcp-dora.pcapng` | `ipconfig /release` then `/renew` | Discover→Offer→Request→Ack, options 3/6/15 |
| `dns-lookup.pcapng` | `nslookup intranet.corp.lab` | query/response, what answers authoritatively |
| `kerberos-logon.pcapng` | `klist purge` then access `\\dc01\HRShare` | AS-REQ/AS-REP, TGS-REQ/TGS-REP, then SMB2 session setup |

## Verify

- Lab machines reach the internet through pfSense; WAN side cannot initiate into the lab.
- The egress rule provably blocks rogue DNS.
- All three captures collected and annotated.

## If it breaks

- No internet from lab after adding pfSense: check default gateway on DC01 (`route print`) and that pfSense LAN is really 10.0.10.1.
- Web UI unreachable: you're probably hitting it from the WAN side; access it from a lab VM.

## What I learned

_(fill in after completing this milestone)_
