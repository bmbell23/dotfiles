#!/bin/bash

# Set timezone to Mountain Time
export TZ="America/Denver"

# Environment variables
export EDITOR="vim"
export PATH="${HOME}/bin:${PATH}"

# History Settings
export HISTSIZE=50000                  # Maximum number of commands stored in memory
export HISTFILESIZE=500000            # Maximum number of lines in history file
export HISTCONTROL=ignoredups         # Don't store duplicate commands
export HISTTIMEFORMAT="%F %T "        # Add timestamps to history
export HISTFILE=~/.bash_history       # Set history file location
export PROMPT_COMMAND='history -a'     # Append history immediately, don't wait for shell exit

# Keep history from all terminals
shopt -s histappend                   # Append to history instead of overwriting
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# Ignore certain commands from history
export HISTIGNORE="ls:ll:cd:pwd:bg:fg:history:clear:exit"

# Don't put duplicate lines or lines starting with space in the history
export HISTCONTROL=ignoreboth

# ... other exports
