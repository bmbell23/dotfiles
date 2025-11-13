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

    local hour=$(date +%-H)  # Use %-H to remove leading zeros
    local name=${1:-$(whoami)}  # Use provided name or username if not provided
    local greeting

    # Define color codes properly
    local GREEN="\033[0;32m"
    local YELLOW="\033[0;33m"
    local BLUE="\033[0;34m"
    local CYAN="\033[0;36m"
    local WHITE="\033[1;37m"
    local RESET="\033[0m"
    local BOLD="\033[1m"

    # Change to project directory
    cd "$WORKSPACE"

    # Source project specific shell configurations
    if [ -d "${WORKSPACE}/config/shell" ]; then
        for config_file in ".bash_functions" ".bash_aliases" ".bash_variables"; do
            if [ -f "${WORKSPACE}/config/shell/${config_file}" ]; then
                source "${WORKSPACE}/config/shell/${config_file}"
            fi
        done
    fi

    # For backwards compatibility, also check root directory
    for config_file in ".bash_functions" ".bash_aliases" ".bash_variables"; do
        if [ -f "${WORKSPACE}/${config_file}" ]; then
            source "${WORKSPACE}/${config_file}"
        fi
    done

    # Special handling for reading_tracker project
    if [ "$1" = "reading_tracker" ]; then
        # Activate virtual environment if it exists
        if [ -d "${WORKSPACE}/venv" ]; then
            source "${WORKSPACE}/venv/bin/activate"
            echo -e "${GREEN}Activated reading_tracker virtual environment${RESET}"
        fi

        echo -e "\n${YELLOW}Here's your kanban board for this project:${RESET}"
        show_kanban
    # Show kanban for dotfiles project
    elif [ "$1" = "dotfiles" ]; then
        echo -e "\n${YELLOW}Here's your kanban board for this project:${RESET}"
        show_kanban
    fi

    # Look for and launch workspace file, create if missing (only if VS Code is available)
    if command -v code &>/dev/null; then
        local workspace_file="${1}.code-workspace"
        if [ ! -f "$workspace_file" ]; then
            # Determine theme based on project type only for new workspace files
            local theme_name
            if [ "$1" = "dotfiles" ]; then
                theme_name="Pretty Pastel"
            elif [[ "$1" == *"auto"* ]]; then
                theme_name="mikasa rainbow"
            elif [[ "$1" == *"sfaos"* ]]; then
                theme_name="Monokai"
            else
                theme_name="Default Dark+"  # fallback theme
            fi

            cat > "${workspace_file}" << EOF
{
    "folders": [
        {
            "path": "."
        }
    ],
    "name": "${1}",
    "settings": {
        "workbench.colorTheme": "${theme_name}",
        "search.exclude": {
            "**/node_modules": true,
            "**/bower_components": true,
            "**/*.code-search": true,
            "**/build/**": true,
            "**/dist/**": true
        },
        "files.exclude": {
            "**/.git": true,
            "**/.svn": true,
            "**/.hg": true,
            "**/CVS": true,
            "**/.DS_Store": true,
            "**/Thumbs.db": true
        },
        "files.watcherExclude": {
            "**/.git/objects/**": true,
            "**/.git/subtree-cache/**": true,
            "**/node_modules/**": true,
            "**/build/**": true,
            "**/dist/**": true
        }
    }
}
EOF
            echo -e "${GREEN}Created new workspace file: ${WHITE}${workspace_file}${RESET}"
        fi

        # Launch workspace in VS Code
        code -n "$workspace_file"
    fi
}

# Project switching completion without subdirectory support
_sp_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local projects_dir="$HOME/projects"

    # Get only top-level directories, excluding hidden ones
    COMPREPLY=($(compgen -W "$(find "$projects_dir" -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' | sed "s|$projects_dir/||")" -- "$cur"))
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

