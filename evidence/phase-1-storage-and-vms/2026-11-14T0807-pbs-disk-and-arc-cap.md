# PBS datastore disk mounted; ZFS cache cap confirmed

- Date: 2026-11-14 08:07 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve`
- Sources: [mount and read-back](2026-11-14T0807-pbs-disk-mounted.png), [fstab in the editor](2026-11-14T0807-fstab.png)

## Result (transcribed)

| Check | Result |
|---|---|
| `df -h /mnt/rp-pbs` | `/dev/sdd`, 98 GB size, 2.1 MB used, 98 GB available, 1% used, mounted on `/mnt/rp-pbs` |
| `grep rp-pbs /etc/fstab` | `LABEL=rp-pbs /mnt/rp-pbs ext4 defaults,nofail 0 2` (one line) |
| `cat /sys/module/zfs/parameters/zfs_arc_max` | 536870912 (512 MB) |
| `cat /etc/modprobe.d/zfs.conf` | `options zfs zfs_arc_max=536870912` |

The ZFS cache cap is live and persisted, which closes the read-back noted in the [pools evidence](2026-11-14T0756-lvm-thin-and-zfs-pools.md).

## Notes

- `/etc/fstab` was edited by hand in vim rather than by the script's `echo` line. The result is the same single line, and the mount worked. The `mkfs` and empty-disk guard output are not in the screenshots, so they are not claimed. The 2.1 MB used on a fresh disk is ext4's own metadata.
- The disk is not registered as Proxmox storage: Proxmox Backup Server will use the directory directly (Phase 2).
- The mount is not yet proven across a reboot. It will be checked at the next restart.
