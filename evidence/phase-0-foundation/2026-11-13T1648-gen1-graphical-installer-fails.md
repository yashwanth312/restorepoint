# Generation 1 VM: installer finds the ISO, graphical installer fails (failed run)

- Date: 2026-11-13 16:48 (America/Chicago, UTC-06:00)
- Host: Windows 11 Home, Hyper-V enabled
- VM: `rp-pve`, rebuilt as Generation 1, 4 GB static memory, 4 vCPU, nested extensions exposed, ISO on the virtual DVD (IDE)
- Source: two console screenshots: [ISO found](2026-11-13T1648-gen1-installer-iso-found.png), [X server failure](2026-11-13T1648-gen1-installer-gui-x-failed.png)

## What happened

- The earlier Generation 2 failure ([log](2026-11-13T1639-gen2-installer-no-iso.md)) is gone: the installer logged `testing device '/dev/sr0' for ISO` then `found Proxmox VE ISO`, switched root, and DHCP succeeded on the Hyper-V Default Switch (lease from the switch's gateway).
- The graphical installer then failed: `vesa: Refusing to run, Framebuffer or dri device present` and `Cannot run in framebuffer mode. Please specify busIDs for all framebuffer devices`, X server terminated. Kernel shown: 7.0.2-6-pve.

## Reading

The ISO and storage path are fine on Generation 1. Hyper-V's Generation 1 video device does not suit the installer's X server. Nesting and the lab are not affected.

## Next

Use the installer's text mode (Install Proxmox VE, Terminal UI).