# Interactive project selector with fancy formatting
function pp() {
    # Colors and formatting
    local RED="\033[0;31m"
    local GREEN="\033[0;32m"
    local YELLOW="\033[0;33m"
    local BLUE="\033[0;34m"
    local PURPLE="\033[0;35m"
    local PINK="\033[1;35m"  # Bright/bold magenta for auto projects
    local ORANGE="\033[0;33m\033[1m"  # Bold yellow for orange effect for sfaos projects
    local GRAY="\033[0;37m"  # Gray for everything else
    local CYAN="\033[0;36m"
    local WHITE="\033[1;37m"
    local RESET="\033[0m"
    local BOLD="\033[1m"

    # Box drawing characters - using ASCII instead of Unicode
    local TOP_LEFT="+"
    local TOP_RIGHT="+"
    local BOTTOM_LEFT="+"
    local BOTTOM_RIGHT="+"
    local HORIZONTAL="-"
    local VERTICAL="|"
    local BULLET="*"

    # Store projects in an array
    local projects=($(ls -d ~/projects/* | sed 's|/home/'$USER'/projects/||' | sort))
    local project_count=${#projects[@]}

    # Calculate max project name length
    local max_length=0
    for project in "${projects[@]}"; do
        if [ ${#project} -gt $max_length ]; then
            max_length=${#project}
        fi
    done

    # Box dimensions
    local SIDE_PADDING=2
    local NUMBER_WIDTH=4  # "XX) "
    local INNER_WIDTH=$((max_length + NUMBER_WIDTH + (2 * SIDE_PADDING)))
    local TITLE="[ Project Selector ]"
    local TITLE_LENGTH=${#TITLE}
    local LEFT_PADDING=$(( (INNER_WIDTH - TITLE_LENGTH - 1) / 2 ))
    local RIGHT_PADDING=$((INNER_WIDTH - TITLE_LENGTH - LEFT_PADDING - 1))

    # Clear screen
    clear

    # Print top border with centered title
    echo -en "${CYAN}${TOP_LEFT}"
    printf "%${LEFT_PADDING}s" | tr " " "${HORIZONTAL}"
    echo -en "${WHITE}${BOLD}${TITLE}${CYAN}"
    printf "%${RIGHT_PADDING}s" | tr " " "${HORIZONTAL}"
    echo -e "${TOP_RIGHT}${RESET}"

    # Print project count with dynamic padding
    local count_text="Found ${project_count} projects"
    local count_padding=$((INNER_WIDTH - ${#count_text} - 2))  # -2 for the initial space and border
    echo -en "${CYAN}${VERTICAL}${RESET} Found ${GREEN}${BOLD}${project_count}${RESET} projects"
    printf "%${count_padding}s" ""
    echo -e "${CYAN}${VERTICAL}${RESET}"

    # Print separator
    echo -en "${CYAN}${VERTICAL}"
    printf "%$((INNER_WIDTH - 1))s" | tr " " "${HORIZONTAL}"
    echo -e "${VERTICAL}${RESET}"

    # Display projects with color coding
    for ((i=0; i<project_count; i++)); do
        local num=$((i + 1))
        local project_color="${GRAY}"  # Default color for everything else

        # Set color based on project name
        if [[ "${projects[$i]}" == auto* ]]; then
            project_color="${PINK}"  # Auto projects in pink
        elif [[ "${projects[$i]}" == sfaos* ]]; then
            project_color="${ORANGE}"  # SFAOS projects in orange
        fi
        
        echo -en "${CYAN}${VERTICAL}${RESET} "
        printf "%2d${RESET}) ${project_color}%-${max_length}s${RESET}" $num "${projects[$i]}"
        printf "%${SIDE_PADDING}s" ""
        echo -e "${CYAN}${VERTICAL}${RESET}"
    done

    # Print bottom border
    echo -en "${CYAN}${BOTTOM_LEFT}"
    printf "%$((INNER_WIDTH - 1))s" | tr " " "${HORIZONTAL}"
    echo -e "${BOTTOM_RIGHT}${RESET}"

    # Prompt for selection
    echo -en "\n${CYAN}${BULLET}${RESET} Select project ${CYAN}(${WHITE}1${CYAN}-${WHITE}${project_count}${CYAN})${RESET}: "
    read selection

    # Validate input
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$project_count" ]; then
        echo -e "\n${RED}Invalid selection${RESET}"
        return 1
    fi

    # Switch to selected project
    local index=$((selection - 1))
    local project_name="${projects[$index]}"
    
    # Color the project name in the confirmation message based on type
    local confirm_color="${GRAY}"
    if [[ "${project_name}" == auto* ]]; then
        confirm_color="${PINK}"
    elif [[ "${project_name}" == sfaos* ]]; then
        confirm_color="${ORANGE}"
    fi
    
    echo -e "\n${WHITE}Switching to project: ${confirm_color}${BOLD}${project_name}${RESET}"

    # Save current directory before switching
    local original_dir="$(pwd)"
    sp "${project_name}"

    # Determine theme based on project type
    local theme_name
    if [ "${project_name}" = "dotfiles" ]; then
        theme_name="Pretty Pastel"
    elif [[ "${project_name}" == *"auto"* ]]; then
        theme_name="mikasa rainbow"
    elif [[ "${project_name}" == *"sfaos"* ]]; then
        theme_name="Monokai"
    else
        theme_name="Default Dark+"  # fallback theme
    fi

    # Look for and launch workspace file, create if missing (only if VS Code is available)
    if command -v code &>/dev/null; then
        local workspace_file="${project_name}.code-workspace"
        if [ ! -f "$workspace_file" ]; then
            cat > "${workspace_file}" << EOF
{
    "folders": [
        {
            "path": "."
        }
    ],
    "name": "${project_name}",
    "settings": {
        "workbench.colorTheme": "${theme_name}",
        "search.exclude": {
            "**/node_modules": true,
            "**/bower_components": true,
            "**/*.code-search": true,
            "**/build/**": true,
            "**/dist/**": true
        },
        "files.exclude": {
            "**/.git": true,
            "**/.svn": true,
            "**/.hg": true,
            "**/CVS": true,
            "**/.DS_Store": true,
            "**/Thumbs.db": true
        },
        "files.watcherExclude": {
            "**/.git/objects/**": true,
            "**/.git/subtree-cache/**": true,
            "**/node_modules/**": true,
            "**/build/**": true,
            "**/dist/**": true
        }
    }
}
EOF
            echo -e "${GREEN}Created new workspace file: ${WHITE}${workspace_file}${RESET}"
        else
            # Update existing workspace file's theme
            sed -i "s/\"workbench.colorTheme\": \".*\"/\"workbench.colorTheme\": \"${theme_name}\"/" "$workspace_file"
            if ! grep -q "workbench.colorTheme" "$workspace_file"; then
                # If theme setting doesn't exist, add it to settings object
                sed -i "/\"settings\": {/a \        \"workbench.colorTheme\": \"${theme_name}\"," "$workspace_file"
            fi
        fi

        # Launch workspace in VS Code
        code -n "$workspace_file"
    fi

    # Don't return to original directory - stay in the selected project
    # cd "$original_dir"  # Remove this line
}
