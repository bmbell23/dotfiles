# .bashrc

# Color definitions
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

# Projects directory configuration - can be overridden in user's personal bashrc
if [ -z "$PROJECTS_DIR" ]; then
    if [ -d "/home/$USER/work/projects" ]; then
        export PROJECTS_DIR="/home/$USER/work/projects"
    elif [ -d "/home/$USER/projects" ]; then
        export PROJECTS_DIR="/home/$USER/projects"
    else
        export PROJECTS_DIR="/home/$USER/work/projects"  # Default fallback
    fi
fi

# Prompt configuration
PS1="[\u@\h \W]\\$ "

# Git branch in prompt
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "

# Directory colors
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Source external configurations
if [ -f "$PROJECTS_DIR/sfaos/janus/test/scripts/jbash_profile" ]; then
    source $PROJECTS_DIR/sfaos/janus/test/scripts/jbash_profile
fi

###############################################################################
# ALIASES
###############################################################################

# Basic navigation and listing
alias ll='ls -alh'                    # Long listing with human readable sizes
alias la="ls -al"                     # Long listing all files
alias p="pwd"                         # Print working directory

# Project navigation (needed here because distrox doesn't allow aliases from /etc/bashrc)
alias goproj='cd $PROJECTS_DIR/$PROJECT'
alias gojanus='cd $PROJECTS_DIR/$PROJECT/janus'

# Color aliases for common commands
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Development and debugging
alias psu="ps -ef | grep -e unified$"
alias clean='sudo rm -rf /tmp;sudo pkill -9 -u $USER unified;sudo pkill -9 -u $USER perl;sudo pkill -9 -u auto unified'

# Disk usage and system monitoring
alias bdu='time sudo du -shc * | grep -v "ssh_" | sort -rh'
alias mydu="time du --max-depth=2 -B M ~/work | sort -rn"
alias thisdu="time sudo du --max-depth=2 -B M . | sort -rn"
alias dfall="time df -h /home/logs /home/cilogs /home/$USER"

# Testing and development tools
alias batch_tests='perl $PROJECTS_DIR/$PROJECT/janus/test/scripts/lib/util/batch_tests.pl'
alias bt="unset UNIFIED_ENV; batch_tests -L -F -v -r"
alias btc="batch_tests -C -L -F -v -r"
alias gs='log -m --pretty=format:%C(yellow)%h%C(auto)%d\ %Creset%s\ (%cr)\ %C(cyan)[%cn] --decorate'

# Log viewing and analysis
alias lv="perl $PROJECTS_DIR/auto/tools/lv/lv.pl"
alias follow="tail -F"

# Git aliases
alias gl='git log --pretty=full --name-only --show-notes'
alias gs='git status --untracked-files=all'
alias gp='git pull'
alias gr='git review'
alias gR='git review -R'

# Monty aliases
alias mut='./run_unit_tests.sh'

# Linter aliases
alias lint='./linter.sh'

###############################################################################
# FUNCTIONS
###############################################################################

# Git add and commit with conditional linting and testing
function gac() {
    local current_dir=$(basename "$PWD")

    # Check if we're in the monty directory
    if [[ "$current_dir" == "monty" ]]; then
        echo "Running lint in monty directory..."
        if ! ./linter.sh; then
            echo "Lint failed! Aborting commit."
            return 1
        fi
        echo "Running unit tests in monty directory..."
        if ! ./run_unit_tests.sh; then
            echo "Unit tests failed! Aborting commit."
            return 1
        fi
    # Check if we're in auto directory (or directory containing "auto")
    elif [[ "$current_dir" == "auto" || "$current_dir" == *"auto"* ]]; then
        echo "Running unit tests in auto directory..."
        if ! jenkins/tests/run_unit_tests.sh; then
            echo "Unit tests failed! Aborting commit."
            return 1
        fi
    fi

    git add .
    git commit "$@"
}

# Git add, commit, and amend with conditional linting and testing
function gaca() {
    local current_dir=$(basename "$PWD")

    # Check if we're in the monty directory
    if [[ "$current_dir" == "monty" ]]; then
        echo "Running lint in monty directory..."
        if ! ./linter.sh; then
            echo "Lint failed! Aborting commit."
            return 1
        fi
        echo "Running unit tests in monty directory..."
        if ! ./run_unit_tests.sh; then
            echo "Unit tests failed! Aborting commit."
            return 1
        fi
    # Check if we're in auto directory (or directory containing "auto")
    elif [[ "$current_dir" == "auto" || "$current_dir" == *"auto"* ]]; then
        echo "Running unit tests in auto directory..."
        if ! jenkins/tests/run_unit_tests.sh; then
            echo "Unit tests failed! Aborting commit."
            return 1
        fi
    fi

    git add .
    git commit --amend "$@"
}

function setproj()
{
    # Set PROJECT environment variable
    export PROJECT=$1
}

function sp()
{
    # Set project and navigate to janus directory
    setproj "$@";
    gojanus > /dev/null 2>&1;
    if [ $? -ne 0 ]; then
        goproj;
    fi
    echo Project is now $@;
}

# Bash completion for project switching
_sp()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    pushd ${PROJECTS_DIR} >/dev/null 2>&1
    COMPREPLY=( $(compgen -d -- $cur) )
    popd >/dev/null 2>&1
}
complete -F _sp sp
complete -F _sp setproj

