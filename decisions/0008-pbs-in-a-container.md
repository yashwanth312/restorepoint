# 0008: Run Proxmox Backup Server in an unprivileged container

Date: 2026-11-14
Status: Accepted

## Context

Backups need a PBS instance with its own disk. With all four lab VMs running, the Proxmox VM had about 1.6 GB of memory available ([decision 0006](0006-proxmox-vm-ram-sizing.md)). Proxmox describes PBS in a container, or on plain Debian, as possible but not its recommended setup.

## Options

1. **Container (LXC)** with the backup disk shared into it. Shares the host kernel, so it needs far less memory.
2. **Small VM.** Cleaner separation, but about 1.5 to 2 GB, which does not fit without stopping a VM.
3. **On the Proxmox host itself.** No extra memory, but one failure takes out the host and the backups together.

## Decision

Option 1: container 105, unprivileged, 1 GB limit, no swap, with the 100 GB backup disk bind-mounted. Retention will be enforced by prune jobs on PBS, and Proxmox gets a limited PBS account (`DatastoreBackup` role) instead of root.

## Why

Memory was the constraint, and the measured result supports the choice: the container used 29 MB idle and peaked at 49 MB while backing up all four VMs ([evidence](../evidence/phase-2-local-backups/2026-11-14T1431-first-backups-and-memory-readings.md)). The trade-offs accepted: the backup server shares a machine with what it protects, which is acceptable for a lab and is why the immutable offsite copy exists; the container needed a user-ID shift on the backup folder and nesting enabled; and it is a setup Proxmox does not recommend. If the container misbehaves, PBS moves to a VM using the same backup disk. Host swap use roughly doubled after PBS arrived, which is recorded and watched.
