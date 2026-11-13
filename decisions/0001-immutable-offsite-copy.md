# 0001: Immutable offsite copy via vzdump and DB files

Date: 2026-11-13
Status: Accepted

## Context

The original design had Proxmox Backup Server (PBS) sync to an S3 bucket with Object Lock, so ransomware that reaches the network still cannot delete the offsite copy.

Checked before building (versions current at the time: Proxmox VE 9.2-1, PBS 4.2-1):

- PBS 4.2 supports S3-compatible object storage as a datastore backend officially ([PBS roadmap](https://pbs.proxmox.com/wiki/Roadmap)).
- A Proxmox staff member said in August 2025 that object locking is not part of the PBS S3 feature set. A July 2026 comment in the same thread asks whether it is planned, with no staff reply visible ([forum thread](https://forum.proxmox.com/threads/immutable-backups-on-s3-object-storage.169404/)).
- A community analysis, not official guidance, lists why locking a PBS datastore bucket is hazardous: prune and garbage collection create delete markers instead of deleting locked objects, PBS cannot see lock state, and older chunks can lose their lock while newer backups still reference them ([forum thread](https://forum.proxmox.com/threads/lets-talk-deduplication-and-immutability.182803/)).

None of this was confirmed against the official PBS documentation. It is treated as "no evidence of support", not as proven impossible.

## Options

1. Weekly full `vzdump` archives plus daily database dumps and WAL files, copied into an Object Lock bucket by a separate job.
2. PBS S3-backed datastore with no Object Lock and least-privilege IAM.
3. Chunk-level copy of the PBS datastore into a locked bucket.

## Decision

Option 1.

## Why

- It is the only option that is truly immutable and can be tested simply: try to delete a locked object and record that it fails.
- Option 2 keeps deduplication but is offsite only, not immutable, so the project's headline claim would be false.
- Option 3 is closest to the original design but is the most complex, and it runs into the lock-expiry hazard above.

Trade-off accepted: the offsite copy is not deduplicated, so it uses more storage and an offsite restore moves more data. The site-loss rebuild time is expected to be dominated by that transfer, and will be measured, not assumed.

## Consequences

- The README claims an immutable offsite copy made by a copy job, not a PBS-native feature.
- Object Lock will be set up in compliance mode. Retention is tested with a short period first, because compliance mode cannot be shortened once set.
- Revisit this decision if PBS gains native Object Lock support.
