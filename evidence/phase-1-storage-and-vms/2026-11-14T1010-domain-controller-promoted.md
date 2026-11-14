# Domain controller promoted: domain `rp.test`, server `RP-DC01`

- Date: 2026-11-14 09:59 to 10:10 (America/Chicago, UTC-06:00). The VM's own clock is on Pacific time, so its event times are two hours earlier than these.
- Sources: [first dcdiag run](2026-11-14T1005-dcdiag-first-run.png), [verification](2026-11-14T1010-dc-verification.png)

## Steps

1. `Rename-Computer -NewName RP-DC01 -Restart`, because renaming a domain controller after promotion is painful. (The rename is shown to have worked by the name `RP-DC01` in later output.)
2. `Install-WindowsFeature AD-Domain-Services -IncludeManagementTools`.
3. `Install-ADDSForest -DomainName rp.test -DomainNetbiosName RP -InstallDns -SafeModeAdministratorPassword $p -Force`, with `$p` read from a prompt. The recovery (DSRM) password was typed by the person running it and is not recorded anywhere.

## First health check, and what it showed

`Get-ADDomain | ft ...; Get-Service ... | ft ...; dcdiag /q` on one line: the formatted tables did not print (PowerShell queued the table output behind the plain `dcdiag` output), so the domain and services could not be read from it. `dcdiag /q` reported, from the server's event log shortly after the first boot:

- `OpenSSH SSH Server service terminated unexpectedly` once, at 08:02 VM time (during promotion).
- Two `account-identifier allocator was unable to assign a new identifier` errors (event 0x4102) at 08:03, with the message that the identifier pool may have been depleted.

These can appear in the first minutes after a fresh promotion, so they were not accepted as harmless until tested.

## Verification (each command on its own line)

| Check | Result |
|---|---|
| `Get-ADDomain` | Name `rp`, DomainMode `Windows2025Domain` |
| `Get-Service NTDS,DNS,sshd` | all three Running |
| `dcdiag /test:ridmanager /test:advertising /test:knowsofroleholders /test:services /q` | no output (quiet mode prints failures only) |
| Create, read and delete a disabled test user `rp-ridtest` | created with SID `S-1-5-21-...-1101` (a normal new ID), then removed |
| `Add-DnsServerForwarder -IPAddress 1.1.1.1` | warning that it is already a forwarder on `RP-DC01` (set automatically during promotion) |

The test account being created and given an ID shows the ID allocator works. The two early allocator errors and the `sshd` crash remain in the server's event log as history; they did not repeat. The `dcdiag` SystemLog test was not re-run, so this record does not claim it passes.
