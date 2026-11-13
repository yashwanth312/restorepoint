# Proxmox web UI reachable, versions recorded, ISO checksum verified

- Date: 2026-11-13 17:44 (America/Chicago, UTC-06:00)
- Host: Windows 11 Home browser reaching the Proxmox VM over the Hyper-V Default Switch (private address; the browser shows "Not secure" because the certificate is Proxmox's self-signed default)
- Sources: [web UI screenshot](2026-11-13T1744-proxmox-web-ui-summary.png), [hash screenshot](2026-11-13T1744-iso-sha256.png)

## Web UI summary page (transcribed)

| Item | Value |
|---|---|
| Product | Proxmox Virtual Environment 9.2.2, node `pve` |
| Manager version | pve-manager/9.2.2/b9984c6d90a4bd80 |
| Kernel | Linux 7.0.2-6-pve (2026-05-20T08:55Z) |
| Boot mode | Legacy BIOS (Hyper-V Generation 1 VM) |
| CPU | 4 x AMD Ryzen 9 8945HX with Radeon Graphics (1 socket) |
| RAM used | 44.35 percent (1.70 GiB of 3.82 GiB), with the 512 MB test VM running |
| Root disk used | 16.47 percent (4.17 GiB of 25.34 GiB) |
| Swap used | 0 of 3.82 GiB |
| Uptime at capture | 00:41:37 |
| Repository status | Enterprise repository enabled, warning that it needs a valid subscription |
| Storage listed | `local`, `local-lvm`; VM 100 `kvm-test` present |

The task log at the bottom shows the VM 100 resets used for the boot-time measurement ([speed test run 3](2026-11-13T1734-nested-speed-test-v3.md)).

## ISO checksum

Command, run in PowerShell in `C:\lab`:

```powershell
Get-FileHash .\proxmox-ve_9.2-1.iso -Algorithm SHA256
```

Output hash: `4E88FE416DF9B527624A175F24C9AA07C714D3332AFB1EE3DBF3879573EF2C6C`

The Proxmox downloads page lists `4e88fe416df9b527624a175f24c9aa07c714d3332afb1ee3dbf3879573ef2c6c` for the Proxmox VE 9.2-1 ISO installer (checked on 2026-11-13). Same value apart from letter case, so the ISO used for every installer attempt is the published one. Only the checksum was compared; the GPG signature was not checked.

## Expected vs actual

Expected: web UI reachable, versions visible, checksum matches. Actual: all three.

## Note for Phase 1

The enterprise repository is enabled by default and has no subscription, so `apt update` will report errors for it until the no-subscription repository is used instead.
