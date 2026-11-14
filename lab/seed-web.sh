#!/usr/bin/env bash
# Seed the web VM (rp-web): install nginx and add a small static site with some binary
# assets. Run as root inside the VM. Safe to run again.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx >/dev/null

ROOT=/var/www/html
mkdir -p "$ROOT/assets"
echo '<h1>RestorePoint lab web server</h1>' > "$ROOT/index.html"
if [ ! -f "$ROOT/.seeded" ]; then
  for i in $(seq 1 10); do head -c 5M /dev/urandom > "$ROOT/assets/img_$i.bin"; done
  touch "$ROOT/.seeded"
fi
systemctl enable --now nginx >/dev/null 2>&1

echo "== web baseline"
echo "files:        $(find "$ROOT" -type f ! -name .seeded | wc -l)"
echo "bytes:        $(du -sb "$ROOT" | cut -f1)"
echo "http check:   $(curl -fsS http://localhost/ | head -1)"
