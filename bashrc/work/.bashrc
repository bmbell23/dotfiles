# Source sfaos bashrc
if [ -f /home/$USER/projects/auto/tools/bash/sfaos.sh ]; then
    source /home/$USER/projects/auto/tools/bash/sfaos.sh
fi

# Source PEM kit bashrc
if [ -f /etc/bashrc ]; then
    source /etc/bashrc
fi

# Only do this stuff if we're in an interactive shell
if [[ "$-" =~ 'i' ]]; then
    umask 022
fi