# Restore tests from the local backup server

- Host: Proxmox VE 9.2.26, backups from storage `rp-pbs` (PBS 4.2.10, container 105)
- Each restore goes to a new VM ID with new network card addresses (`--unique 1`) and, where it has a network, a new IP, so it cannot clash with the running original.
- This file grows as each restore is done.

## VM 104 (web) restored as VM 204

- Date: 2026-11-14 14:54 (America/Chicago, UTC-06:00)
- Source: [commands and output](2026-11-14T1454-restore-vm104.png)
- Backup used: `rp-pbs:backup/vm/104/2026-11-14T20:18:20Z` (the second backup of VM 104)
- Commands: `qmrestore ... 204 --storage rp-lvm --unique 1`, then `qm set 204 --ipconfig0 ip=10.77.0.24/24,gw=10.77.0.1`, `qm start 204`, then a loop that calls `curl` against `http://10.77.0.24/` every 2 seconds until the web server answers (any response; the content check is separate).
- Method for the times: `restore_seconds` is `qmrestore` alone; `serving_seconds` runs from the start of the restore until the first answer from the web server (restore, IP change, boot). Both measured with `date +%s` in the same command.

| Measure | Result |
|---|---|
| `restore_seconds` | **5** |
| `serving_seconds` | **18** |

Comparison, original (10.77.0.14) against the restored copy (10.77.0.24), run over SSH from the Proxmox host:

| Check | Original | Restored |
|---|---|---|
| `sudo du -sb /var/www/html` | 52,429,444 | 52,429,444 |
| SHA-256 of the list of per-file SHA-256 sums for `index.html` and `assets/*` | `b32faaabe48471c23ed67bb3ec0a88c7c166f876071c851b9c8920570b8b2732` | identical (same value) |

The sizes also match the baseline recorded in [the web server baseline](../phase-1-storage-and-vms/2026-11-14T1235-web-server-built-by-hand.md). The comparison is meaningful because the original's content did not change between the backup and the check.

Predicted before the run: `restore_seconds` 15 to 60, `serving_seconds` 40 to 120. Both came in far lower, so the prediction was too high. This VM is small (8 GiB, about 1.6 GiB of real data), so this says nothing yet about the 15-minute target for the large VMs.

## VM 103 (PostgreSQL) restored as VM 203

- Date: 2026-11-14 15:01 (America/Chicago, UTC-06:00); the PostgreSQL log below is in UTC
- Source: [commands and output](2026-11-14T1501-restore-vm103.png)
- Backup used: `rp-pbs:backup/vm/103/2026-11-14T20:18:13Z`. This backup was taken without freezing the guest's disk, so it is crash-consistent.
- Restored with `--unique 1`, new IP 10.77.0.23, memory reduced to 512 MB for the test (the host is short of RAM).
- Method for the times: as for VM 104, with `ssh_seconds` measured until SSH answers.

| Measure | Result |
|---|---|
| `restore_seconds` | **5** |
| `ssh_seconds` | **17** |
| `SELECT count(*) FROM orders` | **1,000,000** (baseline 1,000,000) |
| `pg_database_size('rp_app')` | **156,497,587 bytes** (baseline 156,497,587, identical) |

PostgreSQL log on the first start of the restored copy: `database system was not properly shut down; automatic recovery in progress`, `redo starts at 0/E679A00`, `redo done at 0/E679B08` (264 bytes of log replayed, elapsed 0.00 s), a checkpoint, then `database system is ready to accept connections`.

So the database came back whole from a backup taken while it was running, by repairing itself from its own log. Here almost nothing needed replaying because the database was idle when the backup ran (about 20 minutes after the load). With writes in flight, a VM backup would restore only to the moment of the snapshot, which is why Phase 3 adds log archiving.

Predicted before the run: restore 6 to 20 s (came in lower), ssh 20 to 60 s (lower), count 1,000,000 (held), size close to the baseline but possibly not identical (it was identical), the automatic-recovery message (held).
