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

_(fill in after completing this milestone)_
