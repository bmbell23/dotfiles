#\!/bin/bash

# Backup script for External Drive
# Backs up large media files to /mnt/external/ (2TB external HDD)
# This runs separately because the external drive may not always be connected

set -e  # Exit on error

# Configuration
BACKUP_ROOT="/mnt/external"
LOG_DIR="/var/log/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log file for this run
LOGFILE="$LOG_DIR/backup-external-$TIMESTAMP.log"

# Function to log messages
log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOGFILE"
}

# Function to run rsync with common options
run_rsync() {
    local source="$1"
    local dest="$2"
    local description="$3"
    
    log "Starting backup: $description"
    log "  Source: $source"
    log "  Destination: $dest"
    
    if rsync -avh --delete --stats "$source" "$dest" >> "$LOGFILE" 2>&1; then
        log "✓ Successfully backed up: $description"
        return 0
    else
        log "✗ FAILED to backup: $description"
        return 1
    fi
}

# Start backup process
log "========================================="
log "External Drive Backup started"
log "========================================="

# Check if external drive is mounted
if \! mountpoint -q "$BACKUP_ROOT"; then
    log "WARNING: External drive not mounted at $BACKUP_ROOT"
    log "Skipping external backup (this is normal if drive is unplugged)"
    exit 0  # Exit successfully - this is not an error
fi

# Create backup directories if they don't exist
mkdir -p "$BACKUP_ROOT/media/pictures"
mkdir -p "$BACKUP_ROOT/media/videos"

# Track success/failure
BACKUP_RESULTS=()

# Backup 1: /mnt/boston/media/pictures (local)
log ""
log "--- Backup 1/2: ProxMox /mnt/boston/media/pictures ---"
if run_rsync \
    "/mnt/boston/media/pictures/" \
    "$BACKUP_ROOT/media/pictures/" \
    "ProxMox /mnt/boston/media/pictures"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/pictures: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/pictures: ✗ FAILED")
fi

# Backup 2: /mnt/boston/media/videos (local)
log ""
log "--- Backup 2/2: ProxMox /mnt/boston/media/videos ---"
if run_rsync \
    "/mnt/boston/media/videos/" \
    "$BACKUP_ROOT/media/videos/" \
    "ProxMox /mnt/boston/media/videos"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/videos: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/videos: ✗ FAILED")
fi

# Summary
log ""
log "========================================="
log "External Backup Summary"
log "========================================="
for result in "${BACKUP_RESULTS[@]}"; do
    log "$result"
done
log "========================================="

# Check disk usage
log ""
log "External drive usage:"
df -h "$BACKUP_ROOT" | tee -a "$LOGFILE"

log ""
log "External backup completed at $(date)"
log "Full log: $LOGFILE"

# Exit with error if any backup failed
if echo "${BACKUP_RESULTS[@]}" | grep -q "FAILED"; then
    exit 1
fi

exit 0
