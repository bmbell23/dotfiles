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

# Function: Create a GIT worktree
function gworktree()
{
    name=$1
    if [[ -z "$name" ]]; then
        echo "Must provide a worktree name"
        return 1
    fi

    # CD to a known good starting point for Git
    sp sfaos

    if [ -d ../$name ]; then
        echo "$name branch or worktree already exists."
        return 1
    fi

    git worktree add -b $name ../$name origin/$name

    sp $name
    cd janus/test/scripts
    ln -s /home/$USER/work/projects/auto/lib

    cd ../monty
    env/venv.sh
    sp $name
}

# Function: Delete a GIT worktree AND Branch
function dworktree()
{
    name=$1
    if [[ -z "$name" ]]; then
        echo "Must provide a worktree name"
        return 1
    fi
    BRPTR="/home/$USER/work/projects/$name"
    if [[ ! -d $BRPTR ]]; then
        echo "'${BRPTR}' worktree not found."
        return 1
    fi

    # CD to the branch and remove the lib
    if [[ -d $BRPTR/janus/test/scripts/lib ]]; then
        rm $BRPTR/janus/test/scripts/lib
    fi

    # CD to a known good repo
    sp sfaos
    rm -rf ../$name

    git worktree prune
    git branch -D $name
}

# Function: Code Load onto Controllers
function codeload()
{
    gomonty;
    py3 frontend.py --clear-test --target 10.36.31.$1 --partner 10.36.31.$2 --test Upgrade.test_previous_release --collect --kit $3 --auto_repos_rev 1 --project SFA
}

# Function: Look up the SHA or Rev for a given Rev or SHA
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
        v)  verbose=1
            ;;
        r)  revision=$OPTARG
            ;;
        s)  sha=$OPTARG
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
}