# 0006: Size the Proxmox VM's RAM from measured free memory

Date: 2026-11-13
Status: Accepted

## Context

The lab estimate is about 9 GB: Proxmox about 1.5 GB, AD about 2 GB, file server about 1 GB, PostgreSQL about 1 GB, web about 0.5 GB, PBS about 2 GB. The workstation has 15.3 GB. With heavy apps closed it still had only 6.8 to 6.9 GB free ([evidence](../evidence/phase-1-storage-and-vms/2026-11-13T1829-lab-network-disks-ram.md)). Static memory is required for nested virtualisation, so the VM holds its RAM for as long as it runs.

## Options

1. **Hold out for 9 GB.** Needs the host to give up RAM it does not have free. Windows would page heavily to the same SSD the lab uses.
2. **5 GB (free minus 1.5 GB margin).** Safest for Windows, but tight for the lab.
3. **6 GB.** Leaves about 0.8 GB truly free plus reclaimable cache.
4. **Move to the USB SSD option** from [0004](0004-hyperv-as-nested-lab-hypervisor.md). Rejected for now: the lab fits if trimmed.

## Decision

6 GB, with apps closed whenever the lab runs. If the host shows sustained paging, drop to 5 GB with the VM off.

## Why

The extra GB helps the lab more than it costs Windows, and the setting is reversible in a minute. The 1.5 GB host margin was a rule of thumb, not a measurement, so the host check is part of the evidence. The trade-off is that the lab must be trimmed to fit: Windows Server Core for AD, LXC containers for web and PBS where possible, and the ZFS cache (ARC) capped at about 512 MB. Memory use will be measured per VM rather than estimated.

## Update 2026-11-14

All four lab VMs run together inside the 6 GB Proxmox VM with 1645 MB available and flat swap, idle ([evidence](../evidence/phase-1-storage-and-vms/2026-11-14T1026-four-vms-running-together.md)). The domain controller stays at 2 GB (it uses about 1.3 GB). No trimming was needed at idle; Proxmox Backup Server in Phase 2 is the next test of the margin.
