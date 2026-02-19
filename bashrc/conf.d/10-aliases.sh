#!/bin/bash

# Navigation
alias ll='ls -alhF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -lt'

# Git aliases
alias gs='git status'
alias gl='git log --pretty=full --name-only --show-notes'
alias gd='git diff'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
# gac is defined as a function in work/.bash_aliases with linting and testing
alias gp='git pull'

# Python aliases
alias py='python3'
alias pip='pip3'

# Python virtual environment aliases
alias venv='source venv/bin/activate'
alias deact='deactivate'

# Project-specific aliases
alias reading-env='cd ~/projects/reading_tracker && source venv/bin/activate'

# Version control
alias vc='version_commit.sh'  # Short version
alias version-commit='version_commit.sh'  # Explicit version

# Soource bashrc
alias src='source ~/.bashrc'

alias p='cd ~/projects && clear'

alias series='reading-list series-stats --finished-only'

alias brt='cd ~/projects/reading_tracker && source venv/bin/activate && source config/shell/.bash_functions && source config/shell/.bash_aliases'
