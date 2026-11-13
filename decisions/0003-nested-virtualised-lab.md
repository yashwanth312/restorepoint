# 0003: Run the lab nested in a VM on the workstation

Date: 2026-11-13
Status: Accepted

## Context

The only machine available has a single physical SSD of about 1 TB, with the Windows drives C: and D: as two partitions of it ([evidence](../evidence/phase-0-foundation/2026-11-13T1541-physical-disk-listing.md)). Installing Proxmox VE on bare metal would wipe that disk, including the workstation's own operating system.

## Options

1. Proxmox VE on bare metal on this machine. Wipes the disk.
2. Add a second physical disk and install bare metal.
3. Run Proxmox VE nested inside a VM on the workstation.

## Decision

Option 3.

## Why

It leaves the workstation untouched and costs nothing. The backup datastore gets its own virtual disk, and the S3 bucket is the independent copy.

Trade-off accepted: all virtual disks sit on the same physical SSD, and nested virtualisation adds overhead. The lab demonstrates the backup, restore and measurement method, so recorded timings are lab timings.

## Consequences

- Phase 0 first proves that nested virtualisation works on this workstation, and records the hypervisor and settings used.
- RAM for the Proxmox VM comes out of the workstation's RAM. The amount actually available is measured in Phase 0 and sizes the Phase 1 VMs.
