# 01 — Build the domain controller (DC01)

**Goal:** Windows Server 2022 installed, static IP set, promoted to the first domain controller of a new forest `corp.lab`, serving DNS and DHCP.

## Steps

1. **Install Windows Server 2022** (Desktop Experience) on DC01. Set a strong local Administrator password.
2. **Static IP** — in an elevated PowerShell:
   ```powershell
   Get-NetAdapter                       # note the interface alias, e.g. "Ethernet"
   New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.0.10.5 -PrefixLength 24 -DefaultGateway 10.0.10.1
   Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1
   ```
   (Gateway 10.0.10.1 won't exist until pfSense in milestone 8 — that's fine; the lab is self-contained until then.)
3. **Rename and reboot:**
   ```powershell
   Rename-Computer -NewName DC01 -Restart
   ```
4. **Install AD DS and promote:**
   ```powershell
   Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
   Install-ADDSForest -DomainName corp.lab -DomainNetbiosName CORP -InstallDns
   ```
   Set the DSRM password when prompted; the server reboots as a DC.
5. **Install and configure DHCP:**
   ```powershell
   Install-WindowsFeature DHCP -IncludeManagementTools
   Add-DhcpServerv4Scope -Name "ADLAB" -StartRange 10.0.10.100 -EndRange 10.0.10.199 -SubnetMask 255.255.255.0
   Set-DhcpServerv4OptionValue -DnsServer 10.0.10.5 -Router 10.0.10.1 -DnsDomain corp.lab
   Add-DhcpServerInDC -DnsName dc01.corp.lab -IPAddress 10.0.10.5
   ```

## Verify

```powershell
Get-ADDomain                            # returns corp.lab
Get-Service ADWS,DNS,KDC,Netlogon       # all Running
Resolve-DnsName dc01.corp.lab           # resolves to 10.0.10.5
dcdiag /q                               # no errors (warnings about the missing gateway are OK pre-pfSense)
Get-DhcpServerv4Scope                   # scope 10.0.10.0 active
```

## If it breaks

- `Install-ADDSForest` failing on DNS: make sure the NIC's DNS points at itself (`127.0.0.1`) before promotion.
- `dcdiag` advertising failures right after reboot: give AD a few minutes on first boot, then re-run.
- Client can't get a lease later: confirm the scope is **authorized** (`Get-DhcpServerInDC`) and VirtualBox's own DHCP on `ADLAB` is disabled.

## What I learned

*Completed — DC01 running AD DS, DNS, and DHCP; CLIENT01 pulled 10.0.10.100 on `ipconfig /renew`.*

- **Infrastructure gets static addresses; clients get leases.** The DC is the machine everything else must *find* — its address can't move. This one rule explains most of the milestone's ordering.
- **Active Directory stands on DNS.** The DC points DNS at itself (`127.0.0.1`) because clients locate the login service by *asking DNS*, not by magic. I now understand why "can't reach the domain" tickets are usually DNS tickets in disguise.
- **Eval activation reads as just "Activated."** I expected a visible countdown and briefly thought something was wrong; the timer is there but you have to ask for it (`slmgr /dlv`, or the desktop watermark). Verifying with the right tool beats eyeballing a settings page.
- **DHCP must be *authorized* in AD before it serves anyone** — because a rogue DHCP server is both a classic outage and a classic attack. Security controls sometimes look like extra install steps.
- **One digit is a different network.** I misread the client's new lease as `10.10.10.100` and briefly had a mystery; `10.10.10.x` vs `10.0.10.x` is a different subnet entirely, where nothing would reach the DC. The habit that resolved it: don't trust a glance, run `ipconfig /all` and read the IPv4, DHCP-server, and DNS lines exactly. Cheap habit, prevents expensive confusion.
