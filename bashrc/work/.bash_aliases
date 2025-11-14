#
alias ts="tree scripts"

#
alias rtver="py /home/bbell/sandbox/projects/personal/reading_tracker/reading_list/scripts/updates/update_version.py --check"

#
alias ps_skp="cd ~/sandbox/projects/personal/stephen_king_website_parser && ./setup.sh && source activate_venv.sh"

#
alias py="python3"

#
alias proj="cd ~/projects;clear;ll"

#
alias template="sp sfaos;cd janus/test/monty;time py3 frontend.py -e Template"

#
alias space="sudo du -h --max-depth=1 | sort -hr"

#
alias cmt="cd ~/projects/sfaos/janus/test/monty/ && env/venv.sh && time py3 frontend.py -e Template"

#
alias disk="sudo du -shc * | sort -h"

#
alias cer="cat /etc/*release"

#
alias cjv="cat /ddn/janus_version.txt"

alias nodes="ssh -vvv bbell@co-ci.colorado.datadirectnet.com \"python work/projects/auto/tools/jenkins/jenkins_node_deb_ver.py >> /home/bbell/sandbox/co-ci_nodes/nodes_'$(date '+%Y-%m-%d').csv'\""

# Return the mac address for eth0
alias mac="ip address | grep -C 2 eth0 | grep link/ether | cut -d' ' -f6"

# Git restore and rebase
alias gitrr='git restore --staged *;git restore *;git rebase --continue'

# change dir to pem kits
alias cdpk='cd ~/sandbox/kits/pem_kits/'

# WIP Monitor  
alias wip="~/projects/auto/tools/workflow/wip_monitor.py"

# Set time
alias stime='ctime;sudo timedatectl set-timezone UTC;sudo su -c "echo UTC > /etc/timezone";cat /etc/timezone;ls -alh /etc/localtime'

# Check time
alias ctime="cat /etc/timezone;ls -alh /etc/localtime"


alias lv="perl ~/work/general/tools/scripts/lv.pl"

# Create a PEM Kit
alias cpk="sudo platform/make_flash -D -K PEM local . debug"

alias dock="ssh core@10.36.28.254 -i /home/auto/docker/flatcar/id_rsa"

alias kits="cd ~/sandbox/kits/pem_kits/;tree"


alias ll="pwd;ls -alh"


alias setup-pem="sudo apt install -y vim neovim pdsh tig ranger"


alias bt="batch_tests -L -F -r"


alias vbt="vim /home/bbell/batch_tests/default_batch"

alias wip="/home/bbell/projects/auto-SFAP-102655-wip_monitor_updates/tools/workflow/wip_monitor_cron.sh"

alias batch_tests="perl /home/$USER/work/projects/sfaos/janus/test/scripts/lib/util/batch_tests.pl"


alias nrc='nano ~/.bashrc'


alias src='source ~/.bashrc'


alias db00='ssh root@10.36.16.25;TEST'

# Clear and then Long List
alias cl='clear;ll'

# Go to projects and Long List
alias cdp='cd ~/work/projects;ll'


alias grom='git reset --hard origin/master'

# Setup a softlink for lib in sfaos repo
alias lnlib='sp sfaos;cd janus/test/scripts;ln -s /home/$USER/work/projects/auto/lib'


alias ant='perl /home/bbell/work/projects/analyzer/lib/Analyzer/analyzer.pl'


alias gojanus='cd /home/bbell/work/projects/sfaos/janus'


alias aa='sp sfaos;cd janus;analyzer'

alias mut='./run_unit_tests.sh'

alias bm='cd /home/department_folders/FTP/COLORADO/eng/Buildmeister/Internal'


# Git add, commit, and amend with conditional linting and testing
function gaca() {
    local current_dir=$(basename "$PWD")
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    local repo_name=$(basename "$git_root" 2>/dev/null)

    # Slap the user if they're committing directly to base repos
    if [[ "$repo_name" == "auto" || "$repo_name" == "sfaos" ]]; then
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  🚨 WHAT THE FUCK ARE YOU DOING?! 🚨                          ║"
        echo "║                                                                ║"
        echo "║  You're trying to commit directly to the base repo!            ║"
        echo "║  Did you forget how to use worktrees, you absolute muppet?!    ║"
        echo "║                                                                ║"
        echo "║  USE A GODDAMN WORKTREE LIKE A PROFESSIONAL!                   ║"
        echo "║                                                                ║"
        echo "║  Try: gwt g a <ticket> <description>                           ║"
        echo "║   or: gwt g s <ticket> <description>                           ║"
        echo "║                                                                ║"
        echo "║  Now get your shit together and do it right!                   ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        return 1
    fi

    # Check if we're in a sfaos worktree (must have sfaos-SFAP- pattern)
    if [[ "$repo_name" == sfaos-SFAP-* ]]; then
        local monty_dir="${git_root}/janus/test/monty"
        if [[ ! -d "$monty_dir" ]]; then
            echo "Error: Could not find monty directory at ${monty_dir}"
            return 1
        fi

        echo "Running lint in monty directory..."
        if ! (cd "$monty_dir" && ./linter.sh); then
            echo "Lint failed! Aborting commit."
            return 1
        fi
        echo "Running unit tests in monty directory..."
        if ! (cd "$monty_dir" && ./run_unit_tests.sh); then
            echo "Unit tests failed! Aborting commit."
            return 1
        fi
    # Check if we're in an auto worktree (must have auto-SFAP- pattern)
    elif [[ "$repo_name" == auto-SFAP-* ]]; then
        echo "Running unit tests in auto directory..."
        if ! (cd "$git_root" && jenkins/tests/run_unit_tests.sh); then
            echo "Unit tests failed! Aborting commit."
            return 1
        fi
    fi

    git add .
    git commit --amend "$@"
}


