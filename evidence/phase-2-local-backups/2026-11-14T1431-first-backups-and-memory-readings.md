# First backups to PBS: one VM, then all four, with memory readings

- Date: 2026-11-14 14:07 to 14:31 (America/Chicago, UTC-06:00). PBS and snapshot names use UTC (`T20:17:12Z` is 14:17:12 here).
- Host: Proxmox VE 9.2.26, backups to storage `rp-pbs` (container 105)
- Sources: [interrupted run](2026-11-14T1410-first-backup-interrupted.png), [VM 104 backup](2026-11-14T1414-first-backup-vm104.png), [memory samples](2026-11-14T1422-four-vm-backup-memory-samples.png), [backup log](2026-11-14T1422-four-vm-backup-log.png), [swap and stored size](2026-11-14T1431-swap-activity-and-stored-size.png), [snapshots](2026-11-14T1431-snapshots-encrypted.png)

## What changed on the way

The first attempt, `vzdump 104 --storage rp-pbs --mode snapshot` started with `&` in the web console shell, ended with `ERROR: interrupted by signal` at 14:07:04 and left nothing behind (VM 104 running, no lock, no snapshot). The cause was not established; the job was tied to the console session. The run was repeated detached with `setsid nohup ... < /dev/null &` and worked. The memory readings taken in the first two attempts were taken while no backup was running, so they are not used; the readings below are from the four-VM run, started and sampled from one command line.

## Result

`vzdump 101 102 103 104 --storage rp-pbs --mode snapshot`: `Backup job finished successfully`, about 70 seconds in total.

| VM | Time | Zero data skipped (log) | Note |
|---|---|---|---|
| 101 `rp-ad` (40 GiB) | 48 s | 19.98 GiB (49%) | guest-agent `fs-freeze` issued (app-consistent) |
| 102 `rp-file` (8 + 20 GiB) | 13 s | 25.45 GiB (90%) | freeze disabled in VM options |
| 103 `rp-pg` (10 GiB) | 7 s | 7.90 GiB (78%) | freeze disabled in VM options |
| 104 `rp-web` (8 GiB), second backup | 2 s | not captured | 99% reused (7.99 GiB), incremental |

VM 104's first successful backup (14:12:58 here) took 7 s and skipped 6.40 GiB (80%) of zero data. The Linux VMs are therefore crash-consistent backups, not application-consistent ones; for PostgreSQL that is what the log archiving in Phase 3 is for.

Five snapshots exist (101, 102, 103, and two of 104), all marked **Encrypted**, owner `pve@pbs!pve-token`, verify state `None` (not yet verified).

## Memory and swap during the run

| Reading | Value |
|---|---|
| PBS container, memory used (1,024 MB limit) | 34 to 49 MB during the run (peak 49 MB) |
| Proxmox host, available memory | 1,145 to 1,280 MB at the start, lowest 765 MB at 14:18:06, about 1,100 MB afterwards |
| Proxmox host, swap used | 1,157 MB at the first sample, 1,274 MB shortly after, 1,272 MB at the end |
| `vmstat 5 3` after the run (rows two and three) | swap in 4 and 2 KB/s, swap out 0 |

Predicted before the run: container under about 300 MB (held), host available above about 800 MB (missed: 765 MB), swap flat (missed: it rose by about 117 MB at the start and stayed up). The only earlier swap figure is 584 MB from Phase 1 before PBS existed, so swap use roughly doubled since then. After the run, the host was not actively swapping.

## Stored size

`pvesm status`: `rp-pbs` 9,085,596 KiB used (8.85% of 102,626,232 KiB), which includes about 0.27 GB of fixed folder overhead. `pvesm list rp-pbs` sizes add up to 100,932,277,333 bytes of virtual disk across the five snapshots. The raw ratio, 100.9 GB over 9.30 GB, is about 10.9 to 1; **this is not a dedup result**, because it counts the empty space in the virtual disks. No dedup ratio is claimed yet. The method has to exclude empty space and be repeated after some data changes; it is recorded in a later entry.
