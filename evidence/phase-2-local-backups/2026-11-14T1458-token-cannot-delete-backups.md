# The limited token cannot delete backups

- Date: 2026-11-14 14:58 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26, storage `rp-pbs`, which logs in to PBS as `pve@pbs!pve-token` with the role `DatastoreBackup` ([setup](2026-11-14T1344-pbs-container-datastore-and-storage.md))
- Source: [commands and output](2026-11-14T1458-token-cannot-delete.png)

## Test

`pvesm free rp-pbs:backup/vm/104/2026-11-14T20:12:58Z` asks PBS, with the token Proxmox holds, to delete the older of the two VM 104 snapshots.

Result: `proxmox-backup-client failed: Error: permission check failed - missing Datastore.Modify|Datastore.Prune on /datastore/rp-store`. `pvesm list rp-pbs | grep 104` afterwards still lists both VM 104 snapshots (`...T20:12:58Z` and `...T20:18:20Z`).

## What it shows

A host that can create and restore backups with this login cannot delete them. If the Proxmox host were compromised, an attacker holding this token could not remove the existing backups through it. Retention therefore has to run on PBS (prune jobs), not in Proxmox's own retention setting, which would fail with this role. This does not cover someone who gets root on the PBS container or the backup disk itself; the immutable offsite copy in Phase 4 is for that.

Predicted before the run: refusal with a message naming `Datastore.Modify|Datastore.Prune`, both snapshots still listed. Both held.