# Function: Install a PEM Kit
function ipk()
{
    local pem_kit="$1"

    # If no argument provided, find the kit in the highest version directory
    if [ -z "$pem_kit" ]; then
        local base_dir="/home/cilogs/pem_kits"

        # Find the highest version directory using version sort
        local latest_version=$(ls -1 "$base_dir" | grep -E '^[0-9]+\.[0-9]+$' | sort -V | tail -1)

        if [ -z "$latest_version" ]; then
            echo "Error: No version directories found in $base_dir"
            return 1
        fi

        local kit_dir="$base_dir/$latest_version/"
        echo "Using latest version directory: $kit_dir"

        # Find the PEM kit in the latest version directory
        pem_kit=$(find "$kit_dir" -name "ddn-flash-PEM-*-dev-debug.nojanus.tar.zst" -type f | head -1)

        if [ -z "$pem_kit" ]; then
            echo "Error: No PEM kit found matching pattern 'ddn-flash-PEM-*-dev-debug.nojanus.tar.zst' in $kit_dir"
            return 1
        fi

        echo "Using PEM kit: $pem_kit"
    fi

    sudo /ddn/install/upgrade_fw.sh "$pem_kit"
}

# Help: dynamically list aliases and functions defined in the dotfiles bashrc/ tree.
# Usage: bhelp [pattern]   (optional case-insensitive filter on name or description)
function bhelp()
{
    local bashrc_dir
    bashrc_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local filter="${1:-}"

    # Local color vars — independent of global GREEN/NC, which conf.d may redefine
    # as PS1-bracketed escapes (unsafe for plain printf).
    local C_HDR="" C_FILE="" C_NAME="" C_RESET=""
    if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
        C_HDR="$(tput bold)$(tput setaf 6)"
        C_FILE="$(tput setaf 3)"
        C_NAME="$(tput setaf 2)"
        C_RESET="$(tput sgr0)"
    fi

    # Collect bash source files under the dotfiles bashrc dir
    local files=() f
    while IFS= read -r f; do
        files+=("$f")
    done < <(find "$bashrc_dir" -type f \
                  \( -name '*.sh' -o -name '*.bashrc' -o -name '.bash*' \) \
                  ! -name '*.example' ! -name '*.backup.*' 2>/dev/null | sort)

    # awk program: emit NAME<TAB>DESCRIPTION lines for the requested kind.
    # Description comes from the comment block immediately above the definition;
    # if none, falls back to the alias body (for aliases) or "(undocumented)".
    local awk_extract='
        function flush(name, fallback) {
            if (desc == "") desc = fallback
            print name "\t" desc
            desc = ""
        }
        /^[[:space:]]*#/ {
            line=$0
            sub(/^[[:space:]]*#+[[:space:]]*/, "", line)
            sub(/^Function:[[:space:]]*/, "", line)
            if (line == "") next
            if (desc == "") desc=line; else desc=desc " " line
            next
        }
        kind == "alias" && /^[[:space:]]*alias[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*=/ {
            line=$0
            sub(/^[[:space:]]*alias[[:space:]]+/, "", line)
            eq = index(line, "=")
            name = substr(line, 1, eq-1)
            body = substr(line, eq+1)
            # Strip surrounding quotes (and trailing inline comments) if quoted
            first = substr(body, 1, 1)
            if (first == "\"" || first == "\047") {
                body = substr(body, 2)
                p = index(body, first)
                if (p > 0) body = substr(body, 1, p-1)
            }
            flush(name, "= " body)
            next
        }
        kind == "function" && /^[[:space:]]*(function[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)/ {
            name=$0
            sub(/^[[:space:]]*function[[:space:]]+/, "", name)
            sub(/[[:space:]]*\(\).*$/, "", name)
            if (name ~ /^_/) { desc=""; next }
            flush(name, "(undocumented)")
            next
        }
        { desc="" }
    '

    local kind_title kind title entries rel
    for kind_title in "alias|ALIASES" "function|FUNCTIONS"; do
        kind="${kind_title%|*}"
        title="${kind_title#*|}"
        printf '\n%s== %s ==%s\n' "$C_HDR" "$title" "$C_RESET"
        for f in "${files[@]}"; do
            entries="$(awk -v kind="$kind" "$awk_extract" "$f")"
            [ -z "$entries" ] && continue
            if [ -n "$filter" ]; then
                entries="$(printf '%s\n' "$entries" | grep -i -- "$filter")"
                [ -z "$entries" ] && continue
            fi
            rel="${f#$bashrc_dir/}"
            printf '  %s%s%s\n' "$C_FILE" "$rel" "$C_RESET"
            printf '%s\n' "$entries" | while IFS=$'\t' read -r name desc; do
                printf '    %s%-22s%s %s\n' "$C_NAME" "$name" "$C_RESET" "$desc"
            done
        done
    done
}

###############################################################################
# SOURCING (must stay at end so later files can override earlier definitions)
###############################################################################

export PATH="$HOME/.local/bin:$PATH"

# Source auto project's bashrc snippets if present
for f in /home/$USER/work/projects/auto/.bashrc/*.sh; do
    [ -f "$f" ] && source "$f"
done

# Source modular configs from conf.d/ (prompt, aliases, completion, etc.)
for f in "$(dirname "${BASH_SOURCE[0]}")"/conf.d/*.sh; do
    [ -r "$f" ] && source "$f"
done

# Source work-specific configs (entry point chains to sibling files)
if [ -r "$(dirname "${BASH_SOURCE[0]}")/work/.bashrc" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/work/.bashrc"
fi

