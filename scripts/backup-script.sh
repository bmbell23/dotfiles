#\!/bin/bash

# Backup script for ProxMox
# Backs up:
#   1. /mnt/boston/documents/ from ProxMox (local)
#   2. /mnt/boston/media/audiobooks/ from ProxMox (local)
#   3. /mnt/boston/media/books/ from ProxMox (local)
#   4. /mnt/boston/media/games/ from ProxMox (local)
#   5. /mnt/boston/media/audiobookshelf/ from ProxMox (local)
#   6. /mnt/boston/media/music/ from ProxMox (local)
#   7. /mnt/boston/media/other/ from ProxMox (local)
# To: /mnt/backups/ (sdc1 - 1TB SSD)

set -e  # Exit on error

# Configuration
BACKUP_ROOT="/mnt/backups"
LOG_DIR="/var/log/backups"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log file for this run
LOGFILE="$LOG_DIR/backup-$TIMESTAMP.log"

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
log "Backup started"
log "========================================="

# Check if backup drive is mounted
if \! mountpoint -q "$BACKUP_ROOT"; then
    log "ERROR: Backup drive not mounted at $BACKUP_ROOT"
    exit 1
fi

# Create backup directories if they don't exist
mkdir -p "$BACKUP_ROOT/documents"
mkdir -p "$BACKUP_ROOT/media/audiobooks"
mkdir -p "$BACKUP_ROOT/media/books"
mkdir -p "$BACKUP_ROOT/media/games"
mkdir -p "$BACKUP_ROOT/media/audiobookshelf"
mkdir -p "$BACKUP_ROOT/media/music"
mkdir -p "$BACKUP_ROOT/media/other"

# Track success/failure
BACKUP_RESULTS=()

# Backup 1: /mnt/boston/documents (local)
log ""
log "--- Backup 1/7: ProxMox /mnt/boston/documents ---"
if run_rsync \
    "/mnt/boston/documents/" \
    "$BACKUP_ROOT/documents/" \
    "ProxMox /mnt/boston/documents"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/documents: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/documents: ✗ FAILED")
fi

# Backup 2: /mnt/boston/media/audiobooks (local)
log ""
log "--- Backup 2/7: ProxMox /mnt/boston/media/audiobooks ---"
if run_rsync \
    "/mnt/boston/media/audiobooks/" \
    "$BACKUP_ROOT/media/audiobooks/" \
    "ProxMox /mnt/boston/media/audiobooks"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/audiobooks: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/audiobooks: ✗ FAILED")
fi

# Backup 3: /mnt/boston/media/books (local)
log ""
log "--- Backup 3/7: ProxMox /mnt/boston/media/books ---"
if run_rsync \
    "/mnt/boston/media/books/" \
    "$BACKUP_ROOT/media/books/" \
    "ProxMox /mnt/boston/media/books"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/books: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/books: ✗ FAILED")
fi

# Backup 4: /mnt/boston/media/games (local)
log ""
log "--- Backup 4/7: ProxMox /mnt/boston/media/games ---"
if run_rsync \
    "/mnt/boston/media/games/" \
    "$BACKUP_ROOT/media/games/" \
    "ProxMox /mnt/boston/media/games"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/games: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/games: ✗ FAILED")
fi

# Backup 5: /mnt/boston/media/audiobookshelf (local)
log ""
log "--- Backup 5/7: ProxMox /mnt/boston/media/audiobookshelf ---"
if run_rsync \
    "/mnt/boston/media/audiobookshelf/" \
    "$BACKUP_ROOT/media/audiobookshelf/" \
    "ProxMox /mnt/boston/media/audiobookshelf"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/audiobookshelf: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/audiobookshelf: ✗ FAILED")
fi

# Backup 6: /mnt/boston/media/music (local)
log ""
log "--- Backup 6/7: ProxMox /mnt/boston/media/music ---"
if run_rsync \
    "/mnt/boston/media/music/" \
    "$BACKUP_ROOT/media/music/" \
    "ProxMox /mnt/boston/media/music"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/music: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/music: ✗ FAILED")
fi

# Backup 7: /mnt/boston/media/other (local)
log ""
log "--- Backup 7/7: ProxMox /mnt/boston/media/other ---"
if run_rsync \
    "/mnt/boston/media/other/" \
    "$BACKUP_ROOT/media/other/" \
    "ProxMox /mnt/boston/media/other"; then
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/other: ✓ SUCCESS")
else
    BACKUP_RESULTS+=("ProxMox /mnt/boston/media/other: ✗ FAILED")
fi

# Summary
log ""
log "========================================="
log "Backup Summary"
log "========================================="
for result in "${BACKUP_RESULTS[@]}"; do
    log "$result"
done
log "========================================="

# Check disk usage
log ""
log "Backup drive usage:"
df -h "$BACKUP_ROOT" | tee -a "$LOGFILE"

log ""
log "Backup completed at $(date)"
log "Full log: $LOGFILE"

# Exit with error if any backup failed
if echo "${BACKUP_RESULTS[@]}" | grep -q "FAILED"; then
    exit 1
fi

exit 0
