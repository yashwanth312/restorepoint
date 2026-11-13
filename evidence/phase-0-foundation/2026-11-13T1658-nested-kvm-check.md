# Nested virtualisation check: /dev/kvm inside Proxmox on Hyper-V

- Date: 2026-11-13 16:58 (America/Chicago, UTC-06:00)
- Host: Windows 11 Home on AMD Ryzen 9 8945HX, Hyper-V enabled ([evidence](2026-11-13T1631-enable-hyperv-on-home.md))
- VM: `rp-pve`, Generation 1, 4 GB static memory, 4 vCPU, `ExposeVirtualizationExtensions` on, installed with the Terminal UI installer
- Source: console screenshot, [saved here](2026-11-13T1658-nested-kvm-check.png)

## Commands and output (transcribed)

```
root@pve:~# ls -l /dev/kvm
crw-rw---- 1 root kvm 10, 232 Nov 13 12:57 /dev/kvm
root@pve:~# grep -c svm /proc/cpuinfo
4
root@pve:~# pveversion
pve-manager/9.2.2/b9984c6d90a4bd80 (running kernel: 7.0.2-6-pve)
```

## Expected vs actual

Expected: `/dev/kvm` present, `svm` flag on every vCPU, a current Proxmox VE release.

Actual: all three as expected. AMD-V is visible to Proxmox on 4 of 4 vCPUs.

## Notes

- This proves KVM is available inside the VM. It does not yet prove a guest inside Proxmox runs fast enough; that is the next measurement.
- The VM shell reports the `/dev/kvm` timestamp as 12:57 while the host clock read about 16:57. The Proxmox time zone is therefore not America/Chicago. To be fixed so lab timestamps match the evidence log.
- The shell prompt shows the hostname as `pve`, not the `rp-pve.lab.local` suggested in the installer step.
- The ISO's SHA256 has not been recorded yet.
