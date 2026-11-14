# AD VM `rp-ad` created and Windows Server 2025 installed

- Date: 2026-11-14 09:22 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve`
- Sources: [VM creation and host state](2026-11-14T0912-ad-vm-created.png), [UEFI boot menu](2026-11-14T0912-ad-vm-uefi-boot-menu.png), [SConfig after install](2026-11-14T0922-ad-vm-sconfig-after-install.png)

## VM definition

| Item | Value |
|---|---|
| VMID, name | 101, `rp-ad` |
| Machine, firmware | q35, UEFI (OVMF) with a 4 MB EFI disk on `rp-lvm`, Microsoft Secure Boot keys pre-enrolled |
| CPU, RAM | 2 cores (host type), 2048 MB for the install (to be reduced after measurement) |
| Disk | 40 GB VirtIO SCSI on `rp-lvm` |
| Network | VirtIO, bridge `vmbr0` |
| Optical drives | Windows Server ISO and the VirtIO driver ISO |
| Guest agent | enabled in the VM options (the agent itself is not yet installed in Windows) |

The three Linux VMs were shut down first so the install had the RAM.

## Host state right after start (transcribed)

| Item | Value |
|---|---|
| `qm list` | 101 `rp-ad` running (2048 MB), 102 to 104 stopped, 9000 template stopped |
| `free -m` | 5922 MB total, 1291 used, 3336 free, 4630 available |
| Swap | 595 MB used (0 before the Windows VM started, likely page cache pressure from reading the 7.6 GiB ISO) |
| `df -h /` | 26 GB size, 15 GB used, 10 GB available (59%) |

## Install result

The first boot showed the UEFI boot-device menu with the first DVD entry highlighted ([screenshot](2026-11-14T0912-ad-vm-uefi-boot-menu.png)). The install then completed. The SConfig window title reads `Windows Server 2025 Standard Evaluation`, computer name `WIN-JRQMUEFFS2H` (a name Windows generated), workgroup `WORKGROUP`, remote management enabled. A server that signs in to SConfig is a Server Core install (no desktop).

The installer's edition list and the driver-loading screens were not captured, so the exact edition choices offered are not recorded here.