alias sfaos='sp sfaos'


# Git add and commit with conditional linting and testing
function gac() {
    local current_dir=$(basename "$PWD")
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    local repo_name=$(basename "$git_root" 2>/dev/null)

    # Slap the user if they're committing directly to base repos
    if [[ "$repo_name" == "auto" || "$repo_name" == "sfaos" ]]; then
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  🚨 WHAT THE FUCK ARE YOU DOING?! 🚨                          ║"
        echo "║                                                                ║"
        echo "║  You're trying to commit directly to the base repo!            ║"
        echo "║  Did you forget how to use worktrees, you absolute muppet?!    ║"
        echo "║                                                                ║"
        echo "║  USE A GODDAMN WORKTREE LIKE A PROFESSIONAL!                   ║"
        echo "║                                                                ║"
        echo "║  Try: gwt g a <ticket> <description>                           ║"
        echo "║   or: gwt g s <ticket> <description>                           ║"
        echo "║                                                                ║"
        echo "║  Now get your shit together and do it right!                   ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        return 1
    fi

    # Check if we're in a sfaos worktree (must have sfaos-SFAP- pattern)
    if [[ "$repo_name" == sfaos-SFAP-* ]]; then
        local monty_dir="${git_root}/janus/test/monty"
        if [[ ! -d "$monty_dir" ]]; then
            echo "Error: Could not find monty directory at ${monty_dir}"
            return 1
        fi

        echo "Running lint in monty directory..."
        if ! (cd "$monty_dir" && ./linter.sh); then
            echo "Lint failed! Aborting commit."
            return 1
        fi
        echo "Running unit tests in monty directory..."
        if ! (cd "$monty_dir" && ./run_unit_tests.sh); then
            echo "Unit tests failed! Aborting commit."
            return 1
        fi
    # Check if we're in an auto worktree (must have auto-SFAP- pattern)
    elif [[ "$repo_name" == auto-SFAP-* ]]; then
        echo "Running unit tests in auto directory..."
        if ! (cd "$git_root" && jenkins/tests/run_unit_tests.sh); then
            echo "Unit tests failed! Aborting commit."
            return 1
        fi
    fi

    git add .
    git commit "$@"
}

# Send 'git review'
alias gr='git review'

# Send 'git review -R'
alias gR='git review -R'

# Show the size of all files and directories, sorted by size.
alias size='du -sh .[^.]* * 2>/dev/null | sort -hr'

# Show the percentage of disk used in /home/logs, /home/cilogs, and /home/group
alias sod='df -h /home/logs /home/cilogs /home/group'

# Effectively abandon all of your changes, and do a fresh pull.
alias ga='git checkout -- .;gp'

# View the work note.
alias vw='less $NOTE_WORK'

# View the personal note.
alias vp='less $NOTE_PERSONAL'

# Build a PEM kit with your current checkout.  -D is for development, and -K is with no unified firmware.
alias pemkit='sudo platform/make_flash -D -K PEM local . debug'

alias django='godjango;/home/bbell/work/projects/sfaos/janus/test/monty/py3 manage.py runserver 10.36.28.88:8000'

alias gomonty='cd ~/work/projects/monty/janus/test/monty'

alias godjango='sp sfaos;cd ~/work/projects/sfaos/janus/test/monty/django_server/mysite'

alias gs='git status --untracked-files=all'

alias lint='./linter.sh -H'

alias gb='git branch'

alias monty='cd janus/test/monty;rm py3;env/venv.sh'

alias gp='git pull'

alias vcj='journalctl --utc -D var/log/journal --list-boots'

alias mca='make cleanall;make;sudo rm -rf /tmp/janus_shared*'

alias sfaos='sp sfaos'

alias home='clear;cd;ll'

alias GRH='git rebase --abort;git reset --hard HEAD;gp'
