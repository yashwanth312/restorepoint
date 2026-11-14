# 0009: Restore test copies onto an isolated bridge with a live network card

Date: 2026-11-14
Status: Accepted

## Context

A restored domain controller must not reach the network while the original runs: it has the same identity and the same static address. The first restore test removed the copy's network card to guarantee that. The copy booted and its services reported running, but LDAP (ports 389, 636 and 3268) never started listening, so AD answered no queries ([evidence](../evidence/phase-2-local-backups/2026-11-14T1454-restore-tests.md)). Two earlier explanations were wrong before a control test on the original domain controller and a comparison of listening ports pointed at the missing card.

## Options

1. **No network card.** Safe from clashes, but AD does not serve queries.
2. **Normal lab bridge with a changed address.** The copy's address is a setting inside Windows, so it would still clash on first boot.
3. **Isolated bridge with a live card and no uplink.**
4. **Stop the original and restore onto the normal network.** Only works for a real disaster, not for a drill.

## Decision

Option 3: bridge `vmbr9` on the Proxmox host, created with this stanza in `/etc/network/interfaces` and applied with `ifreload -a`:

```
auto vmbr9
iface vmbr9 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
```

Restored test copies get `net0` on `vmbr9` before their first start.

## Why

With a card on `vmbr9`, the restored domain controller listened on all six AD ports and answered 268 objects 91 seconds after the restore began. Changing only the card fixed it, and the bridge cannot carry traffic to the lab, so the duplicate address does no harm. The trade-off: the host has no address on `vmbr9`, so restored machines can only be checked through the guest agent. The domain controller and Windows tooling answer that way; the Linux VMs have the agent disabled, so the Phase 5 drill either enables it on them or gives the host an address on `vmbr9`. That is decided in Phase 5.
