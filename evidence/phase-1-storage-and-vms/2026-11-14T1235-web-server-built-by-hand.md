# Web server `rp-web` built by hand: nginx, static assets, baseline size

- Date: 2026-11-14 12:30 to 12:35 (America/Chicago, UTC-06:00); the `Date:` header in the screenshot is GMT, so it reads six hours ahead
- Host: Debian 13 VM `rp-web` (10.77.0.14), nginx from the Debian repository
- This was done step by step to learn it; [`lab/seed-web.sh`](../../lab/seed-web.sh) in the repository is the automated version of the same steps.
- Source: [commands and output](2026-11-14T1235-web-baseline.png)

## Install and default state

`sudo apt-get install -y nginx` installed and started the service. `systemctl is-active nginx` printed `active`, and `/var/www/html` held one file, `index.nginx-debian.html` (nginx's default welcome page).

## Content added

- `/var/www/html/assets/asset-01.bin` to `asset-10.bin`: ten files of 5 MB each from `dd if=/dev/urandom bs=1M count=5` (unique, incompressible data).
- `/var/www/html/index.html` containing `<h1>RestorePoint web VM</h1>`. nginx tries `index.html` before `index.nginx-debian.html`, so this page is what the server returns, and it is recognisable after a restore.

## Baseline (healthy, before any backup or fault)

| Check | Result |
|---|---|
| `curl -sI http://localhost` | `HTTP/1.1 200 OK`, `Server: nginx` |
| `curl -s http://localhost/` | `<h1>RestorePoint web VM</h1>` |
| `curl -s http://localhost/assets/asset-01.bin \| wc -c` | 5,242,880 bytes (nginx serves the full file) |
| `ls /var/www/html/assets` | ten files, `asset-01.bin` to `asset-10.bin` |
| `sudo du -sb /var/www/html` | **52,429,444 bytes** |

Method: the commands above, run on the VM. 52,429,444 is 52,428,800 (ten 5 MiB files) plus 644 bytes. The 644 matches the 29-byte new page plus a 615-byte default page; I did not read the default page's size directly.

## Prediction check

I predicted `du -sb` would print about 52,437,000, counting two 4,096-byte directory entries. It printed 52,429,444, about 7.6 KB lower, so `du -sb` evidently did not add those directory entries on this VM. I have not investigated why. It does not affect the baseline: the figure is a measurement, and the same command will be run after a restore. The other four predictions (200 OK, the page text, ten files, 5,242,880 bytes served) held.
