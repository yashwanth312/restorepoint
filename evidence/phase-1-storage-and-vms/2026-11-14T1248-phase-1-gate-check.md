# Phase 1 gate check: pools, quota, VMs and baselines

- Date: 2026-11-14 12:48 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 (`rp-pve`, 10.77.0.10), run as root on the host
- Sources: [pools, volumes and VM list](2026-11-14T1248-gate-check-pools-lvs-vms.png), [block device layout](2026-11-14T1248-gate-check-lsblk.png)
- Gate: *pools healthy, quotas set, four VMs boot, baseline data sizes recorded*

Commands: `zpool status rp-zfs | head -8`, `zfs get -H -o property,value quota,used,compression rp-zfs/shares`, `vgs rp_vg`, `lvs rp_vg`, `qm list`, `lsblk -o NAME,SIZE,TYPE,MOUNTPOINT`.

## Pools healthy

| Check | Result |
|---|---|
| ZFS pool `rp-zfs` | `state: ONLINE`, one device `sdc`, READ, WRITE and CKSUM counters all 0 |
| LVM volume group `rp_vg` | 1 physical volume, 11 logical volumes, 80 GB, 4 GB unallocated in the group |
| Thin pool `rp_vg/data` | 75.85 GB, **Data 25.46%** (about 19.3 GB written, calculated from the percentage), **metadata 18.14%** |

`head -8` cut off the `errors:` line of `zpool status`, so "No known data errors" is not in this output; the zero error counters are. A full `zpool status` is the first check of Phase 2.

## Quota set

`rp-zfs/shares`: quota 40G, used 20.3G, compression lz4. The used figure is mostly the file server's 20 GB data disk, which a ZFS volume reserves in full.

## Four VMs boot

`qm list`: 101 `rp-ad` (2048 MB, 40 GB disk), 102 `rp-file` (1024 MB, 8 GB), 103 `rp-pg` (1024 MB, 10 GB), 104 `rp-web` (512 MB, 8 GB) all `running`; 9000 `rp-debian13-template` stopped, as a template should be.

## Storage layout

`lsblk`: `sda` 60G (Proxmox install, `pve-root` 25.9G, swap 3.8G, unused `pve-data` 20.4G), `sdb` 80G (thin pool `rp_vg-data`, 75.8G, holding every VM system disk), `sdc` 80G (ZFS, `zd0` is the 20G volume that is the file server's data disk), `sdd` 100G mounted at `/mnt/rp-pbs` (reserved for the backup datastore).

Written share of each thin disk (`Data%` column): AD system disk 33.39% of 40 GB, file server system disk 18.28% of 8 GB, PostgreSQL disk 20.34% of 10 GB, web disk 18.98% of 8 GB, template 11.72% of 8 GB. The virtual disks add up to about 74 GB against a 75.85 GB pool, so the pool depends on thin provisioning; `Data%` is the number to watch during the Phase 5 restore drills.

## Baseline data sizes recorded

| VM | Baseline | Evidence |
|---|---|---|
| `rp-ad` | 28 users, 268 directory objects, `ntds.dit` 41,943,040 bytes | [AD baseline](2026-11-14T1246-ad-baseline.md) |
| `rp-file` | 957,609,705 bytes in 2,030 files (text, unique, duplicate data) | [file server](2026-11-14T1106-file-server-built-by-hand.md) |
| `rp-pg` | 1,000,000 rows, database 156,497,587 bytes | [PostgreSQL](2026-11-14T1158-postgres-built-by-hand.md) |
| `rp-web` | 52,429,444 bytes in `/var/www/html` (ten 5 MiB assets) | [web server](2026-11-14T1235-web-server-built-by-hand.md) |

## Result

All four gate conditions have recorded evidence. Predictions made before the run all held: pool ONLINE, quota 40G with lz4, thin pool Data% inside 20 to 40%, VMs 101 to 104 running.
