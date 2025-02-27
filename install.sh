#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup existing files
if [ -f "${HOME}/.bashrc" ]; then
    mv "${HOME}/.bashrc" "${HOME}/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [ -f "${HOME}/.dircolors" ]; then
    mv "${HOME}/.dircolors" "${HOME}/.dircolors.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create new .bashrc that sources our managed files
echo "# This file is managed by dotfiles repository" > "${HOME}/.bashrc"
echo "source ${DOTFILES_DIR}/bashrc/main.bashrc" >> "${HOME}/.bashrc"

# Install .dircolors
cp "${DOTFILES_DIR}/.dircolors" "${HOME}/.dircolors"

# Create local config template if it doesn't exist
if [ ! -f "${DOTFILES_DIR}/bashrc/local.sh" ]; then
    cp "${DOTFILES_DIR}/bashrc/local.sh.example" "${DOTFILES_DIR}/bashrc/local.sh"
fi

# Install cron jobs
echo "Installing cron jobs..."
"${DOTFILES_DIR}/scripts/cron/install_crons.sh" install

echo "Installation complete! Please source your new .bashrc:"
echo "source ~/.bashrc" 
