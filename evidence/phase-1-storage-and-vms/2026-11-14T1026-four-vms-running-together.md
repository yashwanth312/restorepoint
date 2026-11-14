# All four lab VMs running together: RAM reading and guest agent

- Date: 2026-11-14 10:14 to 10:26 (America/Chicago, UTC-06:00)
- Host: Proxmox VE 9.2.26 VM `rp-pve` (5922 MB RAM)
- Sources: [agent not running](2026-11-14T1014-guest-agent-not-running.png), [four VMs and host memory](2026-11-14T1026-four-vms-running-ram.png), [domain controller memory](2026-11-14T1026-dc-ram-four-vms.png)

## Guest agent on the domain controller

`qm agent 101 ping` first answered `QEMU guest agent is not running`. The agent installer had been started earlier but no output was captured, and the agent needs a second driver, the VirtIO serial port driver, that Windows did not have. The fix, in PowerShell on the VM:

```powershell
$f=(Get-ChildItem D:\vioserial -Recurse -Filter vioser.inf | ? FullName -match '2k25.amd64' | select -First 1).FullName
pnputil /add-driver $f /install
Start-Process msiexec -ArgumentList "/i D:\guest-agent\qemu-ga-x86_64.msi /qn /norestart" -Wait
```

Afterwards `qm agent 101 ping` answered `agent ok`. The output of the fix commands was not captured. The agent lets Proxmox freeze the filesystem and use Windows' snapshot service during a backup, which Phase 2 needs for a consistent domain controller backup.

## Memory with all four VMs running (transcribed)

| Where | Total | Used | Free or available |
|---|---|---|---|
| Proxmox host | 5922 MB | 4276 MB | 240 MB free, 1645 MB available (page cache 1687 MB) |
| Proxmox host swap | 3911 MB | 584 MB | was 595 MB before the three Linux VMs started, so it did not grow |
| `rp-ad` (Windows, 2048 MB assigned) | 1980 MB | about 1334 MB | 646 MB free (577 MB before promotion) |
| `rp-file` (1024 MB assigned) | 967 MB | 210 MB | 757 MB available |
| `rp-pg` (1024 MB assigned) | 967 MB | 209 MB | 758 MB available |
| `rp-web` (512 MB assigned) | 464 MB | 86 MB | 377 MB available |

`qm list` shows 101, 102, 103 and 104 running, template 9000 stopped.

## Reading

- The four VMs fit at their current sizes in the 6 GB Proxmox VM: 1645 MB available and swap flat. This is an idle reading with no workload yet, and Proxmox Backup Server (Phase 2) is not included.
- The domain controller uses about 1.3 GB inside its 2 GB both before and after promotion, so it is not shrunk below 2 GB.
- The Windows host's own memory does not change with what runs inside the lab: the Hyper-V VM's memory is static and is reserved in full at start. The earlier host reading ([decision 0006](../../decisions/0006-proxmox-vm-ram-sizing.md)) therefore still applies.
- Headroom for Phase 2 is the open question: a Backup Server VM of 1 to 2 GB on top of 1645 MB available would leave little. Options then are a small backup VM, ballooning on the Linux VMs, or stopping one VM during backups.
