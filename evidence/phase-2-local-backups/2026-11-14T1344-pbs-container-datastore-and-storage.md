# Proxmox Backup Server in a container: install, datastore, limited login, storage link

- Date: 2026-11-14 13:07 to 14:01 (America/Chicago, UTC-06:00). PBS prints times in UTC, six hours ahead.
- Host: Proxmox VE 9.2.26 (`rp-pve`), container 105 `rp-pbs` (10.77.0.15), Proxmox Backup Server 4.2.10-1
- Decision: [0008](../../decisions/0008-pbs-in-a-container.md)
- Sources: [container created](2026-11-14T1319-pbs-container-created.png), [container checks](2026-11-14T1319-pbs-container-checks.png), [services and RAM](2026-11-14T1337-pbs-services-and-ram.png), [datastore](2026-11-14T1344-datastore-created.png), [storage connected](2026-11-14T1401-pbs-storage-connected.png)

## Container

- Template `debian-13-standard_13.6-1_amd64` (`pveam update` and `pveam available` listed it; the archive extracted to 528 MiB).
- `pct create 105 ... --unprivileged 1 --cores 2 --memory 1024 --swap 0 --rootfs rp-lvm:8 --net0 name=eth0,bridge=vmbr0,ip=10.77.0.15/24,gw=10.77.0.1 --nameserver 1.1.1.1 --ssh-public-keys ... --mp0 /mnt/rp-pbs,mp=/mnt/rp-pbs --onboot 1`, preceded by a check that VM 102 sits on `vmbr0`.
- The backup disk folder was set to `100034:100034` on the host. Inside the container it shows as `34 34`, the `backup` user, because an unprivileged container shifts user IDs by 100000.
- Checks: `status: running`, Debian GNU/Linux 13 (trixie), `df` shows `/dev/sdd` 98G for `/mnt/rp-pbs`, `free -m` total 1024 with 16 used, ping to 1.1.1.1 succeeds.
- Two warnings at creation. Proxmox warned that the thin volumes now add up to about 82 GiB against a 75.85 GiB pool (the pool is oversubscribed, which only matters if real data fills it; at the time it was about 25% used). systemd 257 suggested enabling nesting, so `pct set 105 --features nesting=1` was applied before installing PBS.

## PBS install and first checks

- Added the Proxmox archive keyring and a `pbs-no-subscription` source for `trixie` (deb822 format); `apt-cache policy` offered `proxmox-backup-server` 4.2.10-1. Installed `proxmox-backup-server` (not `proxmox-backup`, which adds a kernel a container cannot use).
- `systemctl is-active proxmox-backup proxmox-backup-proxy`: both `active`. `proxmox-backup-manager versions`: 4.2.10-1. Port 8007 listening. Web interface reachable at port 8007 from the Windows browser.
- Idle memory: 29 MB used of 1024 MB. I predicted 150 to 350 MB, so that was wrong by a wide margin; the idle figure says little about use during a backup (see the backup evidence).
- The PBS dashboard shows a "non production-ready repository" notice. That is the free no-subscription repository, chosen on purpose.

## Datastore

`proxmox-backup-manager datastore create rp-store /mnt/rp-pbs/store`. The folder is owned by `backup:backup` and holds a `.chunks` directory with exactly 65,536 sub-folders (predicted from memory of how PBS works, and confirmed). The empty store already reports 271.67 MB used on the PBS dashboard: those folders are fixed overhead, not backup data.

## Limited login for Proxmox

PBS user `pve@pbs` and API token `pve-token`, both with the role `DatastoreBackup` on `/datastore/rp-store` (`acl list` shows two rows, propagate 1). The token secret was shown once, copied by the user straight into the Proxmox storage form, and appears in no file, screenshot or message. The role is intended to allow creating and restoring backups but not deleting other backups; that limit is still to be tested.

## Proxmox storage

Added through the web interface as storage `rp-pbs` (server 10.77.0.15, datastore `rp-store`, token login, fingerprint pasted, **auto-generated client encryption key**). `pvesm status`: `rp-pbs` type `pbs`, `active`, 102,626,232 KiB total, 265,300 KiB used. `/etc/pve/priv/storage/` holds `rp-pbs.enc` (255 bytes, the encryption key) and `rp-pbs.pw` (37 bytes, the stored token secret), both readable by root only. I predicted only the `.enc` file; the `.pw` file is how Proxmox logs in on its own.

The encryption key is not in this repository and never will be. A copy kept outside the lab is needed for the site-loss rebuild in Phase 6.
