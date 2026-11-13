# Nested speed test, run 2: same BusyBox command on both sides (fails the CPU bar as designed; cause not yet isolated)

- Date: 2026-11-13 about 17:25 (America/Chicago, UTC-06:00)
- Host chain and guest: as in [run 1](2026-11-13T1713-nested-speed-test-v1.md)
- Sources: [host screenshot](2026-11-13T1725-speed-test-v2-host.png), [guest screenshot](2026-11-13T1725-speed-test-v2-guest.png)
- Bar (unchanged): guest login prompt after reset in about 90 s or less; fixed workload no more than about 2x the Proxmox host time.

## Commands and output (transcribed)

Proxmox host, pinned to one core:

```
# time taskset -c 0 busybox sh -c 'busybox dd if=/dev/zero bs=1M count=2000 2>/dev/null | busybox sha256sum'
274fbb979251bcaceab594dd89d5adfec310e8851e320b5b5f90fd5f18d76149  -
real 0m1.319s   user 0m0.923s   sys 0m0.390s
# qm showcmd 100 | grep -o -e '-enable-kvm' -e '-cpu [^ ]*'
-cpu host,+kvm_pv_eoi,+kvm_pv_unhalt
```

Guest (Alpine live):

```
# time busybox sh -c 'busybox dd if=/dev/zero bs=1M count=2000 2>/dev/null | busybox sha256sum'
274fbb979251bcaceab594dd89d5adfec310e8851e320b5b5f90fd5f18d76149  -
real 0m6.50s   user 0m6.14s   sys 0m0.31s
# grep -m1 'model name' /proc/cpuinfo
model name : AMD Ryzen 9 8945HX with Radeon Graphics
```

Guest boot: the user reported that `qm reset 100` took 6.5 seconds to reach the login prompt (stopwatch, no screenshot). This coincides with the 6.50 s benchmark figure; confirmation that it was timed separately was requested.

## Result against the bar

- CPU workload: 6.50 / 1.319 = 4.93x. Does **not** meet the 2x bar. Not recorded as a pass.
- Boot after reset: 6.5 s against a 90 s bar, if the stopwatch figure is confirmed.

## Reading

- Kernel-side time is comparable: `sys` 0.390 s on the host vs 0.31 s in the guest.
- The gap is in `user` time: 0.923 s vs 6.14 s. For 2000 MiB that is about 2.2 GB/s on the host vs about 0.33 GB/s in the guest, a gap far larger than normal hardware-assisted virtualisation overhead for plain CPU work. It is consistent with the host BusyBox using the CPU's SHA instructions while the guest BusyBox does not (different builds, or the instructions not exposed to the guest). Not yet checked.
- The guest reports the real CPU model, and `-cpu host` is only valid under KVM acceleration, so the guest is hardware-accelerated. `qm showcmd` did not print `-enable-kvm`; the `kvm_pv_*` flags are present. A direct check (QEMU process holding `/dev/kvm`) is still to be recorded.

## Next

Check the `sha_ni` flag on both sides, run a plain scalar loop in the same BusyBox shell on both, and confirm directly that the QEMU process holds `/dev/kvm`. Decision rule set before running: scalar loop within about 2x passes; otherwise fall back to the USB route.
