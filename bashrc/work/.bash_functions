#############################################################################
################################# FUNCTIONS #################################
#############################################################################

# Function: Create a PEM Kit ISO
function cpi()
{
    sudo platform/make_iso_boot -D PEM ISO $1
}

# Function: Delete a branch and checkout master
function gitdb()
{
    git checkout master
    gp
    git branch --delete $1
}

# Function: Install a PEM Kit
function ipk()
{
    sudo /ddn/install/upgrade_fw.sh $1
}

# Function: Navigate to a directory and long list
function cdl()
{
    cd $1
    ll
}

# Function: Code Load onto Controllers
function codeload()
{
	gomonty;
	py3 frontend.py --clear-test --target 10.36.31.$1 --partner 10.36.31.$2 --test Upgrade.test_previous_release --collect --kit $3 --auto_repos_rev 1 --project SFA
}


#*******************************************************************************
#   Look up the SHA or Rev for a given Rev or SHA
#   Type revsha -r 135934 to execute.
#   You can also embed this (example git checkout $(revsha -r 135934)
#   Keep in mind that revisions are branch specific, so you may see two of the same revision
#*******************************************************************************
function revsha()
{
	revision=""
	sha=""
	verbose=0
    OPTIND=1
    while getopts "h?vr:s:" OPTION
    do
	case $OPTION in
	    h|\?)
		cat <<EOF
Usage: revsha [-hvrs]
-h   : show this help
-v   : verbose output (returns complete SHA and build string)
-r   : Revision to find, returns SHA
-s   : SHA to find returns Revision (short 12-digit SHA accepted too)

Examples: (Do not specify Revision and SHA together)
GIT
revsha -r 135934           -- returns d085b20242644ab6f8949e3cd004962fbae2ec92
revsha -v -s d085b2024264  -- returns d085b20242644ab6f8949e3cd004962fbae2ec92 12.3.b-135934-d085b2024264
SVN
revsha -r 35000            -- returns 2d54900cffc96f482de934d570d21dbdf123ed4d
revsha -v -s 2d54900cffc9  -- returns 2d54900cffc96f482de934d570d21dbdf123ed4d r35000 trunk
EOF
		return 0
		;;
	    v)	verbose=1
			;;
	    r)  revision=$OPTARG
			;;
		s)	sha=$OPTARG
			;;
	esac
    done
    shift $((OPTIND-1))

	if [[ "${revision}" != "" && "${sha}" != "" ]]
	then
		echo "Revision OR SHA must be specified, but not both."
		return 1
	fi
	if [[ "${revision}" == "" && "${sha}" == "" ]]
	then
		echo "Revision OR SHA must be specified."
		return 1
	fi

	if [ "${revision}" != "" ]
	then
		if [ "${verbose}" == "1" ]
		then
			git log --format="%H %N" | egrep '[0-9]+' | egrep "\-$revision\-"\|"r$revision "
		else
			git log --format="%H %N" | egrep '[0-9]+' | egrep "\-$revision\-"\|"r$revision " | cut -d ' ' -f 1
		fi
	fi
	if [ "${sha}" != "" ]
	then
		if [ "${verbose}" == "1" ]
		then
			git log --format="%H %N" | egrep '[0-9]+' | grep $sha
		else
			# This is a dumb way to do it, but it does return the right thing for both SVN and GIT revisions
			git log --format="%H %N" | egrep '[0-9]+' | grep $sha | cut -d '-' -f 2 | cut -d ' ' -f 2
		fi
	fi
	return 0
}

# Function: Add ours
function gcoadd()
{
	git checkout --ours $1
	git add $1
}

