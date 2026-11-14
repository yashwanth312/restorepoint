# ZFS storage re-pointed at the quota dataset; Debian 13 cloud image downloaded

- Date: 2026-11-14 08:30 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve`
- Source: [console screenshot](2026-11-14T0830-zfs-storage-repoint-and-debian-image.png)

## What went wrong first

The `rp-zfs` storage was registered in the [pools step](2026-11-14T0756-lvm-thin-and-zfs-pools.md) with `--pool rp-zfs` (the pool root), in the same script that created the `rp-zfs/shares` dataset with its 40 GB quota. VM disks created on that storage would have landed beside `shares`, not inside it, so the quota would have limited nothing. The gap was noticed while planning the file server VM, before any disk existed on the storage.

A first fix attempt, `pvesm set rp-zfs --pool rp-zfs/shares`, failed with `update storage failed: can't change value of fixed parameter 'pool'`. The pool of a storage entry is fixed once it is created. The attempt changed nothing.

## Fix

```bash
[ -z "$(pvesm list rp-zfs | tail -n +2)" ] || { echo "rp-zfs has volumes, stopping"; exit 1; }
pvesm remove rp-zfs
pvesm add zfspool rp-zfs --pool rp-zfs/shares --content rootdir,images
pvesm status | grep rp-zfs
```

`pvesm list rp-zfs` showed only its header (no volumes), so removing the entry was safe. `pvesm remove` deletes Proxmox's configuration entry only; the ZFS pool and the dataset were not touched.

| Check | Result |
|---|---|
| `pvesm status`, `rp-zfs` | zfspool, active, total 41,943,040 KiB (40 GiB), used 96 KiB |
| Before the fix | total 80,773,120 KiB (the whole pool) |

The total dropping from about 80 GB to exactly 40 GiB shows the 40 GB quota now bounds what Proxmox can place on this storage.

## Debian 13 cloud image

```bash
mkdir -p /root/images && cd /root/images
B=https://cloud.debian.org/images/cloud/trixie/latest
curl -fsSLO $B/debian-13-genericcloud-amd64.qcow2
curl -fsSLO $B/SHA512SUMS
sha512sum -c --ignore-missing SHA512SUMS
```

| Check | Result |
|---|---|
| `sha512sum -c` | `debian-13-genericcloud-amd64.qcow2: OK` |
| Size | 327 MB (qcow2), downloaded Nov 14 08:29 |

The checksum file comes from the same server as the image, so this confirms the download is intact, not who published it.
