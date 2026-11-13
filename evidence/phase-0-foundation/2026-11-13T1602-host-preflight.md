# Host preflight

- Date: 2026-11-13 16:02 (America/Chicago, UTC-06:00)
- Host: the workstation that will host the nested lab
- Shell: Windows PowerShell
- Source: screenshot pasted by the user, transcribed below

## Commands and output

| Check | Command | Result |
|---|---|---|
| CPU | `(Get-CimInstance Win32_Processor).Name` | AMD Ryzen 9 8945HX with Radeon Graphics |
| Total RAM (GB) | `[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)` | 15.3 |
| Free RAM now (GB) | `[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)` | 4.8 |
| Hypervisor already running | `(Get-CimInstance Win32_ComputerSystem).HypervisorPresent` | True |
| Virtualisation-based security | `Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard \| Select VirtualizationBasedSecurityStatus` | 2 (running) |
| VirtualBox version | `VBoxManage.exe --version` | 7.2.18r175117 |
| Free space on C: (GB) | `[math]::Round((Get-PSDrive C).Free/1GB)` | 506 |

## Expected vs actual

Expected: no hypervisor already holding the CPU's virtualisation features, so VirtualBox could expose nested AMD-V to a Proxmox VM.

Actual: Windows' own hypervisor is running with virtualisation-based security active. VirtualBox cannot get direct access to the CPU's virtualisation features in that state, so nested virtualisation through VirtualBox is not expected to work without changing the Windows configuration.

## Resource note

Free RAM at the time of the check was 4.8 GB of 15.3 GB, with normal desktop applications open. The Proxmox VM can only be given what remains free once those applications are closed; the real figure is measured at the start of the build.

## Consequence

The hypervisor choice is revisited before the Proxmox VM is created.
