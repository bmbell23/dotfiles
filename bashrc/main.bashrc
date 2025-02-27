#!/bin/bash

# Source all configuration files
for config in "${HOME}/projects/dotfiles/bashrc/conf.d/"*.sh; do
    source "$config"
done

# Source local machine-specific config if it exists
if [ -f "${HOME}/projects/dotfiles/bashrc/local.sh" ]; then
    source "${HOME}/projects/dotfiles/bashrc/local.sh"
fi