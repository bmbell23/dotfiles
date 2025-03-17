###############################################################################
#   Including things that make dealing with Unified simpler/faster
###############################################################################
source /home/$USER/work/projects/auto/tools/bash/sfaos.sh

###############################################################################
#   Bring in various tools
###############################################################################
export TOOL_DIR=/home/$USER/work/general/tools/
export PERL_MOD_DIR=${TOOL_DIR}/scripts/modules/
export BASH_DIR=${TOOL_DIR}bash/
export CLOC=${TOOL_DIR}scripts/cloc-1.84.pl

source ${BASH_DIR}kmip/kmip.sh
# CI is too dumb to reinstall PEMs. Source a fixed copy of the jbash_profile
# script to get the 'bug' ('de') alias
source ${BASH_DIR}jbash_profile

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

eval `dircolors`

# CUSTOMIZED COMMAND PROMPT:
PS1="\e[1;34m\n[\W]:\e[m\n"

