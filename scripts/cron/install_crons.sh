#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRONTAB_FILE="${SCRIPT_DIR}/../../cron/crontab.txt"
TEMP_CRONTAB="/tmp/temp_crontab_$$"

# Function to check if a cron job exists with exact schedule
check_cron() {
    local schedule="$1"
    local command="$2"
    local existing_schedule
    
    # Get the existing schedule for this command, if any
    existing_schedule=$(crontab -l 2>/dev/null | grep -F "$command" | awk '{$6=$7=""; print $1" "$2" "$3" "$4" "$5}' | xargs)
    
    if [ -z "$existing_schedule" ]; then
        return 1  # Command not found
    elif [ "$existing_schedule" != "$schedule" ]; then
        return 2  # Command found but schedule differs
    else
        return 0  # Exact match
    fi
}

# Function to remove existing cron job
remove_cron() {
    local command="$1"
    crontab -l 2>/dev/null | grep -v -F "$command" > "$TEMP_CRONTAB"
    crontab "$TEMP_CRONTAB"
    rm -f "$TEMP_CRONTAB"
}

# Function to install a single cron job
install_cron() {
    local schedule="$1"
    local command="$2"
    local description="$3"
    
    check_cron "$schedule" "$command"
    local status=$?
    
    if [ $status -eq 1 ]; then
        # Cron doesn't exist, add it
        (crontab -l 2>/dev/null; echo "$schedule $command # $description") | crontab -
        echo "Installed cron: $description"
    elif [ $status -eq 2 ]; then
        # Cron exists but schedule differs, update it
        remove_cron "$command"
        (crontab -l 2>/dev/null; echo "$schedule $command # $description") | crontab -
        echo "Updated schedule for cron: $description"
    else
        echo "Cron already exists with correct schedule: $description"
    fi
}

# Function to check all cron jobs
check_crons() {
    local missing=0
    local needs_update=0
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        
        # Parse the cron entry
        local schedule=$(echo "$line" | awk '{$NF=""; print $1" "$2" "$3" "$4" "$5}')
        local command=$(echo "$line" | awk -F'#' '{print $1}' | awk '{for(i=6;i<=NF;i++) printf "%s ", $i}' | sed 's/ *$//')
        local description=$(echo "$line" | awk -F'#' '{print $2}' | xargs)
        
        check_cron "$schedule" "$command"
        local status=$?
        
        if [ $status -eq 1 ]; then
            echo "Missing cron: $description"
            missing=$((missing + 1))
        elif [ $status -eq 2 ]; then
            echo "Schedule mismatch for cron: $description"
            needs_update=$((needs_update + 1))
        fi
    done < "$CRONTAB_FILE"
    
    if [ $missing -eq 0 ] && [ $needs_update -eq 0 ]; then
        echo "All cron jobs are installed and up to date!"
        return 0
    else
        echo "Found $missing missing and $needs_update outdated cron job(s)"
        return 1
    fi
}

# Function to install all cron jobs
install_crons() {
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        
        # Parse the cron entry
        local schedule=$(echo "$line" | awk '{$NF=""; print $1" "$2" "$3" "$4" "$5}')
        local command=$(echo "$line" | awk -F'#' '{print $1}' | awk '{for(i=6;i<=NF;i++) printf "%s ", $i}' | sed 's/ *$//')
        local description=$(echo "$line" | awk -F'#' '{print $2}' | xargs)
        
        install_cron "$schedule" "$command" "$description"
    done < "$CRONTAB_FILE"
}

# Main script
case "$1" in
    "check")
        check_crons
        ;;
    "install")
        install_crons
        ;;
    *)
        echo "Usage: $0 {check|install}"
        exit 1
        ;;
esac