# Function:
function clean()
{
    # Killing things
    sudo pkill --signal 9 --euid $USER unified
    sudo pkill --signal 9 --euid $USER perl
    sudo pkill --signal 9 --euid $USER --full "libnet-openssh"
    sudo pkill --signal 9 --euid auto unified
    sudo pkill --signal 9 --euid auto --full "libnet-openssh"
    sudo pkill --signal 9 --euid $USER py2
    sudo pkill --signal 9 --euid $USER py3

    # Fixing permissions and limits
    ulimit -c unlimited
    gojanus
    chmod 755 test/scripts/*.pl

    # Removing files
    sudo rm -rf /local/corefiles/*
    sudo rm -rf ${SFAOS_FULL_DISK_DIR}
    sudo rm -rf /tmp/janus-instance*
    sudo rm -rf /tmp/janus_shared*
    sudo rm -rf /tmp/janus_tap_shared*
    sudo rm -rf /tmp/org.eclipse.*
    sudo rm -rf /tmp/hsperfdata_$USER
    sudo rm -rf /tmp/[0-9]*
    sudo rm -rf /tmp/$USER/[0-9]*
    sudo rm -rf /tmp/shmem_*
    sudo rm -rf /tmp/checkouts
    sudo rm -rf /tmp/de*
    sudo rm -rf /tmp/*_triage
    sudo rm -rf /tmp/binary*
    sudo rm -rf /tmp/analyzer*
    sudo rm -rf /tmp/unit_test_*
    sudo rm -rf /tmp/bootstrap*
    sudo rm -rf /tmp/vmware*
    sudo rm -rf /tmp/log_viewer_filter*
    sudo rm -rf /tmp/sh-thd*

    # Python build artifacts that are inexplicably in the local repository and not in .gitignore. Idiots.
    rm -f testcases.json
}


# Function: Search git log for a 6-digit revision number
function scm()
{
	git log --format="%H %N" | egrep '[0-9]+' | grep $1 | cut -d ' ' -f 1
}


# Function: Find only files and stop looking after you find one
function ff()
{
    echo $(find . -name "$1" -type f -print -quit)
}


# Function:
function repeat()
{
    command="$@";
    exit=0
    count=0
	echo "Repeat '$command' until non-zero exit"
    while [ $exit = 0 ]
    do
        $command
        exit=$?
        count=$((count+1))
        echo "Total executions: $count"
    done
    echo "Ran the command $@ a total of $count times"
}

# Function: Easier interface to run python scripts.
function pys()
{
    target=$1
    shift
    args="$@"

    final_target=$(perl ${BASH_DIR}parse_pys_args.pl "${target}")
    if [[ -z "${final_target}" ]]; then
        echo "${target} not found - does the script exist?"
        return 1
    fi
    cmd="py3 test/monty/frontend.py -e ${final_target} ${args} --failfast"
    echo ${cmd}
    ${cmd}

    # --clear-test seems to cause a reboot between every test case. Nothing like
    # wasting 60 seconds between TCs, so I removed that arg from my default list

    # The Python team doesn't understand what build artifacts are or where they
    # should go. Purge them.
    rm -f testcases.json
}

# Function: Delete a local Git branch
function gbd()
{
	git branch -d $1
}

# Function: Merge 'both modified' files for OURS (from feature branch)
function gco()
{
	git checkout --ours $1
	git add $1
}

# Function: Merge 'both modified' files for THEIRS (from master)
function gct()
{
	git checkout --theirs $1
	git add $1
}

# Function: Make a directory and then change to it
function mcd()
{
	mkdir $1
	chmod 777 $1
	cd $1
}

# Function: Write to the specified $NOTE_WORK file
function nw()
{
	echo -e $1 >> $NOTE_WORK
}

# Function: Write to the specified $NOTE_PERSONAL file
function np()
{
	echo -e $1 >> $NOTE_PERSONAL
	clear
	ll
}

# Function:
function pyls()
{
    target=$1
    target_path=$(find . -name ${target} -print -quit)
    if [[ -z "${target_path}" ]]; then
        echo "${target} not found"
        return 1
    fi
    cmd="py3 -m pylint --rcfile test/monty/.pylintrc $target_path"
    echo ${cmd}
    ${cmd}
}

# Function: Tail the log of the most-recently-run script today
function tl()
{
    lines=600
    file=all.log

    for value in $@; do
      if [[ $value = *[[:digit:]] ]]; then
        lines=$value
      else
        file=$value
      fi
    done

    # Python generates a "runner" dir. I'm not sure if that's the one I want or
    # the one I should ignore. Ignore it for now.
    latest=$(ls -dc /home/logs/jts/$USER/[0-9]*/$HOSTNAME/* | grep -v 'runner' | head -n 1)
    if [[ -z "${latest}" ]]; then
        echo "There is no latest file - did Python delete the pass?"
        return 1;
    fi
    echo "Latest: $latest"
    echo "Viewing $latest/$file"
    tail -f -n $lines $latest/$file
}

# Function: Shows the version of a unified executable.
#           Necessary because 'unified -v' was broken to no longer be usable on platforms which the unified itself was not built for.
function ver()
{
    executable=$1
    if [[ -z "${executable}" ]]; then
        executable="unified"
    fi

    git archive --remote="ssh://${USER}@cos-scm-00.colorado.datadirectnet.com:29418/sfa/sfaos" HEAD janus/show_version.sh | tar -xO > /tmp/show_version.sh
    chmod +x /tmp/show_version.sh
    /tmp/show_version.sh ${executable}
    rm /tmp/show_version.sh
}

# Function: Reports the difference between two timestamps.
function tdiff()
{
    read -d '' HELP <<"EOF"
tdiff: Compare two time strings and report the difference

Usage: tdiff t0 t1 [-h]
t0   : First timestamp
t1   : Second timestamp
-h   : Show this help

Timestamp formats which are accepted:
YYYY-MM-DD hh:mm:ss[:ms]
EOF

    # Process options
    OPTIND=1
    while getopts "h?" OPTION
    do
    case $OPTION in
        h|\?)
            printf "$HELP\n"
            return 0
            ;;
    esac
    done
    shift $((OPTIND-1))

    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        printf "$HELP\n"
        return 0
    fi

    perl -I ${PERL_MOD_DIR} -e '
        use tdiff;
        printf("%02d:%02d:%02d\n", seconds_to_human(tdiff($ARGV[0], $ARGV[1])));
        ' "$1" "$2"
}

# Function:
function notes-bash()
{
	vim ~/notes/command-line-notes_bash.txt;
}

# Function:
function glossary()
{
  vim ~/notes/glossary.txt;
}

# Function:
function pem()
{
	ssh 10.36.28."$1"
	datadirect
}

# Function:
function con()
{
	ssh ddn@10.36.31."$1"
	IBopaFC!!
}

#Function:
function greset()
{
	git reset --hard $1
	git pull
}

# Function: Manage Git Worktrees
# Usage: tree <action> <repo> <ticket> [upstream_branch]
# action: g (generate) or d (delete)
# repo: a (auto) or s (sfaos)
# ticket: SFAP ticket number
# upstream_branch: optional, defaults to master
function gwt() {
    # Validate arguments
    if [[ $# -lt 3 ]]; then
        echo "Usage: tree <action> <repo> <ticket> [upstream_branch]"
        echo "action: g (generate) or d (delete)"
        echo "repo: a (auto) or s (sfaos)"
        echo "ticket: SFAP ticket number"
        return 1
    fi

    # Parse arguments
    local action="$1"
    local repo="$2"
    local ticket="$3"
    local upstream_branch="${4:-master}"
    local base_repo
    local worktree_name
    local ticket_number

    # Extract the 5-digit ticket number
    if [[ $ticket =~ ^([0-9]{5}) ]]; then
        ticket_number="${BASH_REMATCH[1]}"
    else
        ticket_number="$ticket"
    fi

    # Validate action
    case "$action" in
        g|d) ;;
        *) echo "Invalid action. Use 'g' for generate or 'd' for delete"; return 1 ;;
    esac

    # Set base repository
    case "$repo" in
        a) base_repo="auto" ;;
        s) base_repo="sfaos" ;;
        *) echo "Invalid repo. Use 'a' for auto or 's' for sfaos"; return 1 ;;
    esac

    # Set worktree name
    worktree_name="${base_repo}-SFAP-${ticket}"

    # Switch to base repository
    sp "$base_repo"
    clear
    echo -e "Swapping to ${base_repo} for a safe place to work."

    case "$action" in
        g) # Generate worktree
            echo -e "\nCreating worktree: ${worktree_name}"
            git branch "${worktree_name}"
            git worktree add "/home/$USER/projects/${worktree_name}" "${worktree_name}"
            git branch --set-upstream-to="origin/${upstream_branch}" "${worktree_name}"

            # Update .gitignore first
            local gitignore_file="/home/$USER/projects/${worktree_name}/.gitignore"
            local needs_workspace=true
            local needs_kanban=true
            local needs_logs=true

            if [[ -f "${gitignore_file}" ]]; then
                grep -q "^*.code-workspace$" "${gitignore_file}" && needs_workspace=false
                grep -q "^.kanban/$" "${gitignore_file}" && needs_kanban=false
                grep -q "logs$" "${gitignore_file}" && needs_logs=false
            fi

            # Only append what's missing
            {
                [[ "${needs_workspace}" == "true" ]] && echo "*.code-workspace"
                [[ "${needs_kanban}" == "true" ]] && echo ".kanban/"
                [[ "${needs_logs}" == "true" ]] && echo "logs"
            } >> "${gitignore_file}"

            # If we made changes to .gitignore, commit them
            if git -C "/home/$USER/projects/${worktree_name}" status --porcelain | grep -q ".gitignore"; then
                git -C "/home/$USER/projects/${worktree_name}" add .gitignore
                git -C "/home/$USER/projects/${worktree_name}" commit -m "chore: Update .gitignore with standard exclusions"
            fi

            # Create .kanban directory and its files
            mkdir -p "/home/$USER/projects/${worktree_name}/.kanban"
            touch "/home/$USER/projects/${worktree_name}/.kanban/backlog.txt"
            touch "/home/$USER/projects/${worktree_name}/.kanban/wip.txt"
            touch "/home/$USER/projects/${worktree_name}/.kanban/done.txt"

            # Symlink logs if they exist
            local logs_source="/home/logs/SFAP-${ticket_number}"
            if [[ -d "${logs_source}" ]]; then
                echo -e "\nFound logs for SFAP-${ticket_number}, creating symlink..."
                echo "Source: ${logs_source}"

                # Create logs as direct symlink to the logs source
                ln -s "${logs_source}" "/home/$USER/projects/${worktree_name}/logs"

                # Force git to acknowledge the ignore
                git -C "/home/$USER/projects/${worktree_name}" status --porcelain >/dev/null 2>&1
            fi

            # Set theme based on repo type
            local theme_name
            if [[ "$repo" == "a" ]]; then
                theme_name="mikasa rainbow"
            else
                theme_name="Monokai"
            fi

            # Create VS Code workspace file with repository-specific theme
            local workspace_file="/home/$USER/projects/${worktree_name}/${worktree_name}.code-workspace"
            cat > "${workspace_file}" << EOF
{
    "folders": [
        {
            "path": "."
        }
    ],
    "name": "${worktree_name}",
    "settings": {
        "workbench.colorTheme": "${theme_name}",
        "search.exclude": {
            "**/node_modules": true,
            "**/bower_components": true,
            "**/*.code-search": true,
            "**/build/**": true,
            "**/dist/**": true
        },
        "files.exclude": {
            "**/.git": true,
            "**/.svn": true,
            "**/.hg": true,
            "**/CVS": true,
            "**/.DS_Store": true,
            "**/Thumbs.db": true
        },
        "files.watcherExclude": {
            "**/.git/objects/**": true,
            "**/.git/subtree-cache/**": true,
            "**/node_modules/**": true,
            "**/build/**": true,
            "**/dist/**": true
        }
    }
}
EOF
            echo -e "\nSetting your project to: ${worktree_name}"
            sp "${worktree_name}"

            # Open VS Code with the workspace
            code -n "${worktree_name}.code-workspace"

            # If this is an SFAOS tree, setup lib symlink and virtual environment
            if [[ "$repo" == "s" ]]; then
                local scripts_dir="/home/$USER/projects/${worktree_name}/janus/test/scripts"
                local monty_dir="/home/$USER/projects/${worktree_name}/janus/test/monty"

                if [[ -d "$scripts_dir" ]]; then
                    echo -e "\nCreating lib symlink for SFAOS..."
                    cd "$scripts_dir"
                    ln -s /home/$USER/projects/auto/lib
                fi

                if [[ -d "$monty_dir" ]]; then
                    echo -e "\nSetting up Python virtual environment..."
                    cd "$monty_dir"
                    env/venv.sh
                fi
            fi

            # Return to projects directory
            cd ~/projects
            echo -e "\nWorktree setup complete. VS Code workspace opened in new window."
            echo -e "\nYour current list of worktrees:"
            git worktree list
            ;;

        d) # Delete worktree
            echo -e "\nYour current list of worktrees:"
            git worktree list
            echo -e "\nRemoving worktree: ${worktree_name}"
            rm -rf "/home/$USER/projects/${worktree_name}"
            echo -e "\nPruning your worktrees."
            git worktree prune
            echo -e "\nRemoving branch: ${worktree_name}"
            git branch -D "${worktree_name}"

            # Remove from VS Code recent workspaces
            local storage_path="$HOME/.config/Code/User/workspaceStorage"
            local vscode_state="$HOME/.config/Code/User/globalStorage/state.vscdb"

            # Remove workspace storage directory if it exists
            if [ -d "$storage_path" ]; then
                find "$storage_path" -type d -name "*${worktree_name}*" -exec rm -rf {} +
            fi

            # Remove from VSCode state DB if sqlite3 is available
            if command -v sqlite3 >/dev/null 2>&1; then
                if [ -f "$vscode_state" ]; then
                    sqlite3 "$vscode_state" "DELETE FROM ItemTable WHERE value LIKE '%${worktree_name}%';"
                fi
            fi

            cd .. && ll
            ;;
    esac

    echo -e "\nYour new list of worktrees:"
    git worktree list
}



