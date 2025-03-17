#!/bin/bash

# Source all configuration files
for config in "${HOME}/projects/dotfiles/bashrc/conf.d/"*.sh; do
    source "$config"
done

# Source local machine-specific config if it exists
if [ -f "${HOME}/projects/dotfiles/bashrc/local.sh" ]; then
    source "${HOME}/projects/dotfiles/bashrc/local.sh"
fi

# Source all work-specific bash files
for config in "${HOME}/projects/dotfiles/bashrc/work/.bash*"; do
    if [ -f "$config" ]; then
        source "$config"
    fi
done

# Source project specific bashrc if it exists
if [ -f "${WORKSPACE}/.bashrc" ]; then
    source "${WORKSPACE}/config/shell/.bash_*"
fi

# Source project specific bash aliases if it exists
if [ -f "${WORKSPACE}/.bash_aliases" ]; then
    source "${WORKSPACE}/.bash_aliases"
fi

# Source project specific bash functions if it exists
if [ -f "${WORKSPACE}/.bash_functions" ]; then
    source "${WORKSPACE}/.bash_functions"
fi

# Source project specific bash variables if it exists
if [ -f "${WORKSPACE}/.bash_variables" ]; then
    source "${WORKSPACE}/.bash_variables"
fi
