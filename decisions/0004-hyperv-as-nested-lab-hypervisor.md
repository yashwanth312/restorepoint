# 0004: Hyper-V (enabled on Windows 11 Home) as the nested-lab hypervisor

Date: 2026-11-13
Status: Accepted (2026-11-13), after the Phase 0 nested test passed ([evidence](../evidence/phase-0-foundation/2026-11-13T1734-nested-speed-test-v3.md)).

## Context

[0003](0003-nested-virtualised-lab.md) puts Proxmox in a VM on the workstation. The workstation is Windows 11 Home on an AMD Ryzen 9 8945HX, and Windows' own hypervisor is already running with virtualisation-based security on ([preflight](../evidence/phase-0-foundation/2026-11-13T1602-host-preflight.md)). That rules out running a second hypervisor on top of the bare CPU.

## Options

1. **VirtualBox 7.2.** Nested AMD-V is not offered with Windows' hypervisor active. Reports on Ryzen laptops show the option still greyed out with Hyper-V features turned off. Dropped.
2. **VMware Workstation Pro.** Reports of nested AMD-V not working on a Hyper-V host with Ryzen. Dropped.
3. **Hyper-V, enabled on Home from the packages already in Windows.** Nested virtualisation on AMD is supported from Windows 11 and Server 2022, and others have run Proxmox VE and Proxmox Backup Server under Hyper-V on Ryzen.
4. **Upgrade to Windows 11 Pro.** Same as option 3 but supported. Costs money.
5. **Proxmox on an external USB SSD.** No nesting, full RAM for the lab, but the workstation is dedicated to the lab while it runs.
6. **LXC-only lab.** Works without KVM, but loses the Windows AD VM and VM-level restores.

## Decision

Option 3, validated by a time-boxed test. Fallbacks in order: option 5, then option 6.

## Why

It costs nothing, touches no disks, and is reversible with one DISM command. Windows already runs on Hyper-V's hypervisor because of virtualisation-based security, so this adds the management stack, not a new layer. The trade-off is that Microsoft does not support Hyper-V on Home, and AMD nested performance is not guaranteed, which is why the decision stayed Proposed until the test passed.

## Findings so far

- The Proxmox installer on a Generation 2 VM could not find its DVD ([evidence](../evidence/phase-0-foundation/2026-11-13T1639-gen2-installer-no-iso.md)), and on Generation 1 the graphical installer fails on the video device ([evidence](../evidence/phase-0-foundation/2026-11-13T1648-gen1-graphical-installer-fails.md)). The working combination is a Generation 1 VM with the text-mode installer.
- `/dev/kvm` exists and `svm` is visible on all vCPUs ([evidence](../evidence/phase-0-foundation/2026-11-13T1658-nested-kvm-check.md)). A guest inside Proxmox boots in about 6.5 to 6.7 s and ran a plain CPU loop 1.53x slower than the Proxmox layer, with KVM confirmed ([evidence](../evidence/phase-0-foundation/2026-11-13T1734-nested-speed-test-v3.md)). A hashing test ran 4.9x slower for a reason not yet isolated; it is noted in the evidence.

## Sources

- Hyper-V on Home via the package workaround: <https://assistouest.fr/en/enabling-hyper-v-on-windows-home-edition>
- AMD nested virtualisation in Hyper-V: <https://www.thomasmaurer.ch/2021/09/hyper-v-nested-virtualization-for-amd-processors/>
- Proxmox VE and PBS under Hyper-V on a Ryzen host: <https://forum.proxmox.com/goto/post?id=639825>
- VirtualBox nested option greyed out on Ryzen: <https://libreddit.winscloud.net/r/virtualbox/comments/1noteb1/nested_virtualization_with_amd_ryzen_cpu/nfuibkp/?context=3>
