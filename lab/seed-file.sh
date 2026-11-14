#!/usr/bin/env bash
# Seed the file server VM (rp-file): format and mount the 20 GB data disk, export it over
# SMB and NFS (read-only, lab network), and create baseline test data.
# Run as root inside the VM. Safe to run again: each step checks before it acts.
set -euo pipefail

DISK=/dev/sdb
MNT=/srv/share
EXPECTED_BYTES=21474836480   # 20 GiB: refuse to touch a disk of any other size

[ "$(lsblk -bdno SIZE "$DISK")" -eq "$EXPECTED_BYTES" ] || { echo "$DISK is not the 20 GiB data disk, stopping"; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq samba nfs-kernel-server >/dev/null

# Format only if the disk has no filesystem or signature yet.
blkid "$DISK" >/dev/null 2>&1 || mkfs.ext4 -q -L rp-share -m 0 "$DISK"
mkdir -p "$MNT"
grep -q 'LABEL=rp-share' /etc/fstab || echo "LABEL=rp-share $MNT ext4 defaults,nofail 0 2" >> /etc/fstab
systemctl daemon-reload
mountpoint -q "$MNT" || mount "$MNT"

if [ ! -f "$MNT/.seeded" ]; then
  mkdir -p "$MNT"/docs "$MNT"/media "$MNT"/archive
  # 2,000 small text files: compress well.
  for i in $(seq 1 2000); do
    seq 1 $((200 + i % 300)) | sed "s/^/report $i line /" > "$MNT/docs/report_$i.txt"
  done
  # 20 files of 20 MB random data: unique and incompressible.
  for i in $(seq 1 20); do head -c 20M /dev/urandom > "$MNT/media/clip_$i.bin"; done
  # One 50 MB random file stored ten times: duplicate data for deduplication to find.
  head -c 50M /dev/urandom > "$MNT/archive/base.bin"
  for i in $(seq 1 9); do cp "$MNT/archive/base.bin" "$MNT/archive/copy_$i.bin"; done
  touch "$MNT/.seeded"
fi
chown -R rp:rp "$MNT"

# Lab-only exports: read-only, and NFS limited to the lab network.
grep -q '^\[share\]' /etc/samba/smb.conf || cat >> /etc/samba/smb.conf <<CONF

[share]
   path = $MNT
   read only = yes
   guest ok = yes
CONF
grep -q "^$MNT " /etc/exports || echo "$MNT 10.77.0.0/24(ro,sync,no_subtree_check)" >> /etc/exports
systemctl enable --now smbd nfs-server >/dev/null 2>&1
systemctl restart smbd
exportfs -ra

echo "== file server baseline"
echo "files:        $(find "$MNT" -type f ! -name .seeded | wc -l)"
echo "bytes:        $(du -sb "$MNT" | cut -f1)"
du -sh "$MNT"/docs "$MNT"/media "$MNT"/archive
df -h "$MNT" | tail -1
echo "services:     smbd $(systemctl is-active smbd), nfs-server $(systemctl is-active nfs-server)"
exportfs -v
