# File server `rp-file` built by hand: data disk, baseline data, NFS and SMB shares

- Date: 2026-11-14 10:37 to 11:06 (America/Chicago, UTC-06:00). Debian VMs keep UTC, so file times in the screenshots are six hours ahead.
- Host: Debian 13 VM `rp-file` (10.77.0.12), tested from `rp-web` (10.77.0.14)
- This was done step by step to learn it; the [`lab/seed-file.sh`](../../lab/seed-file.sh) script in the repository is the automated version of the same steps.
- Sources: [mkfs and mount](2026-11-14T1037-file-server-mkfs-mount.png), [fstab](2026-11-14T1041-file-server-fstab.png), [baseline sizes](2026-11-14T1046-file-server-baseline-sizes.png), [shares configured](2026-11-14T1059-nfs-and-samba-configured.png), [tests from the web VM](2026-11-14T1106-share-tests-from-web-vm.png)

## Data disk

- `lsblk -f` showed `sda` (system, ext4 and EFI partitions) and `sdb` (20 GB) with no filesystem. `sr0` is the cloud-init drive.
- `sudo mkfs.ext4 -L rp-share -m 0 /dev/sdb` created the filesystem; mounted on `/srv/share` it reported 20G size, 2.1M used.
- Persistent mount: `LABEL=rp-share /srv/share ext4 defaults,nofail 0 2` appended to `/etc/fstab` with `sudo tee -a`. Tested without a reboot: `umount`, then `mount -a`, then `df`. `mount -a` printed a hint that systemd still held the old copy of fstab; the mount worked, and `systemctl daemon-reload` refreshes it.

## Baseline data

Created by hand as three kinds of data: 2,000 small text files (compress well), 20 random 20 MB files (unique, incompressible), and one 50 MB random file stored ten times (duplicates).

| Folder | Size (`du -sh`) |
|---|---|
| `docs` | 18M |
| `media` | 401M |
| `archive` | 501M |
| **Total** | **957,609,705 bytes** (`du -sb`), 2,030 files, `df` shows 920M used of 20G (5%) |

`find` and `du` print `Permission denied` for `/srv/share/lost+found`, the root-only repair folder that `mkfs` creates; it is empty, so no number is affected.

## NFS and SMB shares

- NFS: `/srv/share 10.77.0.0/24(ro,sync,no_subtree_check)` in `/etc/exports`. `exportfs -ra` printed nothing, and `exportfs -v` showed the export with `ro` and `root_squash` among its options.
- SMB: a `[share]` section with `path = /srv/share` and `guest ok = Yes`; `read only = yes` is Samba's default and `testparm -s` leaves defaults out. `smbd` and `nfs-server` both `active`. Guest access is for this lab only: a read-only share for a test network.

## Tests from `rp-web` (separate machine over the lab network)

| Test | Result |
|---|---|
| `mount -t nfs 10.77.0.12:/srv/share /mnt/share`, then `ls` | `archive docs lost+found media`; `archive` holds 10 entries |
| `touch /mnt/share/test` | `Read-only file system` (the read-only export holds) |
| `smbclient //10.77.0.12/share -N -c 'ls archive'` | connected as guest; `ls archive\*` lists the ten files, each 52,428,800 bytes, with 19,508,040 KB free |
| `smbclient ... -c 'put /etc/hostname x'` | `NT_STATUS_ACCESS_DENIED` (the read-only share holds) |

The Windows side, `dir \\10.77.0.12\share` from the domain controller, was not run. Windows Server 2025 is expected to refuse guest SMB logons, so a Windows test would need the file server on the domain with real accounts.
