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

## VM 101 (domain controller) restored as VM 201

- Date: 2026-11-14 15:08 to 15:48 (America/Chicago, UTC-06:00). The guest's own clock showed the same local time.
- Backup used: `rp-pbs:backup/vm/101/2026-11-14T20:17:12Z` (taken with the guest's disk frozen through the guest agent). The disk is 40 GiB, about half of it real data.
- To avoid a clash with the running domain controller, the file server, web server and PostgreSQL copy were stopped to free memory (a guard stopped the run unless 1,800 MB was available), and the copy was never attached to the lab network.
- Method for the times: `restore_seconds` is `qmrestore` alone; `agent_seconds` runs from the start of the restore until the guest agent answers; `ad_seconds` runs until `(Get-ADObject -Filter * -Server localhost).Count` run through the guest agent returns 268. All three come from `date +%s` in the same command.

### First run, network card removed: AD did not answer

Sources: [first run](2026-11-14T1523-restore-vm101-first-run.png), [services and log](2026-11-14T1526-restore-vm101-services-and-log.png), [localhost check](2026-11-14T1530-restore-vm101-localhost-check.png), [control check](2026-11-14T1532-restore-vm101-control-check.png), [listening ports](2026-11-14T1536-restore-vm101-listening-ports.png)

- `restore_seconds=35`, `agent_seconds=62`, no network card (`qm config 201 | grep -c net` printed 0). The wait for AD ran its full 600 seconds and gave up, so no `ad_seconds` exists for this run. `ntds.dit` was present at 41,943,040 bytes, but every AD PowerShell command failed with `Server instance not found on the given port`.
- All five services were `Running` (`NTDS`, `ADWS`, `DNS`, `Netlogon`, `KDC`), and the Directory Service log showed startup complete about 15 seconds after the boot time of 3:05:57 PM. First guess (ADWS stopped) was wrong.
- Second guess, that the check needed `-Server localhost` because there was no network to find a domain controller on, was wrong: the same error came back.
- Control: the identical commands on the original domain controller returned 268 objects and 28 users (web-service cmdlet and direct LDAP). On the copy the cmdlet failed and a direct LDAP search said `The server is not operational`. So the check method was fine and the copy was the problem.
- Listening ports (`53, 88, 389, 636, 3268, 9389` on the original): on the copy only `53, 88, 9389`, so **LDAP was not listening**; the copy had only the loopback address. The only Directory Service warnings, on both machines, were two configuration notices (events 3054 and 3051); nothing pointed at restore detection.

### Fix: a network card on an isolated bridge

Source: [isolated bridge and card attached](2026-11-14T1542-restore-vm101-isolated-bridge.png)

Created `vmbr9` on the Proxmox host (no physical port, no IP, no route to the lab; stanza in [decision 0009](../../decisions/0009-isolated-bridge-for-restore-drills.md)) and ran `qm set 201 --net0 virtio,bridge=vmbr9` on the running copy. After 30 seconds, with no reboot, the copy listened on `53, 88, 389, 636, 3268, 9389` and showed `10.77.0.11 on Ethernet`: Windows applied the old card's saved static address to the new card. That is the original domain controller's address, which is why the bridge has to be isolated. Predicted instead: a `169.254.` placeholder address (wrong); LDAP up without a reboot (held).

### Clean run, isolated card from the start

Source: [clean run](2026-11-14T1548-restore-vm101-clean-run.png)

The test copy was deleted and restored again with `net0` on `vmbr9` before the first start.

| Measure | Result |
|---|---|
| Restore image | 42,949,672,960 bytes in 33.97 s (reported speed 1,205.75 MB/s) |
| `restore_seconds` | **36** |
| `agent_seconds` | **64** |
| `ad_seconds` (AD answering 268 objects) | **91** |
| Users / objects / `ntds.dit` / domain | 28 / 268 / 41,943,040 bytes / `rp.test` (all equal to the [AD baseline](../phase-1-storage-and-vms/2026-11-14T1246-ad-baseline.md)) |

Predicted for this run: restore 20 to 40 s, agent 45 to 90 s, AD 60 to 150 s, content equal to the baseline. All held. Against the 15-minute target (900 s), the 40 GiB domain controller was answering queries in 91 seconds.

Caveats: one clean run; nested lab with backup disk and VM disks on the same SSD; the copy was checked through the guest agent and not from another machine, so logons, DNS lookups from clients and replication were not tested.
