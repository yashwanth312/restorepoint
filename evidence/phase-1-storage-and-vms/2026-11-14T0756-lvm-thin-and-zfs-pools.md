# LVM-thin pool on `sdb` and ZFS pool with a quota on `sdc`

- Date: 2026-11-14 07:56 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve`, 6 GB RAM
- Sources: [creation commands](2026-11-14T0756-storage-create.png), [verification](2026-11-14T0756-storage-verify.png)

## Commands

```bash
pvcreate /dev/sdb
vgcreate rp_vg /dev/sdb
lvcreate -l 95%FREE -T rp_vg/data
pvesm add lvmthin rp-lvm --vgname rp_vg --thinpool data --content rootdir,images

zpool create -o ashift=12 -O compression=lz4 -O atime=off rp-zfs /dev/sdc
zfs create -o quota=40G rp-zfs/shares
pvesm add zfspool rp-zfs --pool rp-zfs --content rootdir,images
echo "options zfs zfs_arc_max=536870912" > /etc/modprobe.d/zfs.conf
echo 536870912 > /sys/module/zfs/parameters/zfs_arc_max
```

## Results (transcribed)

| Check | Result |
|---|---|
| `zpool status rp-zfs` | ONLINE, `sdc` ONLINE, read/write/checksum errors 0/0/0, no known data errors |
| `zfs get quota` | `rp-zfs/shares` quota 40G (set locally); pool root has none |
| `zfs get compression` | `rp-zfs/shares` lz4, inherited from the pool |
| `lvs rp_vg` | thin pool `data`, 75.85 GiB, data 0.00%, metadata 10.44% |
| `pvesm status` | `local` (dir) 21.11% used, `local-lvm` active, `rp-lvm` (lvmthin) 79,532,032 KiB total, `rp-zfs` (zfspool) 80,773,120 KiB total, all active |
| `free -m` | 5922 MB total, 1632 used, 4289 available, swap 0 used |

The thin pool chunk size is 64 KiB, which the tool reported as able to address up to about 15.9 TiB, far beyond this disk.

## Notes

- Commands were entered one at a time, not as the pasted script. The empty-disk guard output is not in the screenshots, so it is not claimed as run. Both disks had been seen empty in `lsblk` before.
- The ZFS cache cap was written to the running system and to `/etc/modprobe.d/zfs.conf` without errors, but the live value was not read back. A read-back of `/sys/module/zfs/parameters/zfs_arc_max` is still to do, and the cap must survive a reboot.
- `local-lvm` (20 GB, on the install disk) is unchanged and not used by the lab.
