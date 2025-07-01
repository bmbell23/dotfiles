#!/bin/bash

# Source all configuration files
for config in "${HOME}/projects/dotfiles/bashrc/conf.d/"*.sh; do
    source "$config"
done

# Source local machine-specific config if it exists
if [ -f "${HOME}/projects/dotfiles/bashrc/local.sh" ]; then
    source "${HOME}/projects/dotfiles/bashrc/local.sh"
fi

# Source work-specific bash files explicitly
source "${HOME}/projects/dotfiles/bashrc/work/.bashrc"
source "${HOME}/projects/dotfiles/bashrc/work/.bash_functions"
source "${HOME}/projects/dotfiles/bashrc/work/.bash_aliases"
source "${HOME}/projects/dotfiles/bashrc/work/.bash_variables"

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

# direnv was removed to avoid conflicts with custom project setup
