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
    local current_version
    local version
    local message
    local git_root

    # Get the git root directory
    git_root=$(git rev-parse --show-toplevel)
    if [ $? -ne 0 ]; then
        echo "Error: Not in a git repository"
        return 1
    fi

    # Check if we have 1 or 2 arguments
    if [ $# -eq 1 ]; then
        # Only message provided, need to auto-increment version
        message="$1"

        # Check which project we're in and use appropriate method
        if [ -f "${git_root}/version.txt" ]; then
            # For dotfiles project, get version from version.txt
            current_version=$(cat "${git_root}/version.txt")
        elif [ -f "${git_root}/CHANGELOG.md" ]; then
            current_version=$(grep -m 1 "## \[.*\]" "${git_root}/CHANGELOG.md" | grep -oP "\[\K[^\]]+")
        elif [ -f "${git_root}/scripts/updates/update_version.py" ]; then
            current_version=$(python3 -m scripts.updates.update_version --check | grep -oP '\d+\.\d+\.\d+' | head -n1 || true)
        elif [ -f "${git_root}/pyproject.toml" ]; then
            current_version=$(grep -m 1 "version\s*=\s*\".*\"" "${git_root}/pyproject.toml" | cut -d'"' -f2)
        fi

        if [ -z "$current_version" ]; then
            echo "Error: Could not determine current version"
            return 1
        fi

        echo "Current version: $current_version"

        # Split version into major.minor.patch
        IFS='.' read -r major minor patch <<< "$current_version"

        # Increment patch version
        patch=$((patch + 1))

        # Construct new version
        version="${major}.${minor}.${patch}"

        echo "New version will be: $version"

    elif [ $# -eq 2 ]; then
        # Both version and message provided
        version="$1"
        message="$2"
    else
        echo "Usage: gvc <message>           # Auto-increments point release"
        echo "       gvc <version> <message> # Uses specified version"
        return 1
    fi

    # Validate version format (X.Y.Z)
    if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version must be in format X.Y.Z (e.g., 1.0.0)"
        return 1
    fi

    # Update version in appropriate files based on project type
    if [ -f "${git_root}/version.txt" ]; then
        echo "$version" > "${git_root}/version.txt"
    elif [ -f "${git_root}/CHANGELOG.md" ]; then
        sed -i "s/## \[.*\]/## [$version]/" "${git_root}/CHANGELOG.md"
    elif [ -f "${git_root}/scripts/updates/update_version.py" ]; then
        python3 -m scripts.updates.update_version --update "$version"
    elif [ -f "${git_root}/pyproject.toml" ]; then
        sed -i "s/version = \".*\"/version = \"$version\"/" "${git_root}/pyproject.toml"
    fi

    # Commit changes
    git add .
    git commit -m "v$version: $message"
    git tag -a "v$version" -m "Version $version"
    git push && git push --tags
}

# Set project root
sp() {
    WORKSPACE="/home/$USER/projects/$1"

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

    # Source all shell configuration files if they exist
    if [ -d "config/shell" ]; then
        echo -e "${CYAN}Sourcing shell configuration files...${RESET}"
        # Source files in a specific order
        local shell_files=(".bash_variables" ".bash_functions" ".bash_aliases")
        for file in "${shell_files[@]}"; do
            if [ -f "config/shell/$file" ]; then
                echo -e "${CYAN}Loading $file...${RESET}"
                source "config/shell/$file"
            fi
        done
        # Source any additional .bash_* files
        for file in config/shell/.bash_*; do
            if [ -f "$file" ] && [[ ! " ${shell_files[@]} " =~ " $(basename $file) " ]]; then
                echo -e "${CYAN}Loading $(basename $file)...${RESET}"
                source "$file"
            fi
        done
    fi

    # Prompt to show full kanban board
    echo -e "\n${YELLOW}Here's your kanban board for this project:${RESET}"
    show_kanban
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

# Interactive project selector
function pp() {
    # Store projects in an array, stripping the path prefix
    local projects=($(ls -d ~/projects/* | sed 's|/home/'$USER'/projects/||'))
    local i=1

    # Display numbered list of projects
    echo "Available projects:"
    echo "-----------------"
    for project in "${projects[@]}"; do
        printf "%2d) %s\n" $i "$project"
        ((i++))
    done

    # Prompt for selection
    echo
    read -p "Select project number (1-${#projects[@]}): " selection

    # Validate input
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || \
       [ "$selection" -lt 1 ] || \
       [ "$selection" -gt "${#projects[@]}" ]; then
        echo "Invalid selection"
        return 1
    fi

    # Convert selection to array index (0-based)
    local index=$((selection - 1))

    # Call sp with selected project
    sp "${projects[$index]}"
}
