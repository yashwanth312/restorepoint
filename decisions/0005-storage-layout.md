# 0005: Three separate thin disks for VM storage, ZFS and the backup datastore

Date: 2026-11-13
Status: Accepted (2026-11-14), after the LVM-thin and ZFS pools were created healthy ([evidence](../evidence/phase-1-storage-and-vms/2026-11-14T0756-lvm-thin-and-zfs-pools.md)). The PBS datastore disk is still to be prepared.

## Context

The lab needs VM disks (LVM-thin), a ZFS pool for the file server data, and a datastore for Proxmox Backup Server. Everything sits on one physical SSD, so the layout cannot give real failure isolation, but it can keep the three workloads from sharing a filesystem or a volume group.

## Options

1. **One big virtual disk with partitions for everything.** Simple, but a full backup datastore would take the VM storage with it.
2. **Three thin virtual disks, one per role.** Each role has its own limit and can be wiped or resized alone.
3. **ZFS for everything.** One technology to learn, but LVM-thin is the Proxmox default for VMs and part of the goal is to use both.

## Decision

Option 2: `rp-lvm.vhdx` (80 GB) for LVM-thin VM storage, `rp-zfs.vhdx` (80 GB) for a ZFS pool, `rp-pbs.vhdx` (100 GB) for the PBS datastore. All dynamically sized, so the files on Windows start near 4 MB each.

## Why

A separate disk for the backup datastore means filling it cannot take down the VMs, and the capacity forecast in Phase 6 can read its growth directly. The trade-off is that all three disks share one SSD, so a failed drive loses everything, and the dynamic files can fill the Windows disk if the guests write more than expected. The Windows free-space check goes into the Phase 1 evidence.

## Update 2026-11-14

The ZFS storage entry in Proxmox points at the `rp-zfs/shares` dataset, not the pool root, so the 40 GB quota bounds every disk created there. The pool of a storage entry cannot be edited after creation; it was removed and re-added ([evidence](../evidence/phase-1-storage-and-vms/2026-11-14T0830-zfs-storage-repoint-and-debian-image.md)).
