# Physical disk listing

- Date: 2026-11-13 15:41 (America/Chicago, UTC-06:00)
- Host: the workstation that will host the nested lab
- Shell: Windows PowerShell
- Source: screenshot pasted by the user, transcribed below

## Command

```powershell
Get-PhysicalDisk | Format-Table FriendlyName,MediaType,Size
```

## Output

```
FriendlyName               MediaType          Size
------------               ---------          ----
SAMSUNG MZAL81T0HFLB-00BL2 SSD       1024209543168
```

## Expected vs actual

Expected: two physical disks, so that the PBS datastore could sit on a separate failure domain from the VMs.

Actual: one physical SSD of 1,024,209,543,168 bytes (about 954 GiB). The Windows drive letters C: and D: are therefore partitions of the same disk on this machine.

## Consequence

With one physical disk and no wish to wipe it, the lab runs nested in a VM instead of on bare metal: [decision 0003](../../decisions/0003-nested-virtualised-lab.md).
