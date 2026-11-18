# Daily backup job, PBS retention jobs, time zone mismatch, and the backup check

- Date: 2026-11-18, 11:31 to 11:57 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve`; Proxmox Backup Server 4.2.10 in container 105
- Scope: [decision 0010](../../decisions/0010-one-week-scope.md): daily job from 2026-11-18 through 2026-11-24
- Sources: screenshots linked below; the check script is [`lab/backup-check.sh`](../../lab/backup-check.sh)

## Daily backup job (Proxmox side)

Created in the web UI, then read back with `cat /etc/pve/jobs.cfg` ([screenshot](2026-11-18T1149-daily-job-config.png)):

| Setting | Value |
|---|---|
| Schedule | `15:00` (host time zone America/Chicago, confirmed with `timedatectl`, clock synchronised) |
| Selection | VMs 101, 102, 103, 104 only |
| Mode, storage | snapshot, `rp-pbs` |
| Retention on the Proxmox side | `keep-all=1`, because the limited backup token cannot prune; retention is enforced by PBS prune jobs |
| `repeat-missed` | 0, so a missed run is not made up |

One manual Run now, about 11:33 ([task log](2026-11-18T1135-daily-job-run-now-task-log.png)): all four VMs finished (VM 101 in 25 s, the others in 1 to 2 s), no `ERROR` or `WARN` line, `TASK OK`. The backup disk read 15,939,740 KiB used afterwards, 312 MiB above the end of the six-day simulation. No freeze error this time, after hours of gap; the day 2 and day 3 errors happened minutes after the previous backup, which may be the cause but was not tested.

## PBS jobs

| Job | Setting as created | Source |
|---|---|---|
| Prune | daily 16:00, keep daily 7, weekly 4, monthly 6, root namespace | [screenshot](2026-11-18T1144-prune-and-gc-jobs-utc.png) |
| Garbage collection | daily 16:30 (daily only so space returns within the one-week window) | same screenshot |
| Verify | daily 17:00, skip already verified, re-verify after 30 days | [screenshot](2026-11-18T1144-verify-job.png) |

## Found: PBS reads schedules in its own time zone, which was UTC

Expected: the jobs run at 16:00, 16:30 and 17:00 local time. Actual: the screenshot shows Next Run as 10:00, 10:30 and 11:00 for those schedules. The garbage collection log from earlier in the day also carries `+00:00` timestamps. So the container ran on UTC and read the schedules as UTC, which put the jobs before the 15:00 backup, at times the workstation may be off.

Fix: link `/etc/localtime` in container 105 to `/usr/share/zoneinfo/America/Chicago` and restart `proxmox-backup` and `proxmox-backup-proxy`. A first attempt used a wrong path and the container stayed on UTC (`date` showed UTC). After the corrected link the Next Run times were reported as correct by the user; the output was not captured.

## Snapshots after the first prune

The Content tab ([screenshot](2026-11-18T1144-content-after-prune.png)) lists two snapshots per VM: the last one of 2026-11-14 and today's 11:32 run. The six simulation snapshots from earlier today are no longer listed. The scheduled prune job showed no last run at that point, so the removal was done by hand. This matches the prediction that PBS keeps the last backup of each calendar day: 8 snapshots remain out of about 33. Space from the removed snapshots is freed only by a garbage collection more than 24 hours later. The 13:1 dedup figure in the [six-day simulation](2026-11-18T1044-six-day-simulation-and-dedup-factor.md) can no longer be re-derived from the store.

## Backup check (new script)

Runs from cron at 15:10, ten minutes after the backup. It looks at the latest backup task log and fails if no backup ran within a window (default 30 minutes), fewer than four VMs finished, the task did not end `TASK OK`, or the log contains `unable to freeze`, `ERROR` or `WARN`. It writes one line to `/var/log/rp-backup-check.log` and to the system log and exits 1 on failure. There is no email in the lab, so a failure is a line in a log, not a message sent to anyone.

Three runs, with the predictions made beforehand ([screenshot](2026-11-18T1157-backup-check-tests.png)):

| Run | Predicted | Actual |
|---|---|---|
| Latest backup, 30-minute window | `OK`, exit 0 | `OK`, exit 0 |
| `WINDOW=1` | `FAIL`, no backup task in the last 1 minutes | as predicted, exit 1 |
| `LOGFILE=/root/sim-day-2.log` (the real day 2 log) | `FAIL`, showing the freeze error | `FAIL`: task did not end OK; `ERROR: unable to freeze guest fs - timeout when try to receive Frozen event from VSS provider: Windows error 0x80004005`, exit 1 |

## What this does not prove yet

That the 15:00 job and the 15:10 check fire on their own, that the prune, garbage collection and verify jobs complete when scheduled, and that garbage collection returns the freed space. Those are recorded in the next entry, after the first scheduled run.
