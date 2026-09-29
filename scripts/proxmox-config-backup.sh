#!/bin/bash
# Proxmox configuration backup
# Backs up everything needed to rebuild this server from scratch on new hardware:
#   - /etc/pve/        (all Proxmox config: VMs, storage, network, users, backup jobs)
#   - /etc/network/    (network interfaces)
#   - /etc/fstab       (drive mount points)
#   - /etc/hostname, /etc/hosts
#   - /etc/udev/rules.d/ (automount rules)
#   - crontab -l       (the running user's crontab; scripts themselves live in the dotfiles repo)
# To: /mnt/boston/proxmox-config-backups/
# Retains last 30 daily backups (pruned on every run, even a failed one)
# Runs as brandon (brandon is in www-data group for /etc/pve read access).
# /etc/pve/priv is root-only, so it's skipped unless run as root.
# Exits non-zero on failure so a scheduler (Dagu) can alert.

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

TAR_EXCLUDES=()
if [ "$(id -u)" -ne 0 ]; then
    TAR_EXCLUDES+=(--exclude=/etc/pve/priv)
    log "Not root: skipping /etc/pve/priv (root-only: authkey, ssh keys, API tokens)"
fi

STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT
crontab -l > "$STAGING/crontab-$(id -un).txt" 2>/dev/null || log "WARNING: no crontab for $(id -un)"

FAILED=0
# Write to .partial and rename on success, so a failed run never leaves a half archive behind.
tar -czf "$ARCHIVE.partial" \
    "${TAR_EXCLUDES[@]}" \
    /etc/pve \
    /etc/network/interfaces \
    /etc/fstab \
    /etc/hostname \
    /etc/hosts \
    /etc/udev/rules.d \
    -C "$STAGING" . \
    2>> "$LOG" || {
    TAR_EXIT=$?
    if [ $TAR_EXIT -eq 1 ]; then
        log "WARNING: tar completed with warnings (files changed during backup - archive is usable)"
    else
        log "ERROR: tar failed with exit code $TAR_EXIT (see tar messages above in $LOG)"
        FAILED=1
    fi
}

if [ "$FAILED" -eq 0 ]; then
    mv "$ARCHIVE.partial" "$ARCHIVE"
    SIZE=$(du -sh "$ARCHIVE" | cut -f1)
    log "Archive created: $ARCHIVE ($SIZE)"
else
    rm -f "$ARCHIVE.partial"
fi

# Prune old backups, keep last $KEEP. Runs even when tar failed; it only ever
# removes the oldest archives, so the newest $KEEP are always kept.
COUNT=$(ls -1 "$DEST"/proxmox-config-*.tar.gz 2>/dev/null | wc -l)
if [ "$COUNT" -gt "$KEEP" ]; then
    REMOVE=$((COUNT - KEEP))
    log "Pruning $REMOVE old backup(s) (keeping last $KEEP)"
    ls -1t "$DEST"/proxmox-config-*.tar.gz | tail -n "$REMOVE" | while read -r f; do
        rm -f "$f" "${f%.tar.gz}.log"
        log "  Removed: $(basename "$f")"
    done
fi
# Logs of failed runs have no archive, so the loop above never removes them.
OLD_LOGS=$(find "$DEST" -maxdepth 1 -name 'proxmox-config-*.log' -mtime +"$KEEP" | wc -l)
if [ "$OLD_LOGS" -gt 0 ]; then
    find "$DEST" -maxdepth 1 -name 'proxmox-config-*.log' -mtime +"$KEEP" -delete
    log "Pruned $OLD_LOGS log(s) older than $KEEP days"
fi

log "Done. Backups on disk: $(ls -1 "$DEST"/proxmox-config-*.tar.gz 2>/dev/null | wc -l)"

if [ "$FAILED" -ne 0 ]; then
    log "FAILED: config backup did not produce an archive"
    exit 1
fi
