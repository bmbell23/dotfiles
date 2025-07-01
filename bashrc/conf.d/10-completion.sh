# Bash completion settings
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Only run bind commands in interactive shells
if [[ $- == *i* ]]; then
    # Always add trailing slash to directory completions
    bind 'set mark-directories on'
    bind 'set mark-symlinked-directories on'

    # Show completion list immediately when multiple options exist
    bind 'set show-all-if-ambiguous on'

    # Ignore case when completing
    bind 'set completion-ignore-case on'
fi