#Function:
function greview()
{
	git review -d $1
}

#Function: Create and checkout a local branch, and indicate what branch it will track
function gbout()
{
	git checkout -b $1 --track origin/$2
}

#Function: Checkout a pre-existing local branch
function gout()
{
	git checkout $1
}

#Function: Delete a local branch
function gbdel()
{
	git branch -D $1
}

#Function
function skg()
{
	ssh-keygen -t dsa -f $1
}

#Function
function pl()
{
    # NAVIGATE TO THE JANUS DIRECTORY
	clear
    echo "Navigating to your Janus directory..."
    cd /home/bbell/work/projects/sfaos/janus

    # QUERY FOR INPUT VARIABLES TO RUN THE TEST
	read -p 'Script Name: ' script
	read -p '1st IP: ' ip0
	read -p '2nd IP: ' ip1
	read -p 'Platform? ' platform
	read -p 'kit: ' kit
	read -p 'Watchdog time? ' watchdog
	read -p 'Log location? ' logpath
	read -p 'Enable collection? ' collect

    # INITIALIZE THE COMMAND
	clear
    cmd=""

    # FIND THE SCRIPT AND ADD IT TO THE COMMAND
    if [[ ! -z ${script} ]];
    then
        script_path=$(find . -name ${script} -print -quit)
        cmd="perl ${script_path}"
    else
        echo "You did not provide a script. Please try again."
        return
    fi

    # ADD THE FIRST IP ADDRESS OR INDICATE EMULATION
    if [[ ! -z ${ip0} ]];
    then
        cmd+=" -jc0=${ip0} -i0=0"
    else
        cmd+=" -start_unified"
    fi

    # ADD THE SECOND IP ADDRESS IF PROVIDED
    if [[ ! -z ${ip1} ]];
    then
        cmd+=" -jc1=${ip1} -i1=0"
    fi

    # ADD THE PLATFORM IF PROVIDED
    if [[ ! -z ${platform} ]];
    then
        cmd+=" -platform=${platform}"
    fi

    # ADD THE KIT IF PROVIDED
    if [[ ! -z ${kit} ]];
    then
        cmd+=" -kit=${kit}"
    fi

    # ADD THE WATCHDOG TIMER IF PROVIDED
    if [[ ! -z ${watchdog} ]];
    then
        cmd+=" -watchdog=${watchdog}"
    fi

    # ADD THE LOG PATH IF PROVIDED
    if [[ ! -z ${logpath} ]];
    then
        cmd+=" -logpath=${logpath}"
    fi

    # ADD COLLECTION IF INDICATED
    if [[ ! -z ${collect} ]];
    then
        cmd+=" -collect"
    fi

    echo "The command to run this script with these parameters is:"
    echo ${cmd}
    echo "I'll go ahead and kick that off for you right now..."
    ${cmd}
}

