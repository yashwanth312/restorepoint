# PostgreSQL and web VMs cloned; first reading with three VMs running

- Date: 2026-11-14 08:52 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve` (5922 MB RAM)
- Source: [console screenshot](2026-11-14T0852-three-linux-vms-running.png)

## What was built

Full clones of template 9000 (see [file server evidence](2026-11-14T0844-debian-template-and-file-server-vm.md)), all key-login only for user `rp`:

| VMID | Name | RAM set | System disk | Address |
|---|---|---|---|---|
| 102 | `rp-file` | 1024 MB | 8 GB, plus 20 GB data disk on ZFS | 10.77.0.12 |
| 103 | `rp-pg` | 1024 MB | 10 GB (grown before first boot) | 10.77.0.13 |
| 104 | `rp-web` | 512 MB | 8 GB | 10.77.0.14 |

## Readings (transcribed)

| Where | Total | Used | Available |
|---|---|---|---|
| Inside `rp-pg` | 967 MB | 223 MB | 744 MB |
| Inside `rp-web` | 464 MB | 91 MB | 373 MB |
| Proxmox host, three VMs running | 5922 MB | 3656 MB | 2265 MB (free 2173 MB, swap used 0) |

`qm list` shows 102, 103 and 104 running and template 9000 stopped.

Before any guest VM existed, the host showed 1632 MB used ([pools evidence](2026-11-14T0756-lvm-thin-and-zfs-pools.md)). The difference, about 2.0 GB, is what the three VMs plus their overhead cost the host a few minutes after boot. The two host readings were taken minutes apart, so this is approximate, and it is a just-booted reading: guests fill their page caches over time, so it will rise.

## What this means for the Windows VM

Windows Server needs roughly 2 GB. With 2265 MB available on the host, a 2 GB domain controller would leave about 200 MB, and the host would start swapping. All four VMs at their planned sizes do not fit comfortably in 5.9 GB. The levers, to be applied from measurements:

1. Install and promote the domain controller with the other three stopped, then try running it at a smaller size (about 1.5 GB) and measure.
2. Shrink the Linux VMs, or allow ballooning so the host can reclaim memory from idle guests.
3. Raise the Proxmox VM's RAM. Not possible without more Windows free memory: with the 6 GB VM running, the host measured about 0.83 GB available ([decision 0006](../../decisions/0006-proxmox-vm-ram-sizing.md)).
