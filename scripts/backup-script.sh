#!/bin/bash

# Backup script for ProxMox
# Backs up:
#   1. /mnt/docker/ from DockerHost (192.168.0.158)
#   2. /mnt/boston/documents/ from ProxMox (local)
# To: /mnt/backups/ (sdc1 - 1TB SSD)

set -e  # Exit on error

# Configuration
BACKUP_ROOT="/mnt/backups"
DOCKERHOST_USER="brandon"
DOCKERHOST_IP="192.168.0.158"
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
if ! mountpoint -q "$BACKUP_ROOT"; then
    log "ERROR: Backup drive not mounted at $BACKUP_ROOT"
    exit 1
fi

# Create backup directories if they don't exist
mkdir -p "$BACKUP_ROOT/dockerhost-docker"
mkdir -p "$BACKUP_ROOT/documents"

# Backup 1: /mnt/docker from DockerHost (via SSH with sudo)
log ""
log "--- Backup 1/2: DockerHost /mnt/docker ---"
if run_rsync \
    "--rsync-path='sudo rsync' ${DOCKERHOST_USER}@${DOCKERHOST_IP}:/mnt/docker/" \
    "$BACKUP_ROOT/dockerhost-docker/" \
    "DockerHost /mnt/docker"; then
    BACKUP1_SUCCESS=true
else
    BACKUP1_SUCCESS=false
fi

# Backup 2: /mnt/boston/documents (local)
log ""
log "--- Backup 2/2: ProxMox /mnt/boston/documents ---"
if run_rsync \
    "/mnt/boston/documents/" \
    "$BACKUP_ROOT/documents/" \
    "ProxMox /mnt/boston/documents"; then
    BACKUP2_SUCCESS=true
else
    BACKUP2_SUCCESS=false
fi

# Summary
log ""
log "========================================="
log "Backup Summary"
log "========================================="
log "DockerHost /mnt/docker:        $([ "$BACKUP1_SUCCESS" = true ] && echo "✓ SUCCESS" || echo "✗ FAILED")"
log "ProxMox /mnt/boston/documents: $([ "$BACKUP2_SUCCESS" = true ] && echo "✓ SUCCESS" || echo "✗ FAILED")"
log "========================================="

# Check disk usage
log ""
log "Backup drive usage:"
df -h "$BACKUP_ROOT" | tee -a "$LOGFILE"

log ""
log "Backup completed at $(date)"
log "Full log: $LOGFILE"

# Exit with error if any backup failed
if [ "$BACKUP1_SUCCESS" = false ] || [ "$BACKUP2_SUCCESS" = false ]; then
    exit 1
fi

exit 0

