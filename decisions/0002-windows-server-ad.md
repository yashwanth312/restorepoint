# 0002: Windows Server AD from an evaluation ISO

Date: 2026-11-13
Status: Accepted

## Context

The lab needs an AD/DNS workload. The host has 16 GB of RAM, shared with ZFS, the file server, PostgreSQL, the web VM and the backup server.

## Options

1. Windows Server with the AD DS role, installed from an evaluation ISO.
2. Samba AD on Linux.

## Decision

Option 1.

## Why

- The design names Windows Server AD/DNS, and it is the setup most small companies actually run.
- It lets the project demonstrate a Windows-specific restore hazard: a domain controller restored from an old backup and started on the production network can corrupt AD replication. This is the concrete reason restore drills run on an isolated network.
- Trade-off accepted: it needs noticeably more RAM than Samba AD and the evaluation licence is time-limited. RAM use will be measured in Phase 1 and the ZFS memory cap tuned if the host is tight.

## Consequences

- Phase 1 records measured RAM per VM before any further sizing claims.
- The drill must prove the restored DC works on an isolated network and never touches production.

## Update 2026-11-14

The evaluation ISO used is Windows Server 2025 from the Microsoft Evaluation Center: a 180-day evaluation, and it must be activated online within 10 days or it shuts itself down. The edition and installation option (Core or Desktop Experience) are chosen at install time. Microsoft lists 512 MB as the minimum RAM for Server Core and 2 GB for Desktop Experience; the real figure for a domain controller here will be measured, not assumed.
