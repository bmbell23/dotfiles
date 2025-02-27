#!/bin/bash

# Package management functions
pkg() {
    local dotfiles_dir="${HOME}/projects/dotfiles"
    local packages_script="${dotfiles_dir}/packages/install_packages.sh"
    
    case "$1" in
        "check")
            $packages_script check
            ;;
        "install")
            $packages_script install
            ;;
        "add")
            if [ -z "$2" ]; then
                echo "Usage: pkg add <package-name>"
                return 1
            fi
            $packages_script add "$2"
            ;;
        *)
            echo "Usage: pkg {check|install|add <package-name>}"
            return 1
            ;;
    esac
}

# Package management completion
_pkg_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    case "$prev" in
        "pkg")
            COMPREPLY=($(compgen -W "check install add" -- "$cur"))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}
complete -F _pkg_complete pkg

# Cron management functions
cron() {
    local dotfiles_dir="${HOME}/projects/dotfiles"
    local cron_script="${dotfiles_dir}/scripts/cron/install_crons.sh"
    
    case "$1" in
        "check")
            $cron_script check
            ;;
        "install")
            $cron_script install
            ;;
        *)
            echo "Usage: cron {check|install}"
            return 1
            ;;
    esac
}

# Cron management completion
_cron_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(compgen -W "check install" -- "$cur"))
}
complete -F _cron_complete cron
