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
