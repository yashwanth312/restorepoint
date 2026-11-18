#!/usr/bin/env bash
# Simulate N days of change on the four lab VMs, backing all of them up after each day.
# Usage: simulate-days.sh <number-of-days>   (run on the Proxmox host)
# Linux VMs are reached over SSH with the lab key; the domain controller is reached
# through the QEMU guest agent (qm guest exec). The change rate is an invented
# assumption: per day about 100 MB of random files on the file server, 10 MB of
# assets on the web server, 50,000 database rows and 5 disabled directory users.
set -euo pipefail
N=${1:?number of days}
SSH="ssh -i /root/.ssh/rp_lab -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
for vm in 101 102 103 104; do
  [ "$(qm status $vm | awk '{print $2}')" = running ] || { echo "VM $vm is not running"; exit 1; }
done
for D in $(seq 1 "$N"); do
  echo "=== day $D: changing data"
  $SSH rp@10.77.0.12 "sudo mkdir -p /srv/share/media/day$D && for i in 1 2 3 4 5; do sudo dd if=/dev/urandom of=/srv/share/media/day$D/new-\$i.bin bs=1M count=20 status=none; done; sync"
  $SSH rp@10.77.0.13 'sudo -u postgres psql -q -d rp_app' <<'SQL'
INSERT INTO orders (customer, note) SELECT (random()*10000)::int, md5(g::text)||md5((g*7)::text) FROM generate_series(1,50000) g;
SQL
  $SSH rp@10.77.0.14 "for i in 1 2; do sudo dd if=/dev/urandom of=/var/www/html/assets/day$D-\$i.bin bs=1M count=5 status=none; done; sync"
  PS='1..5 | ForEach-Object { $n = "day'"$D"'user" + $_; New-ADUser -Name $n -SamAccountName $n -Path "OU=rp-staff,DC=rp,DC=test" -Enabled $false }'
  ENC=$(printf '%s' "$PS" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)
  out=$(qm guest exec 101 --timeout 120 -- powershell -NoProfile -EncodedCommand "$ENC"); echo "$out" | grep -q '"exitcode" : 0' && ! echo "$out" | grep -q 'S=[^A-Za-z]*Error' || { echo "DC step failed: $out"; exit 1; }
  echo "=== day $D: backing up"
  vzdump 101 102 103 104 --storage rp-pbs --mode snapshot 2>&1 | tee /root/sim-day-$D.log | grep -E "Finished Backup|reused|sparse|ERROR|Backup job"
  pvesm status | grep rp-pbs
done
echo "=== finished"
