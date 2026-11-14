# Nested speed test, run 3: plain CPU loop, SHA flag, KVM file descriptors, boot time (passes)

- Date: 2026-11-13 about 17:34 (America/Chicago, UTC-06:00)
- Host chain and guest: as in [run 1](2026-11-13T1713-nested-speed-test-v1.md); follows [run 2](2026-11-13T1725-nested-speed-test-v2.md)
- Sources: [host screenshot](2026-11-13T1734-speed-test-v3-host.png), [guest screenshot](2026-11-13T1734-speed-test-v3-guest.png)
- Decision rule set before this run: scalar loop within about 2x of the Proxmox host passes; otherwise fall back to the USB route.

## Commands and output (transcribed)

Proxmox host:

```
# grep -c -w sha_ni /proc/cpuinfo
4
# time taskset -c 0 busybox sh -c 'i=0; while [ $i -lt 3000000 ]; do i=$((i+1)); done'
real 0m2.096s   user 0m2.096s   sys 0m0.001s
# ls -l /proc/$(cat /run/qemu-server/100.pid)/fd | grep -c kvm
4
```


Guest (Alpine live):

```
# grep -c -w sha_ni /proc/cpuinfo
1
# time busybox sh -c 'i=0; while [ $i -lt 3000000 ]; do i=$((i+1)); done'
real 0m3.21s   user 0m3.18s   sys 0m0.00s
```

Guest boot: the user timed `qm reset 100` to the login prompt by stopwatch at about 6.5 to 6.7 seconds (approximate, hand-timed).

## Results against the bar

| Check | Bar | Measured | Result |
|---|---|---|---|
| Plain CPU loop, guest vs Proxmox host (same BusyBox shell, one core each) | within about 2x | 3.21 / 2.096 = 1.53x | pass |
| Guest boot after reset to login prompt | about 90 s or less | about 6.5 to 6.7 s (stopwatch) | pass |
| QEMU process holds KVM file descriptors | present | 4 matching descriptors | pass |
| Guest reports real CPU | real model | AMD Ryzen 9 8945HX ([run 2](2026-11-13T1725-nested-speed-test-v2.md)) | pass |

## What is still unexplained

The SHA-256 hashing workload in [run 2](2026-11-13T1725-nested-speed-test-v2.md) ran 4.93x slower in the guest (6.50 s vs 1.319 s). The guest does expose `sha_ni` (1 of 1 vCPU), so the earlier hypothesis that the instruction was hidden from the guest is wrong. The most likely remaining explanation is that the two BusyBox builds (Debian on the host, Alpine in the guest) differ in whether they use the SHA instructions. This was not verified. Kernel-side time was comparable (0.39 s host vs 0.31 s guest) and the plain loop is 1.53x, so the gap does not look like general virtualisation overhead. It will be revisited if backup hashing throughput turns out to be a bottleneck in Phase 2.

## Conclusion

Nested virtualisation works on this host and the guest is KVM-accelerated. [Decision 0004](../../decisions/0004-hyperv-as-nested-lab-hypervisor.md) is accepted. Timings elsewhere in the project carry the nested overhead (about 1.5x on plain CPU work in this test) and the repo says so.
