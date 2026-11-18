#!/usr/bin/env bash
# Check the latest vzdump task: all four VMs finished, task ended OK, no freeze errors or warnings.
# Appends one line to /var/log/rp-backup-check.log and to syslog; exits 1 on failure.
# WINDOW = how many minutes back a backup must have run. LOGFILE = check this file instead.
# Install on the Proxmox host: copy to /usr/local/bin/rp-backup-check.sh, chmod +x, then
#   echo '10 15 * * * root /usr/local/bin/rp-backup-check.sh' > /etc/cron.d/rp-backup-check
# (10 minutes after the 15:00 backup job; the host time zone is America/Chicago.)
set -uo pipefail
LOG=/var/log/rp-backup-check.log
WINDOW=${WINDOW:-30}
f=${LOGFILE:-$(find /var/log/pve/tasks -name '*vzdump*' -mmin -"$WINDOW" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)}
status=OK; why=""
if [ -z "$f" ]; then
  status=FAIL; why=" no backup task in the last $WINDOW minutes"
else
  n=$(grep -c "Finished Backup of VM" "$f")
  [ "$n" -eq 4 ] || { status=FAIL; why="$why only $n of 4 VMs finished;"; }
  grep -q "^TASK OK" "$f" || { status=FAIL; why="$why task did not end OK;"; }
  if grep -qiE "unable to freeze|ERROR|WARN" "$f"; then
    status=FAIL; why="$why $(grep -iE 'unable to freeze|ERROR|WARN' "$f" | head -1);"
  fi
fi
msg="$(date '+%F %T') backup-check $status$why"
echo "$msg" >> "$LOG"
if [ "$status" = OK ]; then logger -t rp-backup-check -p user.info "$msg"; else logger -t rp-backup-check -p user.err "$msg"; fi
[ "$status" = OK ]
