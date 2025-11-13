#!/bin/bash

# Script to sync auto and sfaos repositories hourly
# This script pulls the latest changes from the remote repositories

LOG_FILE="/home/$USER/.cache/repo_sync.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Function to sync a repository
sync_repo() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    if [ ! -d "$repo_path" ]; then
        log_message "ERROR: Repository not found: $repo_path"
        return 1
    fi
    
    cd "$repo_path" || {
        log_message "ERROR: Could not change to directory: $repo_path"
        return 1
    }
    
    # Check if it's a git repository
    if [ ! -d ".git" ]; then
        log_message "ERROR: Not a git repository: $repo_path"
        return 1
    fi
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_message "SKIP: $repo_name has uncommitted changes, skipping pull"
        return 0
    fi
    
    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    # Pull latest changes
    if git pull --ff-only origin "$current_branch" >> "$LOG_FILE" 2>&1; then
        log_message "SUCCESS: Pulled latest changes for $repo_name (branch: $current_branch)"
    else
        log_message "ERROR: Failed to pull changes for $repo_name"
        return 1
    fi
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

log_message "Starting hourly repository sync"

# Sync auto repository
sync_repo "/home/$USER/projects/auto"

# Sync sfaos repository
sync_repo "/home/$USER/projects/sfaos"

log_message "Completed hourly repository sync"

