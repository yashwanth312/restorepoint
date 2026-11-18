# 0010: One-week scope with a single restore drill

Date: 2026-11-18
Status: Accepted

## Context

RestorePoint is a personal project, not a production service, so its jobs should have an end date. The original design targeted four weeks of passing weekly restore drills and a schedule that keeps running afterwards. The lab only runs while the workstation is on, so the daily backup is set for 15:00 local time, when it is on.

## Options

1. Keep the four-week target and let the jobs run until it is met.
2. One-week build window, one restore drill, then stop the schedules.
3. Skip the schedules and only run everything by hand.

## Decision

Option 2.

- The daily backup job runs from 2026-11-18 through 2026-11-24 (up to 7 runs), then final measurements are taken on 2026-11-25.
- Phase 5 produces the automated restore drill and runs it once. Phase 6 runs the timed site-loss rebuild once.
- At the end, the daily backup, prune, garbage collection and verify jobs are disabled. The scripts and schedules stay in the repository so they can be switched on again.
- No new data is generated after the six-day simulation ([evidence](../evidence/phase-2-local-backups/2026-11-18T1044-six-day-simulation-and-dedup-factor.md)). Only the guests' own background changes are backed up.

## Why

It bounds the time spent, keeps every claim tied to a run that actually happened, and still exercises each mechanism once: schedule, retention, offsite copy, restore drill, runbook.

## Trade-offs accepted

- One drill shows the mechanism works once. It does not show it keeps working week after week, so the README reports one drill over about a week and makes no four-week pass-rate claim.
- A week cannot show the weekly and monthly retention tiers (4 weekly, 6 monthly). Those are checked with the prune simulator and reported as a simulation.
- The capacity forecast has one week of idle-lab growth to work from, plus the 198 MiB a day measured in the six-day simulation as a second scenario. Both are labelled with how they were obtained.
- With little new data, the dedup ratio rises as snapshots accumulate, so any figure is quoted with the snapshot count and the change rate behind it.

## Consequences

- The README results table reports drill results as one drill, not a pass rate.
- Numbers that cannot be measured inside the window are approximated and marked as approximations.
