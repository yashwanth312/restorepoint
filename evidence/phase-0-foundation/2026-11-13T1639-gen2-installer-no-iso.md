# Proxmox VE installer on a Generation 2 Hyper-V VM: DVD not found (failed run)

- Date: 2026-11-13 16:39 (America/Chicago, UTC-06:00)
- Host: Windows 11 Home, Hyper-V enabled ([evidence](2026-11-13T1631-enable-hyperv-on-home.md))
- VM: `rp-pve`, Generation 2, 4 GB static memory, 4 vCPU, nested extensions exposed, Secure Boot off, ISO attached to the VM's virtual DVD drive (SCSI on Generation 2)
- ISO: `proxmox-ve_9.2-1.iso` (hash not yet recorded)
- Source: screenshot of the VM console, [saved here](2026-11-13T1639-gen2-installer-no-iso.png)

## What happened

The firmware booted the installer ("Welcome to the Proxmox VE 9.2 (ISO 1) installer!", EFI boot mode detected). The installer's early boot then searched for the block device holding the ISO, retried for 8 seconds, and stopped:

```
[ERROR] no device with valid ISO found, please check your installation medium
```

Driver list the installer loaded: `processor rtc_cmos battery ac hv_vmbus vmgenid efi_pstore pcspkr aesni_intel ghash_clmulni_intel kvm_amd intel_rapl_common amd_atl fmpm`. Two modprobe errors followed (`amd_atl`, `fmpm`: No such device).

## Reading

- `kvm_amd` loaded without an error. This is a good sign for nesting but not proof; `/dev/kvm` is checked after install.
- `amd_atl` and `fmpm` are AMD hardware error-reporting modules that have no device inside a VM. Harmless.
- `hv_vmbus` is loaded but `hv_storvsc` (the Hyper-V storage driver) is not in the list. A Generation 2 VM presents its DVD drive over that storage path, so the installer cannot see the ISO. Generation 1 presents the DVD on an emulated IDE controller, which needs no Hyper-V driver.

## Next

Recreate the VM as Generation 1.
