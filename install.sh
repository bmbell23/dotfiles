#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup existing .bashrc if it exists
if [ -f "${HOME}/.bashrc" ]; then
    mv "${HOME}/.bashrc" "${HOME}/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create new .bashrc that sources our managed files
echo "# This file is managed by dotfiles repository" > "${HOME}/.bashrc"
echo "source ${DOTFILES_DIR}/bashrc/main.bashrc" >> "${HOME}/.bashrc"

# Create local config template if it doesn't exist
if [ ! -f "${DOTFILES_DIR}/bashrc/local.sh" ]; then
    cp "${DOTFILES_DIR}/bashrc/local.sh.example" "${DOTFILES_DIR}/bashrc/local.sh"
fi

echo "Installation complete! Please source your new .bashrc:"
echo "source ~/.bashrc" 