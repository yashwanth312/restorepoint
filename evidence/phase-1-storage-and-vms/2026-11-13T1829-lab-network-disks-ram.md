# Fixed lab network, three data disks and 6 GB of RAM on the Proxmox VM

- Date: 2026-11-13 18:29 (America/Chicago, UTC-06:00)
- Host: Windows 11 Home, 15.3 GB RAM, apps closed. Proxmox VE 9.2.2 in Hyper-V Generation 1 VM `rp-pve`.
- Source: [Proxmox console screenshot](2026-11-13T1829-proxmox-network-disks-ram.png)

## What was changed

| Layer | Change |
|---|---|
| Hyper-V | Internal switch `rp-lab`, host address 10.77.0.1/24, NAT `rp-lab-nat` for 10.77.0.0/24. The Default Switch is no longer used, because its subnet changes after a Windows restart. |
| Hyper-V | `rp-pve` set to 8 vCPUs, static 6 GB RAM, and three thin SCSI disks: `rp-lvm.vhdx` 80 GB, `rp-zfs.vhdx` 80 GB, `rp-pbs.vhdx` 100 GB in `C:\lab\vm`. |
| Proxmox | `vmbr0` moved to 10.77.0.10/24 with gateway 10.77.0.1, `/etc/hosts` updated, DNS set to 1.1.1.1 and 8.8.8.8. The Phase 0 test VM 100 and the Alpine ISO were removed. |

## What the VM reports (transcribed from the screenshot)

| Check | Result |
|---|---|
| `ip -br a` | `vmbr0` UP at 10.77.0.10/24 |
| `lsblk` | `sda` 60 GB (Proxmox install), plus new empty disks `sdb` 80 GB, `sdc` 80 GB, `sdd` 100 GB |
| `free -m` | 5922 MB total, 1522 MB used, 4400 MB available, swap 3911 MB with 0 used |
| `ping -c4 1.1.1.1` | 4 of 4 replied, 0% loss, min/avg/max 29.6/35.1/42.7 ms |
| Web UI | Console opened from `https://10.77.0.10:8006` in the Windows browser |

Which of `sdb`, `sdc`, `sdd` is which VHDX is not yet confirmed. The sizes (80, 80, 100) map to the disks, but the two 80 GB disks look identical. Phase 1 pins them by serial or by size-and-order before creating pools.

## Failures on the way (kept on purpose)

1. **First run: VM was still running.** `Set-VM`, `Set-VMProcessor` and `Add-VMScsiController` all refused because these settings only change while the VM is Off. The script had also computed `free 1.4 GB, VM gets -1 GB` and Hyper-V rejected the negative size, so nothing was damaged. The three VHDX files were created fine.
2. **Guarded runs stopped on RAM.** The first guard needed 7.5 GB free, and the host had 6.8 to 6.9 GB free with apps closed. The threshold was lowered to 6.5 GB, and the VM RAM was then set to 6 GB by hand (see [decision 0006](../../decisions/0006-proxmox-vm-ram-sizing.md)).
3. **Missing script output.** An early `throw` swallowed the `free ... GB` line and the NAT listing. The script now uses `Write-Host` and `Out-Host`, and creates the switch, address and NAT only if they are missing.

## Not yet measured

- Host memory pressure with the 6 GB VM running (`Available MBytes`, `Pages/sec`). The counter command has been given; the output is still to come.
- The pasted PowerShell output of the final run was not captured, so the Hyper-V side of this log rests on the Proxmox-side result above, not on the script's own printout.
