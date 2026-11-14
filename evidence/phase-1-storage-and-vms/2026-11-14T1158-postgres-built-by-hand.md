# PostgreSQL `rp-pg` built by hand: database, table, one million rows, baseline size

- Date: 2026-11-14 11:30 to 11:58 (America/Chicago, UTC-06:00)
- Host: Debian 13 VM `rp-pg` (10.77.0.13), PostgreSQL 17.12 (Debian 17.12-0+deb13u1), cluster `main`, data directory `/var/lib/postgresql/17/main`
- This was done step by step to learn it; [`lab/seed-pg.sh`](../../lab/seed-pg.sh) in the repository is the automated version of the same steps.
- Sources: [table definition](2026-11-14T1151-postgres-orders-table.png), [load and baseline](2026-11-14T1158-postgres-baseline.png)

## Database and table

`sudo -u postgres createdb rp_app`, then in `psql`:

```sql
CREATE TABLE orders (
  id        bigserial PRIMARY KEY,
  customer  int NOT NULL,
  placed_at timestamptz NOT NULL DEFAULT now(),
  note      text
);
```

`\d orders` shows four columns (`id` bigint with default `nextval('orders_id_seq')`, `customer` integer, `placed_at` timestamp with time zone default `now()`, `note` text) and one index, `orders_pkey` (btree on `id`).

## Load

```sql
INSERT INTO orders (customer, note)
SELECT (random() * 10000)::int, md5(g::text) || md5((g * 7)::text)
FROM generate_series(1, 1000000) AS g;
```

Result: `INSERT 0 1000000` in 5,338 ms (about 5.3 s), measured with `\timing on`.

## Baseline (healthy, before any backup or fault)

| Measure | Value |
|---|---|
| `SELECT count(*) FROM orders` | 1,000,000 rows (45 ms) |
| `pg_database_size('rp_app')` | **156,497,587 bytes** (149 MB) |
| `pg_table_size('orders')` | 120 MB |
| `pg_indexes_size('orders')` | 21 MB |

Method: the four queries above, run in `psql` on the VM, output in the second screenshot. The row count and these sizes are the reference for the restore checks in Phases 3 and 5.

## Prediction check

Predicted before the run: 5 to 30 s load, count 1,000,000, table 100 to 120 MB, index about 21 MB, database 140 to 160 MB. Measured: 5.3 s (bottom of the range), count exact, table at the top edge of the range, index exact, database inside the range.
