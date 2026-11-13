# Evidence

Dated output behind every claim in the README. Passing and failing runs are both kept, because the history of fixing things is part of the record.

## Layout

```
evidence/
  phase-0-foundation/
  phase-1-storage-and-vms/
  ...
    2026-11-13T1530-short-description.txt
```

Folders are created as each phase starts.

## What each file contains

- Date and time (local, with offset), host name, and software versions.
- The exact commands that were run.
- The unedited output, apart from the scrubbing below.
- One line saying what was expected and whether the result matched.

## Scrubbing before commit

Public repo, so before anything is committed: remove or replace AWS account IDs, access keys, public IP addresses, domain names, passwords and encryption keys. Raw, unscrubbed output stays out of version control (see `.gitignore`).

## Claims rule

A number appears in the README only if a file in this folder records how it was measured. If the measured value misses the target, the measured value is what gets published.
