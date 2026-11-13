# Nested speed test, run 1: Proxmox host vs a guest inside it (inconclusive, test design flawed)

- Date: 2026-11-13 about 17:02 to 17:13 (America/Chicago, UTC-06:00)
- Host chain: Windows 11 Home (AMD Ryzen 9 8945HX) -> Hyper-V Generation 1 VM `rp-pve` (4 GB static, 4 vCPU) -> Proxmox VE 9.2.2 -> guest VM 100 (Alpine virt 3.24.4, 1 vCPU, 512 MB, `--cpu host`)
- Sources: [host screenshot](2026-11-13T1713-speed-test-v1-host.png), [guest screenshot](2026-11-13T1713-speed-test-v1-guest.png)
- Pre-set bar (stated before the run): guest reaches a login prompt in about 90 s or less, and the fixed workload takes no more than about 2x as long in the guest as on the Proxmox host.

## Commands and output (transcribed)

Proxmox host:

```
# timedatectl set-timezone America/Chicago ; date
Fri Nov 13 05:01:54 PM CST 2026
# free -m
        total  used  free  shared  buff/cache  available
Mem:     3913  1461  2135      31         570       2452
Swap:    3911     0  3911
# nproc
4
# time sh -c 'dd if=/dev/zero bs=1M count=2000 2>/dev/null | sha256sum'
274fbb979251bcaceab594dd89d5adfec310e8851e320b5b5f90fd5f18d76149  -
real 0m1.820s   user 0m0.889s   sys 0m1.379s
# pveperf
CPU BOGOMIPS:      19961.88
REGEX/SECOND:      7465511
HD SIZE:           25.34 GB (/dev/mapper/pve-root)
BUFFERED READS:    8846.66 MB/sec
AVERAGE SEEK TIME: 0.09 ms
FSYNCS/SECOND:     622.15
DNS EXT:           54.58 ms
DNS INT:           22.87 ms (mshome.net)
```

Guest (Alpine live, same command):

```
# time sh -c 'dd if=/dev/zero bs=1M count=2000 2>/dev/null | sha256sum'
274fbb979251bcaceab594dd89d5adfec310e8851e320b5b5f90fd5f18d76149  -
real 0m6.53s   user 0m6.19s   sys 0m0.29s
# cat /proc/uptime
250.20 241.90
```

## Result against the bar

Guest time / host time = 6.53 / 1.820 = 3.59x. By the bar as set, this run does **not** pass, and it is not recorded as a pass.

## Why this run cannot settle it

- The two sides did not run the same code. The host used GNU `sha256sum`; Alpine used BusyBox `sha256sum`. Software differences alone can account for a multiple.
- The host pipeline ran `dd` and `sha256sum` in parallel on separate cores (user + sys exceeds real time). The guest has one vCPU, so both shared it.
- The identical hash on both sides confirms the same data was processed, not that the same work was done.
- `/proc/uptime` (250 s) is how long the guest had been up when the command ran, not how long it took to boot. Boot time was not measured.

What the numbers do show: in the guest, almost all time was user-mode CPU (6.19 s user, 0.29 s sys, real about equal to user + sys), which looks like a vCPU running code directly, not slowed by I/O or emulation. That is consistent with working KVM, not proof of it.

## Measured and kept as baseline

- Proxmox idle memory with a 3913 MB VM: 1461 MB used, 2452 MB available (before any lab VMs, before ZFS).
- `pveperf` values above: baseline for the nested Proxmox layer (note `FSYNCS/SECOND` 622, relevant later to PostgreSQL WAL and PBS).
- Time zone fixed: `date` reports CST.

## Next

Re-run with identical code on both sides (same BusyBox applets, same single core), confirm the guest is KVM-accelerated from Proxmox's own command line, and time boot with a stopwatch.
