#!/usr/bin/env bash
# Seed the PostgreSQL VM (rp-pg): install PostgreSQL and create a database with a
# one-million-row table. Run as root inside the VM. Safe to run again.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq postgresql >/dev/null
systemctl enable --now postgresql >/dev/null 2>&1

sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='rp_app'" | grep -q 1 \
  || sudo -u postgres createdb rp_app

sudo -u postgres psql -d rp_app -v ON_ERROR_STOP=1 -q <<'SQL'
CREATE TABLE IF NOT EXISTS orders (
  id        bigserial PRIMARY KEY,
  customer  int NOT NULL,
  placed_at timestamptz NOT NULL DEFAULT now(),
  note      text
);
INSERT INTO orders (customer, note)
SELECT (random() * 10000)::int, md5(g::text) || md5((g * 7)::text)
FROM generate_series(1, 1000000) g
WHERE NOT EXISTS (SELECT 1 FROM orders);
SQL

echo "== PostgreSQL baseline"
sudo -u postgres psql -tA -c "SHOW server_version"
sudo -u postgres psql -tA -c "SHOW data_directory"
sudo -u postgres psql -d rp_app -tA -c "SELECT 'rows: ' || count(*) FROM orders"
sudo -u postgres psql -d rp_app -tA -c "SELECT 'database size: ' || pg_size_pretty(pg_database_size('rp_app')) || ' (' || pg_database_size('rp_app') || ' bytes)'"
