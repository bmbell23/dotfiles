# Drive and Backup Audit

Date: 2026-03-28
Host: proxmox
User: brandon

## Current Backup Policy

- Source root: `/mnt/boston`
- Internal backup target: `/mnt/backups`
  - Includes: `docker-backups`, `documents`, `media/audiobooks`, `media/books`, `media/games`, `media/audiobookshelf`, `media/music`, `media/other`
- External backup target: `/mnt/external`
  - Includes: `media/pictures`, `media/videos`

Cron schedule (user crontab):

- `0 * * * * /home/brandon/projects/dotfiles/scripts/backup-script.sh`
- `5 * * * * /home/brandon/projects/dotfiles/scripts/backup-external.sh`

## Drive Inventory (Confirmed)

### Mounted data drives

- `sda1` -> `/mnt/boston`
  - Size: 7.3T
  - FS: NTFS (label `Boston`)
  - Model: `WDC_WD8001FFWX-68J1UN0` (8TB WD drive)
  - Use: primary data source for backups
- `sdc1` -> `/mnt/backups`
  - Size: 931.5G
  - FS: NTFS (label `CLEAN_E`)
  - Model: `SanDisk_SDSSDH31000G` (1TB SSD)
  - Use: internal backup destination
- `sdf1` -> `/mnt/external`
  - Size: 1.8T
  - FS: NTFS (label `Blank`)
  - Model: `WDC_WD20NMVW-11EDZS7`
  - by-id: `usb-WD_Elements_25A1_...`
  - Use: external media backup destination
- `sdb2` -> `/mnt/ssd250`
  - Size: 223.6G
  - FS: ext4
  - Model: `KINGSTON_SA400S37240G`
  - Use: local VM/template/image storage

### Mounted OS/system drive

- `nvme0n1` (Samsung 970 EVO 250GB)
  - `/` on `pve-root` (LVM)
  - Proxmox root/system and VM volumes (`pve-data`, `pve-vm-*`)

### Present but not mounted

- `sdd1`
  - Size: 1.8T
  - FS: NTFS (label `Allston`)
  - Model: `WDC_WD20NMVW-11EDZS6`
  - by-id: `usb-WD_easystore_25FC_...`
  - Current mount state: not mounted
  - Existing mountpoint folder: `/mnt/allston`
  - Working assumption: offline/optional Proxmox backup archive drive

### Not currently detected as block devices

- `edison`: only mountpoint folder exists at `/mnt/edison`; no matching mounted filesystem or disk label currently visible.
- `charles`: only mountpoint folder exists at `/mnt/charles`; no matching mounted filesystem or disk label currently visible.

## Capacity Snapshot

- `/mnt/boston`: 7.3T total, 2.6T used, 4.8T free (36%)
- `/mnt/backups`: 932G total, 55G used, 877G free (6%)
- `/mnt/external`: 1.9T total, 365G used, 1.5T free (20%)
- `/mnt/ssd250`: 219G total, 101G used, 108G free (49%)

## Backup Freshness Snapshot (before fixing scripts)

Most recent file timestamps seen in destinations:

- `/mnt/backups/documents`: 2026-01-19
- `/mnt/backups/media/audiobooks`: 2026-01-15
- `/mnt/external/media/pictures`: 2026-01-15
- Several destination categories currently contain little/no content compared to source categories.

Interpretation: backups appeared stale before script fixes and may have stopped around Jan 2026.

## Script Changes Made

- `scripts/backup-script.sh`
  - Log directory moved from `/var/log/backups` to user-writable default: `${HOME}/.local/state/backups`
  - Added fallback log dir: `/tmp/backups-$USER`
  - Added `set -euo pipefail`
  - Added predictable PATH for cron
  - Added process lock via `flock`
  - Added `BACKUP_DRY_RUN=1` support
  - Added backup of `/mnt/boston/docker-backups` to `/mnt/backups/docker-backups`
- `scripts/backup-external.sh`
  - Same non-root log handling and shell hardening
  - Added process lock via `flock`
  - Added `BACKUP_DRY_RUN=1` support
- `cron/crontab.txt`
  - Updated to current hourly internal + external backup plan
  - Removed stale entries (`daily_backup.sh`, old user path)

## Validation Results

- Shell syntax checks passed for both scripts.
- Internal script dry-run completed successfully as `brandon`.
- External script dry-run started successfully as `brandon` and traversed source data (large run; execution confirmed, long due to dataset size).
- New logs are being written to:
  - `/home/brandon/.local/state/backups`

## Open Unknowns

- Physical location mapping (desk enclosure vs NAS bay) cannot be proven from software alone.
- `allston` intended workload should be confirmed manually.
- `edison` is currently not visible as an attached disk label/device.

## Recommended Next Operations

1. Run one full (non-dry-run) backup for each script manually during a known maintenance window and review the resulting log summaries.
2. Add a simple post-run health check alert (for example: notify when script exit code is non-zero).
3. Decide whether `allston` should be auto-mounted and included/excluded by policy.
4. Confirm whether `edison` exists physically, and if so, reconnect and label it.
