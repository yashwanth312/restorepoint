# Six simulated days of change: stored growth, dedup factor, and two domain controller freeze errors

- Date: 2026-11-18, run about 10:25 to 10:35, garbage collection 10:44 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve`, Proxmox Backup Server 4.2.10 in container 105, datastore `rp-store` on its own virtual disk
- Script: [`lab/simulate-days.sh`](../../lab/simulate-days.sh), run as `setsid nohup /root/simulate-days.sh 6 > /root/sim.log 2>&1 < /dev/null &`
- Sources: [log, days 1 to 3](2026-11-18T1032-simulation-log-days-1-to-3.png), [log, days 4 to 6](2026-11-18T1032-simulation-log-days-4-to-6.png), [unedited garbage collection log](2026-11-18T1044-gc-task-log.txt), snapshot counts and the script transcribed from console screenshots

## What was done

Six rounds, back to back. Each round changed data on the four VMs, then ran `vzdump 101 102 103 104 --storage rp-pbs --mode snapshot`, so each round is one snapshot per VM. The six rounds took a few minutes of wall-clock time; they are simulated days, not real ones.

The change rate is an assumption, not a measurement of any real workload. Per simulated day: 5 files of 20 MB of random data on the file server, 2 files of 5 MB of random data on the web server, 50,000 inserted rows in the PostgreSQL `orders` table, and 5 disabled users in the directory. Random data neither compresses nor deduplicates, so it is a pessimistic input for the files and a neutral one for the rest.

## Stored size after each round (`pvesm status`, used)

| After | Used (KiB) | Used (GiB) | Change (MiB) |
|---|---|---|---|
| Before the run | 9,085,600 | 8.66 | |
| Day 1 | 14,603,888 | 13.93 | +5,389 |
| Day 2 | 14,827,816 | 14.14 | +219 |
| Day 3 | 15,008,264 | 14.31 | +176 |
| Day 4 | 15,177,468 | 14.47 | +165 |
| Day 5 | 15,401,388 | 14.69 | +219 |
| Day 6 | 15,619,856 | 14.90 | +213 |

Days 2 to 6 averaged about 198 MiB per day, roughly 1.7 times the 120 MB or so injected per day. This fits 4 MiB backup chunks that are rewritten whole when a few bytes change, plus background changes inside the guests. The two were not separated.

Day 1 grew by 5.26 GiB, far above the injected data. In that round the domain controller reused 76% of its chunks, against 96 to 98% for the three Linux VMs. The domain controller had been running for days since its previous backup. What changed inside it was not isolated.

## Garbage collection result (unedited log linked above)

| Line in the log | Value |
|---|---|
| Index files | 43 (snapshots 7, 7, 7, 8 for VMs 101 to 104; VM 101 and VM 102 have two disk images each) |
| Original data usage | 610.004 GiB |
| On-Disk usage | 14.617 GiB, 9,454 chunks, average chunk 1.583 MiB |
| Deduplication factor | 41.73 |
| Removed | 1 chunk, 235.4 KiB |

`pvesm` reports 14.90 GiB used against 14.617 GiB of chunk data. The difference of about 0.28 GiB is probably the datastore's 65,536 chunk folders and other file system overhead. That was not checked.

## The honest ratio

PBS computes 41.73 as 610.004 / 14.617. The 610 GiB is the sum of every virtual disk's full size across all snapshots, so it counts empty disk space as data. It is the number PBS prints, but it is not a fair dedup claim.

Fair method: take only the data that is not zero, count it once per snapshot, and divide by the on-disk size. The non-zero amount per VM comes from the day 1 `total zero data` lines in the backup log: 40 - 19.72 = 20.28 GiB for VM 101, 28 - 25.12 = 2.88 GiB for VM 102, 10 - 7.77 = 2.23 GiB for VM 103, 8 - 6.38 = 1.62 GiB for VM 104, which is 27.01 GiB per snapshot of all four.

| VM | Non-zero GiB per snapshot | Snapshots | Total GiB |
|---|---|---|---|
| 101 | 20.28 | 7 | 141.96 |
| 102 | 2.88 | 7 | 20.16 |
| 103 | 2.23 | 7 | 15.61 |
| 104 | 1.62 | 8 | 12.96 |
| All | | 29 | 190.69 |

190.69 / 14.617 = **13.05, about 13:1.**

Caveats that go with that number:
- The per-snapshot non-zero size is taken from day 1 and assumed constant. The data grew by roughly 0.1 GiB a day, so the true figure is probably a few percent higher (13.0 to 13.5).
- The on-disk size is after PBS's own compression, so the ratio mixes dedup and compression.
- It depends on the snapshot count (29 here) and on the invented change rate above. A longer retention window or a quieter workload gives a higher ratio.
- Only the 41.73 is printed by PBS. The 13:1 is arithmetic on log lines, not a measurement by PBS.

## Expected vs actual

| Predicted before the run | Actual |
|---|---|
| Growth of 150 to 300 MB per day | 165 to 219 MiB per day on days 2 to 6 (matches) |
| `rp-pbs` used grows from 9.3 GB to about 10 to 11 GB | 15.99 GB (14.90 GiB); wrong, because of the day 1 jump |
| No errors | Two freeze errors on the domain controller (below) |

## Two domain controller backups ran without the Windows freeze

| Day | Domain controller backup | Error line in the log |
|---|---|---|
| 2 | 1 min 38 s | `unable to freeze guest fs - timeout when try to receive Frozen event from VSS provider: Windows error 0x80004005: Unspecified error` |
| 3 | 12 s | `unable to freeze guest fs - failed to start snapshot set: Windows error 0x80042316` |

Days 1, 4, 5 and 6 show no error line. The domain controller backup took 12 s to 98 s across the six rounds.

Both backups still finished, but with no filesystem freeze they are crash-consistent only, not application-consistent. The earlier manual domain controller backup, with a working freeze, took 48 s. The likely cause is back-to-back rounds a few minutes apart, which a nightly job would not do, but this was not tested. The error code `0x80042316` probably means another shadow copy operation was still in progress; this was not checked either.

Consequence for the plan: the nightly job in the next step has to check the backup log for a freeze error and fail loudly, so a domain controller snapshot taken without the freeze is never silently counted as a good one.

## Notes on how the run went

- The first versions of the script reached the domain controller over SSH, which was never set up for `Administrator`, and a later version stopped on harmless PowerShell progress output. The step now uses `qm guest exec`, and the script stops on a real error record or a non-zero exit code. Both stops came before any backup.
- Because of those aborted attempts, day 1's file, database and web changes ran three times in total. The `orders` table should therefore hold about 400,000 more rows than a single clean run of 6 days would add (the table was not counted).
- Directory users `day1user1` to `day1user5` from an aborted attempt were removed before the final run.

## What this does not prove

That the ratio holds for real data or a real change rate. That the domain controller backups are consistent on every day. That a restore from any of the six new snapshots works; only the earlier snapshots were restored ([restore tests](2026-11-14T1454-restore-tests.md)).