function clean()
{
    # Killing SFA related processes
    sudo pkill --signal 9 --euid $USER unified
    sudo pkill --signal 9 --euid $USER perl
    sudo pkill --signal 9 --euid $USER --full "libnet-openssh"
    sudo pkill --signal 9 --euid auto unified
    sudo pkill --signal 9 --euid auto --full "libnet-openssh"
    sudo pkill --signal 9 --euid $USER py2
    sudo pkill --signal 9 --euid $USER py3

    # Fixing permissions and limits
    ulimit -c unlimited

    # Removing files from /tmp
    sudo rm -rf --one-file-system /local/corefiles/*
    sudo rm -rf --one-file-system ${SFAOS_FULL_DISK_DIR}
    sudo rm -rf --one-file-system /tmp/janus-instance*
    sudo rm -rf --one-file-system /tmp/janus_shared*
    sudo rm -rf --one-file-system /tmp/janus_tap_shared*
    sudo rm -rf --one-file-system /tmp/org.eclipse.*
    sudo rm -rf --one-file-system /tmp/hsperfdata_$USER
    sudo rm -rf --one-file-system /tmp/[0-9]*
    sudo rm -rf --one-file-system /tmp/$USER/[0-9]*
    sudo rm -rf --one-file-system /tmp/shmem_*
    sudo rm -rf --one-file-system /tmp/checkouts
    sudo rm -rf --one-file-system /tmp/de*
    sudo rm -rf --one-file-system /tmp/*_triage
    sudo rm -rf --one-file-system /tmp/binary*
    sudo rm -rf --one-file-system /tmp/analyzer*
    sudo rm -rf --one-file-system /tmp/unit_test_*
    sudo rm -rf --one-file-system /tmp/bootstrap*
    sudo rm -rf --one-file-system /tmp/vmware*
    sudo rm -rf --one-file-system /tmp/log_viewer_filter*
    sudo rm -rf --one-file-system /tmp/sh-thd*

    # Removing Python build artifacts that are in the local repository and not in .gitignore
    rm -f testcases.json
    rm -rf --one-file-system test/monty/branch/decoders_*

    # Cleaning up API and Docker containers
    sudo kill -9 $(pidof sfcbd) 2>/dev/null
    perl -e '
        # Purge containers
        my $output = `docker ps -a | grep " ci_"`;
        my @lines = split(/\n/, $output);
        foreach my $line ( @lines )
        {
            if ($line =~ m/^([^ ]+)\s+pem:ci_/)
            {
                my $cid = $1;
                `docker container stop $cid`;
                `docker container rm $cid`;
            }
        }

        # Purge images
        my $output = `docker images | grep " ci_"`;
        my @lines = split(/\n/, $output);
        foreach my $line ( @lines )
        {
            if ($line =~ m/^pem\s+ci_[^ ]+\s+([^ ]+)/)
            {
                my $iid = $1;
                `docker image rm $iid`;
            }
        }
    '
    #Clean logs
    $(rm -rf --one-file-system /home/logs/jts/$USER/[0-9]*)
}

function scmp()
{
    proj="${1:-sfaos}"
    sp "$proj"
    cd janus
    clean
    mca
    make installapi
    cd test/monty
    env/venv.sh
    time py3 frontend.py -e Template

}

function auto()
{
    sp auto-SFAP-$1
    ID=$(echo "$1" | grep -oP '(?<=SFAP-)\d+')
    echo "https://jira.tegile.com/browse/SFAP-$ID"

}

function sfap()
{
    sp sfaos-SFAP-$1
    project=$1
    ID=$(echo "$project" | grep -oP '(?<=SFAP-)\d+')
    echo "ID is $ID"
    echo "https://jira.tegile.com/browse/SFAP-$ID"

}

function mkcd()
{
	mkdir $1
	cd $1
}

function tn()
{
	touch $1
	nano $1
}

function get_ip_addr()
{
    ip addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -n 1
}

function get_debian_version()
{
    grep -oP '^[^\.]+' /etc/debian_version
}

function book()
{
	python -m scripts.utils.search_book -f "$1"
}

function sqlti()
{
	sqlite3 data/db/reading_list.db "pragma table_info($1)"
}

function sqlt()
{
	sqlite3 data/db/reading_list.db ".tables"
}

function sql()
{
	sqlite3 data/db/reading_list.db "$1"
}

function hs()
{
	history | grep '$1'
}

function select_project() {
    local projects=("$@")
    local num_projects=${#projects[@]}

    # Print header
    echo "╭──────────────[ Project Selector ]──────────────╮"
    echo "│ Found ${num_projects} projects                                │"
    echo "│─────────────────────────────────────────────────│"

    # Print projects
    for i in "${!projects[@]}"; do
        printf "│  %d) %-42s │\n" "$((i+1))" "${projects[i]}"
    done
    printf "│  0) Exit                                        │\n"
    echo "╰─────────────────────────────────────────────────╯"

    # Get user selection with trap for Ctrl+C
    local selection
    trap 'echo -e "\nExiting project selector..."; return 1' INT
    while true; do
        read -rp "• Select project (0-${num_projects}): " selection

        # Check for exit condition
        if [[ "$selection" == "0" ]]; then
            echo "Exiting project selector..."
            return 1
        fi

        # Validate input
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -le "$num_projects" ] && [ "$selection" -gt 0 ]; then
            break
        fi
        echo "Invalid selection. Please choose between 0 and ${num_projects}"
    done
    trap - INT

    # Return the selected project (array is 0-based, so subtract 1)
    echo "${projects[$((selection-1))]}"
}

function code() {
    # Try to connect to VS Code server
    command code "$@" 2>/dev/null || {
        local exit_code=$?

        # If the error was due to server connection issues
        if [[ $exit_code -eq 1 ]]; then
            echo "VS Code server connection failed. Attempting to restart VS Code server..."

            # Kill any existing VS Code processes
            pkill -f "code" || true

            # Clean up any stale socket files
            rm -f /run/user/$UID/vscode-ipc-*.sock

            # Wait for processes to fully terminate
            sleep 2

            # Start VS Code server in the background
            /usr/bin/code --start-server &>/dev/null &

            # Wait for server to initialize
            sleep 3

            # Try again
            command code "$@" 2>/dev/null || {
                echo "Error: Failed to start VS Code. Please check if VS Code is installed correctly."
                return 1
            }
        else
            echo "Error: Failed to open VS Code (exit code: $exit_code)"
            return $exit_code
        fi
    }
}
