# AD VM network: driver, address, firewall, SSH

- Date: 2026-11-14 09:31 to 09:51 (America/Chicago, UTC-06:00)
- Host: Windows Server 2025 Standard Evaluation (Server Core) in VM `rp-ad`, on the lab network 10.77.0.0/24
- Sources: [empty adapter name](2026-11-14T0931-ad-no-adapter-empty-alias.png), [driver installed](2026-11-14T0935-ad-netkvm-driver-installed.png), [address set](2026-11-14T0945-ad-ip-address-set.png), [DNS, ping and agent commands](2026-11-14T0945-ad-dns-ping-agent.png), [Windows RAM reading](2026-11-14T0945-ad-windows-ram-idle.png), [Proxmox cannot reach the VM](2026-11-14T0945-proxmox-cannot-reach-ad.png)

## Failure 1: no network adapter

`$a=(Get-NetAdapter | select -First 1).Name` returned nothing, and `New-NetIPAddress -InterfaceAlias $a` failed with `Cannot bind argument to parameter 'InterfaceAlias' because it is an empty string`. Windows had no driver for the VirtIO network card, so it did not list an adapter at all. The empty name was a symptom; the cause was the missing driver. The all-in-one VirtIO installer step had not produced a working adapter.

Fix, in PowerShell on the VM:

```powershell
$v=(Get-Volume | ? FileSystemLabel -like 'virtio-win*').DriveLetter
$f=(Get-ChildItem "${v}:\NetKVM" -Recurse -Filter netkvm.inf | ? FullName -match '2k25.amd64' | select -First 1).FullName
pnputil /add-driver $f /install
Get-NetAdapter
```

Result: drive `D`, driver `D:\NetKVM\2k25\amd64\netkvm.inf` added as `oem1.inf`, and `Get-NetAdapter` lists `Ethernet`, Red Hat VirtIO Ethernet Adapter, status Up, 10 Gbps.

## Address and outbound check

```powershell
New-NetIPAddress -InterfaceAlias Ethernet -IPAddress 10.77.0.11 -PrefixLength 24 -DefaultGateway 10.77.0.1
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses 1.1.1.1
Start-Service sshd; Set-Service sshd -StartupType Automatic
Test-Connection 1.1.1.1 -Count 1
```

The address printed in `Tentative` state (still doing the duplicate-address check) and is a normal first reading. `Test-Connection 1.1.1.1` replied in 35 ms, so the VM reaches the internet through the lab NAT. A guest agent installer was started from `D:\guest-agent\qemu-ga-x86_64.msi`; its outcome was not captured.

## Failure 2: Proxmox could not reach the VM

From the Proxmox host, `ping 10.77.0.11` lost 8 of 8 packets and `ssh Administrator@10.77.0.11` hung with no answer. The Linux VMs on the same bridge were reachable earlier, and the VM could reach the internet, so the network path was fine. Windows' firewall drops inbound ping and unlisted inbound connections by default; a hang (rather than an immediate "connection refused") points to packets being dropped.

Fix, in PowerShell on the VM:

```powershell
New-NetFirewallRule -Name rp-lab-ssh -DisplayName 'RP lab SSH' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Any
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In
```

Result: SSH from the Proxmox shell worked afterwards (reported by the person running it; the output was not captured). The two firewall rules apply to any network profile, which is acceptable only because this network is the isolated lab network. The status of the `sshd` service and the network profile were also queried; their output was not captured.

## First Windows RAM reading

Before the server is a domain controller: `1980 MB total, 577 MB free`, about 1.4 GB in use. Windows Update was set to download only and may have been active right after the install, so this is an upper estimate for an idle server, not a final figure. The domain controller will be measured again after promotion.
