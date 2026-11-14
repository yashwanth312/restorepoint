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

## What changed on the way

1. **The RAM check stopped the first runs.** The first guard needed 7.5 GB free, and the host had 6.8 to 6.9 GB free with apps closed. The threshold was lowered to 6.5 GB, and the VM RAM was then set to 6 GB by hand (see [decision 0006](../../decisions/0006-proxmox-vm-ram-sizing.md)).

## Host memory pressure with the 6 GB VM running (18:34)

Command, in an administrator PowerShell on the host, lab idle, apps closed: `Get-Counter '\Memory\Available MBytes','\Memory\Pages/sec' -SampleInterval 2 -MaxSamples 5`. The screenshot is not committed because it shows the computer's name; the values are transcribed here.

| Sample | Available MBytes | Pages/sec |
|---|---|---|
| 1 | 825 | 16.0 |
| 2 | 828 | 31.2 |
| 3 | 847 | 61.0 |
| 4 | 846 | 51.5 |
| 5 | 846 | 8.0 |

Available memory held steady at about 0.83 GB and paging stayed under 100 per second. That meets the bars set beforehand (above 500 MB available, mostly under 100 pages per second), so 6 GB stands ([decision 0006](../../decisions/0006-proxmox-vm-ram-sizing.md)). This is an idle-lab reading. It has to be repeated with the four lab VMs running, which is the real test of the host margin. Pages/sec also counts ordinary file reads, so it overstates true paging.

## Disk slots

`lsblk -o NAME,SIZE,MODEL,HCTL` ([screenshot](2026-11-13T1834-apt-sources-and-disk-slots.png)):

| Device | Size | SCSI address (controller:channel:target:LUN) | Role |
|---|---|---|---|
| `sdb` | 80 GB | 3:0:0:0 | LVM-thin (`rp-lvm.vhdx`, attached first) |
| `sdc` | 80 GB | 3:0:0:1 | ZFS (`rp-zfs.vhdx`, attached second) |
| `sdd` | 100 GB | 3:0:0:2 | PBS datastore (`rp-pbs.vhdx`, attached third) |

The role of `sdb` and `sdc` follows the attach order; the two 80 GB disks are otherwise identical and empty. The size alone confirms `sdd`.

## Repositories as found

`/etc/apt/sources.list.d/` held `ceph.sources` (enterprise Ceph repo), `debian.sources`, and `pve-enterprise.sources`. Both Proxmox files point at `enterprise.proxmox.com`, which requires a paid subscription. They get disabled, and the `pve-no-subscription` repository added, in the next step.
