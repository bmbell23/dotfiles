#!/bin/bash

# Navigation
alias ll='ls -alhF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -lt'

# Git aliases
alias gs='git status'
alias gl='git log --name-only'
alias gd='git diff'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gac='git add . && git commit'
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
