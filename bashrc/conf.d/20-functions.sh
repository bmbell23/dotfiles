#!/bin/bash

# Utility functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Timestamp logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function to redirect all output through timestamp logger
enable_timestamps() {
    exec 1> >(while read -r line; do log "$line"; done)
    exec 2> >(while read -r line; do log "[ERROR] $line" >&2; done)
}

# Git version management and commit function
gvc() {
    if [ $# -ne 2 ]; then
        echo "Error: Missing required arguments"
        echo "Usage: gvc <version> <commit_message>"
        echo "Example: gvc \"1.1.0\" \"Added package management system\""
        return 1
    fi

    local version=$1
    local message=$2

    # Validate version format (X.Y.Z)
    if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version must be in format X.Y.Z (e.g., 1.0.0)"
        return 1
    fi

    # Show what's being changed
    git status

    # Add all changes
    git add .

    # Commit with version in message
    git commit -m "v${version}: ${message}"

    # Create version tag
    git tag -a "v${version}" -m "Version ${version}"

    # Push changes and tags
    git push && git push --tags

    # Show final status
    echo -e "\nPush complete! Version v${version} has been committed and tagged"
    git status
}

# Set project root
sp() {
    WORKSPACE="/home/brandon/projects/$1"

    local hour=$(date +%H)
    local name=${1:-$(whoami)}  # Use provided name or username if not provided
    local greeting

    # Define color codes properly
    local GREEN="\033[0;32m"
    local YELLOW="\033[0;33m"
    local BLUE="\033[0;34m"
    local CYAN="\033[0;36m"
    local RESET="\033[0m"

    # Determine greeting and comment based on time of day
    if (( hour >= 0 && hour < 12 )); then
        greeting="Good morning"
        comment="Welcome back, are you ready for the day?"
    elif (( hour >= 12 && hour < 17 )); then
        greeting="Good afternoon"
    elif (( hour >= 17 && hour < 24 )); then
        greeting="Good evening"
    fi

    # Get current time in 12-hour format
    local time=$(date +"%I:%M %p")
    
    clear
    echo -e "${GREEN}${greeting}, $USER! ${comment}${RESET}"
    echo -e "${CYAN}It's currently ${time}.${RESET}"

    echo -e "${YELLOW}You're in ${WORKSPACE} right now.${RESET}"
    cd "$WORKSPACE"
    
    # Try to activate virtual environment if it exists
    if [ -f "venv/bin/activate" ]; then
        echo -e "${CYAN}Activating Python virtual environment...${RESET}"
        source venv/bin/activate
    fi

    echo -e "${YELLOW}Here's the status of your project:${RESET}"
    git status

    # Show WIP items
    echo -e "\n${YELLOW}You're currently working on:${RESET}"
    if [[ -f "$WORKSPACE/.kanban/wip.txt" ]]; then
        cat "$WORKSPACE/.kanban/wip.txt"
    else
        echo -e "${CYAN}Nothing! You have a clean slate to start something new!${RESET}"
    fi

    # Prompt to show full kanban board
    echo -e "\n${YELLOW}Would you like to see the full kanban board? ${BLUE}(y/n)${RESET}"
    read -r show_kanban
    if [[ "$show_kanban" =~ ^[Yy]$ ]]; then
        show_kanban
    fi
}

# Project switching completion with subdirectory support
_sp_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local projects_dir="$HOME/projects"
    
    # Get all directories up to 2 levels deep, excluding hidden ones
    # Add trailing slash to make directory navigation more convenient
    COMPREPLY=($(compgen -W "$(find "$projects_dir" -mindepth 1 -maxdepth 2 -type d -not -path '*/\.*' | sed "s|$projects_dir/||" | sed 's|$|/|')" -- "$cur"))
}
complete -F _sp_complete sp

# Version management functions
version() {
    case "$1" in
        "check")
            python3 -m scripts.updates.update_version --check
            ;;
        "update")
            if [ -z "$2" ]; then
                echo "Usage: version update <version>"
                return 1
            fi
            python3 -m scripts.updates.update_version --update "$2"
            ;;
        *)
            echo "Usage: version {check|update <version>}"
            return 1
            ;;
    esac
}

# Version management completion
_version_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    case "$prev" in
        "version")
            COMPREPLY=($(compgen -W "check update" -- "$cur"))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}
complete -F _version_complete version

# General directory completion with proper trailing slashes
_dir_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=$'\n'
    
    # Complete directories and ensure trailing slashes
    COMPREPLY=($(compgen -d -- "$cur" | sed 's|$|/|'))
}

# Apply to relevant commands
complete -o nospace -F _dir_complete cd

