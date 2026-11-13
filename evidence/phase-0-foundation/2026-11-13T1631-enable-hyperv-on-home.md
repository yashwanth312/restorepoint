# Enable Hyper-V on Windows 11 Home

- Date: 2026-11-13 (America/Chicago, UTC-06:00); commands run between about 16:20 and 16:31, verification after reboot
- Host: the workstation that will host the nested lab, Windows 11 Home (edition stated by the user), image version 10.0.26200.9974, DISM 10.0.26100.9549
- Shell: elevated Windows PowerShell
- Why: VirtualBox cannot nest on this host (see [host preflight](2026-11-13T1602-host-preflight.md)); Hyper-V is the hypervisor chosen in [decision 0004](../../decisions/0004-hyperv-as-nested-lab-hypervisor.md). Windows 11 Home does not ship Hyper-V enabled, so the Hyper-V packages already present in the Windows image are added and then the feature is switched on.

## Commands

```powershell
Checkpoint-Computer -Description "pre-hyperv" -RestorePointType MODIFY_SETTINGS
Get-ChildItem "$env:SystemRoot\servicing\Packages\*Hyper-V*.mum" | ForEach-Object { dism /online /norestart /add-package:"$($_.FullName)" }
dism /online /enable-feature /featurename:Microsoft-Hyper-V -All /LimitAccess /ALL
```

Unedited DISM output: [2026-11-13T1631-enable-hyperv-dism-output.txt](2026-11-13T1631-enable-hyperv-dism-output.txt). It contains 58 package installs, each ending `The operation completed successfully.`, then `Enabling feature(s)` completing successfully with `Restart Windows to complete this operation.` The restart prompt was declined so the output could be saved, then the machine was restarted manually.

`Checkpoint-Computer` printed nothing. A restore point is therefore not confirmed; the undo command below is the safety net.

## Verification after reboot

```powershell
Get-Command Set-VMProcessor | Select-Object Name,Source
(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State
Get-Service vmms | Select-Object Name,Status
```

Transcribed from a screenshot:

| Check | Result |
|---|---|
| `Set-VMProcessor` cmdlet | found, source `Hyper-V` |
| Feature `Microsoft-Hyper-V-All` | `Enabled` |
| Service `vmms` | listed; the Status column is not visible in the screenshot, so *Running* is not yet confirmed |

## Expected vs actual

Expected: cmdlet present, feature enabled, `vmms` running.

Actual: cmdlet present and feature enabled as expected. `vmms` status still to be confirmed in the next step.

## Undo

```powershell
DISM /Online /Disable-Feature /FeatureName:Microsoft-Hyper-V-All
```

## What this does not prove

That nested virtualisation works and is fast enough on this CPU. That is the Phase 0 gate and is measured next.
