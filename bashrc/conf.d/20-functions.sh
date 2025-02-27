#!/bin/bash

# Utility functions
mkcd() {
    mkdir -p "$1" && cd "$1"
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

# ... other functions...
