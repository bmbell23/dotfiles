#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRONTAB_FILE="${SCRIPT_DIR}/../../cron/crontab.txt"
TEMP_CRONTAB="/tmp/temp_crontab_$$"

# Function to check if a cron job exists
check_cron() {
    local schedule="$1"
    local command="$2"
    crontab -l 2>/dev/null | grep -F "$command" >/dev/null
}

# Function to install a single cron job
install_cron() {
    local schedule="$1"
    local command="$2"
    local description="$3"
    
    if ! check_cron "$schedule" "$command"; then
        (crontab -l 2>/dev/null; echo "$schedule $command # $description") | crontab -
        echo "Installed cron: $description"
    else
        echo "Cron already exists: $description"
    fi
}

# Function to check all cron jobs
check_crons() {
    local missing=0
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        
        # Parse the cron entry
        local schedule=$(echo "$line" | awk '{$NF=""; print $1" "$2" "$3" "$4" "$5}')
        local command=$(echo "$line" | awk -F'#' '{print $1}' | awk '{for(i=6;i<=NF;i++) printf "%s ", $i}' | sed 's/ *$//')
        local description=$(echo "$line" | awk -F'#' '{print $2}' | xargs)
        
        if ! check_cron "$schedule" "$command"; then
            echo "Missing cron: $description"
            missing=$((missing + 1))
        fi
    done < "$CRONTAB_FILE"
    
    if [ $missing -eq 0 ]; then
        echo "All cron jobs are installed!"
        return 0
    else
        echo "Found $missing missing cron job(s)"
        return 1
    fi
}

# Function to install all missing cron jobs
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