#!/bin/bash

# Backup script for External Drive
# Backs up large media files to /mnt/external/ (2TB external HDD)
# This runs separately because the external drive may not always be connected

set -euo pipefail

# Cron can run with a minimal PATH, so set a predictable one.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Set variables
BACKUP_ROOT="/mnt/external"
LOG_DIR="${BACKUP_LOG_DIR:-${HOME:-/tmp}/.local/state/backups}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOGFILE=""

# Create log directory
if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
    LOG_DIR="/tmp/backups-${USER:-$(id -u)}"
    mkdir -p "$LOG_DIR"
fi

# Create log file
LOGFILE="$LOG_DIR/backup-external-$TIMESTAMP.log"

# Acquire lock if flock is available to prevent concurrent runs of this script
if command -v flock >/dev/null 2>&1; then
    LOCK_FILE="/tmp/$(basename "$0").lock"
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ERROR: Another backup-external.sh run is already in progress."
        exit 1
    fi
fi

# Log function
log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOGFILE"
}

# Rsync function
run_rsync() {
    local source="$1"
    local dest="$2"
    local description="$3"

    log "Starting backup: $description"
    log "  Source: $source"
    log "  Destination: $dest"

    if [ ! -d "$source" ]; then
        log "FAILED: Source directory does not exist: $source"
        return 1
    fi

    local rsync_opts=(-avh --delete --stats)
    if [ "${BACKUP_DRY_RUN:-0}" = "1" ]; then
        rsync_opts+=(--dry-run)
    fi

    if rsync "${rsync_opts[@]}" "$source" "$dest" >> "$LOGFILE" 2>&1; then
        log "SUCCESS: Backed up: $description"
        return 0
    else
        log "FAILED: Backup failed: $description"
        return 1
    fi
}

log "========================================="
log "External Drive Backup started"
log "========================================="

# Check if dry run is enabled
if [ "${BACKUP_DRY_RUN:-0}" = "1" ]; then
    log "DRY RUN enabled (no files will be changed)"
fi

# Check if external drive is mounted
if ! mountpoint -q "$BACKUP_ROOT"; then
    log "WARNING: External drive not mounted at $BACKUP_ROOT"
    log "Skipping external backup (this is normal if drive is unplugged)"
    exit 0
fi

# Create backup directories
mkdir -p "$BACKUP_ROOT/media/pictures"
mkdir -p "$BACKUP_ROOT/media/videos"

# Run backups
BACKUP_RESULTS=()

# Backup pictures
log ""
log "--- Backup 1/2: /mnt/boston/media/pictures ---"
if run_rsync \
    "/mnt/boston/media/pictures/" \
    "$BACKUP_ROOT/media/pictures/" \
    "/mnt/boston/media/pictures"; then
    BACKUP_RESULTS+=("/mnt/boston/media/pictures: SUCCESS")
else
    BACKUP_RESULTS+=("/mnt/boston/media/pictures: FAILED")
fi

log ""
log "--- Backup 2/2: /mnt/boston/media/videos ---"
if run_rsync \
    "/mnt/boston/media/videos/" \
    "$BACKUP_ROOT/media/videos/" \
    "/mnt/boston/media/videos"; then
    BACKUP_RESULTS+=("/mnt/boston/media/videos: SUCCESS")
else
    BACKUP_RESULTS+=("/mnt/boston/media/videos: FAILED")
fi

log ""
log "========================================="
log "External Backup Summary"
log "========================================="
for result in "${BACKUP_RESULTS[@]}"; do
    log "$result"
done
log "========================================="

log ""
log "External drive usage:"
df -h "$BACKUP_ROOT" | tee -a "$LOGFILE"

log ""
log "External backup completed at $(date)"
log "Full log: $LOGFILE"

if printf '%s\n' "${BACKUP_RESULTS[@]}" | grep -q "FAILED"; then
    exit 1
fi

exit 0
