# Switched to the no-subscription repository, upgraded, rebooted

- Date: 2026-11-13 18:42 (America/Chicago, UTC-06:00)
- Host: Proxmox VE VM `rp-pve` (6 GB RAM, 8 vCPUs, lab network 10.77.0.0/24)
- Source: [console screenshot after reboot](2026-11-13T1842-after-upgrade-reboot.png)

## Commands

```bash
for f in pve-enterprise ceph; do grep -q '^Enabled:' /etc/apt/sources.list.d/$f.sources || sed -i '1i Enabled: false' /etc/apt/sources.list.d/$f.sources; done
cat > /etc/apt/sources.list.d/pve-no-subscription.sources <<'EOT'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOT
apt update && apt -y full-upgrade && pveversion && reboot
```

The two enterprise files are disabled, not deleted. Ceph is not used in this lab.

## Result after the reboot

| Item | Before | After |
|---|---|---|
| pve-manager | 9.2.2 | 9.2.26 |
| Kernel | 7.0.2-6-pve | 7.0.14-28-pve (2026-11-02) |
| `vmbr0` | 10.77.0.10/24, UP | 10.77.0.10/24, UP |
| Data disks | `sdb` 80 GB, `sdc` 80 GB, `sdd` 100 GB | same three, same sizes |

The fixed lab network and the three data disks came back unchanged after a reboot into the new kernel.

## Notes

- The upgrade's own output was not pasted, so the package list is not recorded. The end state above is what the VM reports.
- The Phase 0 benchmark numbers were measured on the older kernel (7.0.2-6). They stay as a Phase 0 record and are not re-run.
