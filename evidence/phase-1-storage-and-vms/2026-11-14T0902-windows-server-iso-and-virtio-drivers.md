# Windows Server evaluation ISO uploaded and verified; VirtIO driver ISO downloaded

- Date: 2026-11-14 09:02 (America/Chicago, UTC-06:00)
- Sources: [hash on Windows](2026-11-14T0902-windows-iso-sha256.png), [Proxmox upload task](2026-11-14T0902-proxmox-upload-checksum-verified.png), [VirtIO download and ISO list](2026-11-14T0902-virtio-win-download-and-iso-list.png)

## Windows Server ISO

The file `Windows-AD-Server.iso` was downloaded from the Microsoft Evaluation Center (Windows Server 2025 evaluation, see [decision 0002](../../decisions/0002-windows-server-ad.md)) in `C:\lab` on the Windows host.

| Item | Value |
|---|---|
| SHA256 (PowerShell `Get-FileHash`) | `7B052573BA7894C9924E3E87BA732CCD354D18CB75A883EFA9B900EA125BFD51` |
| Size on Proxmox | 8,152,356,864 bytes (7.6 GiB) |
| Upload | Proxmox web UI, ISO Images, with the SHA-256 above entered in the upload form |
| Proxmox task log | `calculating checksum...OK, checksum verified`, `TASK OK` |
| Location | `/var/lib/vz/template/iso/Windows-AD-Server.iso` |

The checksum match proves the copy on Proxmox is identical to the file on the Windows host. It does not prove the file is the genuine Microsoft image: no Microsoft-published hash was checked. The file is 7.6 GiB, larger than the 5.6 GB a third-party page quoted, so the installer's edition list is the real check of what it contains.

## VirtIO driver ISO

`virtio-win.iso` (837 MB) was downloaded from `fedorapeople.org/groups/virt/virtio-win` stable direct-downloads in 18 seconds at about 46 MB/s. Windows Setup needs it to see a VirtIO disk, and the installed system needs it for the VirtIO network card. No checksum was compared for this file.

The ISO directory holds both files (8.5 GB in total) on the 25 GB `local` storage.
