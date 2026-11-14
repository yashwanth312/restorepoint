# Debian 13 template and the file server VM (`rp-file`, VMID 102)

- Date: 2026-11-14 08:44 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve`
- Sources: [first boot and storage use](2026-11-14T0844-file-server-vm-first-boot.png), [the failed first attempt](2026-11-14T0836-ostype-typo.png)

## Failed first attempt

`qm create 9000 ... --ostype 126` failed with `400 Parameter verification failed. ostype: value '126' does not have a value in the enumeration ... l24, l26`. The value is `l26` (a lowercase L), and in the console font it looks like the digit 1 and was retyped as such. Nothing was created. The SSH key generation before it succeeded. The retry used a pasted block, wrapped in a subshell so a failing line cannot close the terminal.

## What was built

| Item | Value |
|---|---|
| Lab SSH key | ed25519, `/root/.ssh/rp_lab` on the Proxmox host only (never committed) |
| Template | VMID 9000 `rp-debian13-template`: Debian 13 cloud image imported onto `rp-lvm`, 8 GB, cloud-init drive, user `rp`, key login only, 2 vCPUs, host CPU type |
| File server | VMID 102 `rp-file`: full clone of the template, 1024 MB RAM, 10.77.0.12/24, gateway 10.77.0.1, plus a second 20 GB disk on `rp-zfs` |

The template and clone commands scrolled out of view, so the build itself is not shown in a screenshot; the result below is what the booted VM reports.

## What the booted VM reports (transcribed)

| Check | Result |
|---|---|
| SSH as `rp` with the lab key | works; first-contact warning that the host key was added to known hosts |
| `hostname` | `rp-file` |
| `free -m` | 967 MB total, 256 MB used, 711 MB available, no swap |
| `lsblk -d` | `sda` 8 GB (system), `sdb` 20 GB (share data, on ZFS), `sr0` 4 MB (cloud-init drive) |
| `ping -c1 1.1.1.1` | 1 of 1 replied, 41.6 ms |

## Storage use after the build

| Storage | Total | Used | Used % |
|---|---|---|---|
| `rp-lvm` | 79,532,032 KiB | 2,433,680 KiB (about 2.3 GiB) | 3.06% |
| `rp-zfs` | 41,943,040 KiB | 21,301,856 KiB (about 20.3 GiB) | 50.79% |

The two lines differ on purpose: the LVM-thin disks only use space for blocks actually written, but the 20 GB disk on ZFS reserves its full size up front, so one 20 GB disk takes about half of the 40 GB quota at once. Further ZFS disks must be sized with that in mind.

## Notes

- The 256 MB used is an idle reading with nothing installed. It is a floor, not the file server's real memory use; Samba and NFS are not yet installed.
