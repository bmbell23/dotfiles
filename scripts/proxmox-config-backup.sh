#!/bin/bash
# Proxmox configuration backup
# Backs up everything needed to rebuild this server from scratch on new hardware:
#   - /etc/pve/        (all Proxmox config: VMs, storage, network, users, backup jobs)
#   - /etc/network/    (network interfaces)
#   - /etc/fstab       (drive mount points)
#   - /etc/hostname, /etc/hosts
#   - /etc/udev/rules.d/ (automount rules)
#   - /home/brandon/   (scripts, dotfiles)
# To: /mnt/boston/proxmox-config-backups/
# Retains last 30 daily backups
# Runs as brandon (brandon is in www-data group for /etc/pve read access)

set -euo pipefail

DEST="/mnt/boston/proxmox-config-backups"
KEEP=30
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
ARCHIVE="$DEST/proxmox-config-$TIMESTAMP.tar.gz"
LOG="$DEST/proxmox-config-$TIMESTAMP.log"

log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOG"
}

if ! mountpoint -q /mnt/boston; then
    echo "ERROR: /mnt/boston not mounted, aborting config backup" >&2
    exit 1
fi

mkdir -p "$DEST"
log "Starting Proxmox config backup → $ARCHIVE"

tar -czf "$ARCHIVE" \
    /etc/pve \
    /etc/network/interfaces \
    /etc/fstab \
    /etc/hostname \
    /etc/hosts \
    /etc/udev/rules.d \
    /home/brandon \
    2>> "$LOG" || {
    TAR_EXIT=$?
    if [ $TAR_EXIT -eq 1 ]; then
        log "WARNING: tar completed with warnings (files changed during backup - archive is usable)"
    else
        log "ERROR: tar failed with exit code $TAR_EXIT"
        exit 1
    fi
}

SIZE=$(du -sh "$ARCHIVE" | cut -f1)
log "Archive created: $ARCHIVE ($SIZE)"

# Prune old backups, keep last $KEEP
COUNT=$(ls -1 "$DEST"/proxmox-config-*.tar.gz 2>/dev/null | wc -l)
if [ "$COUNT" -gt "$KEEP" ]; then
    REMOVE=$((COUNT - KEEP))
    log "Pruning $REMOVE old backup(s) (keeping last $KEEP)"
    ls -1t "$DEST"/proxmox-config-*.tar.gz | tail -n "$REMOVE" | while read -r f; do
        rm -f "$f" "${f%.tar.gz}.log"
        log "  Removed: $(basename "$f")"
    done
fi

log "Done. Backups on disk: $(ls -1 "$DEST"/proxmox-config-*.tar.gz 2>/dev/null | wc -l)"
