#!/bin/bash

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    log "Error: Missing required arguments"
    log "Usage: ./version_commit.sh <version> <commit_message>"
    log "Example: ./version_commit.sh \"1.1.0\" \"Updated version to 1.1.0\""
    exit 1
fi

# Determine package name from pyproject.toml or directory structure
if [ -f "pyproject.toml" ]; then
    PACKAGE_NAME=$(grep -m 1 "name\s*=\s*\".*\"" pyproject.toml | cut -d'"' -f2 | tr -d '[:space:]')
elif [ -f "setup.py" ]; then
    PACKAGE_NAME=$(grep -m 1 "name=" setup.py | cut -d'"' -f2 | tr -d '[:space:]')
else
    PACKAGE_NAME=$(basename $(pwd) | tr -d '[:space:]')
fi

# Run version update script and capture its exit status
if command -v "$PACKAGE_NAME" >/dev/null 2>&1; then
    $PACKAGE_NAME update-version --update "$1"
else
    echo "Error: $PACKAGE_NAME command not found. Please ensure the package is installed and in your PATH"
    exit 1
fi

# Check if update_version.py succeeded
if [ $UPDATE_STATUS -ne 0 ]; then
    echo "Error: Version update failed"
    exit 1
fi
log "Version updated to $1"

# 1. See what files have been changed
git status

# 2. Add files to staging
git add .

# 3. Commit changes and create tag, then push both
git commit -m "$2" && git tag "v$1" && git push --follow-tags

# 6. Check status again to show everything is clean
git status

echo "Done! Version $1 has been committed, tagged, and pushed"

