#!/bin/bash
# gwt - Git Worktree Manager
# Standalone function for managing git worktrees for SFAP tickets
#
# Usage: Source this file in your .bashrc or .bash_profile
#   source /path/to/gwt.sh
#
# Then use: gwt --help for usage information

function gwt() {
    # Auto-detect projects directory by looking for sfaos or auto repositories
    local projects_dir=""
    local search_paths=(
        "/home/$USER/work/projects"
        "/home/$USER/projects"
        "/home/$USER"
    )

    for path in "${search_paths[@]}"; do
        if [[ -d "$path/sfaos" ]] || [[ -d "$path/auto" ]]; then
            projects_dir="$path"
            break
        fi
    done

    if [[ -z "$projects_dir" ]]; then
        echo "Error: Could not find sfaos or auto repository in standard locations:"
        printf '  %s\n' "${search_paths[@]}"
        echo "Please ensure your repositories are in one of these locations."
        return 1
    fi

    # Show help if no arguments or help flag
    if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        cat << 'EOF'
gwt - Git Worktree Manager

USAGE:
    gwt <action> <repo> <ticket_number> <description> [upstream_branch]
    gwt <action> <repo> <full_worktree_name> [upstream_branch]
    gwt r <repo> <old_worktree_name> <new_worktree_name>

ACTIONS:
    g           Generate (create) a new worktree
    d           Delete an existing worktree
    r           Rename an existing worktree

REPOSITORIES:
    a           auto repository
    s           sfaos repository

ARGUMENTS:
    ticket_number       SFAP ticket number (5 or 6 digits)
    description         Brief description for branch name (use hyphens, no spaces)
    upstream_branch     Remote branch to track (default: master)
    full_worktree_name  Complete worktree name (e.g., sfaos-SFAP-123456-description)

EXAMPLES:
    # Create new worktree from master
    gwt g s 12345 coupled-crash-issue

    # Create new worktree from a different remote branch
    gwt g s 102078 read-copy-to-ap SFAP-102078-read-copy-to-ap

    # Create worktree tracking a release branch
    gwt g s 123456 other-issue 12.8-branch

    # Delete worktree (auto-find by SFAP number)
    gwt d s 12345

    # Delete worktree (with description)
    gwt d s 12345 coupled-crash-issue

    # Delete worktree (using full name)
    gwt d s sfaos-SFAP-123456-test

    # Rename worktree
    gwt r s sfaos-SFAP-12345-old-name sfaos-SFAP-12345-new-name

NOTES:
    - Auto-detects projects directory
    - For sfaos worktrees, automatically creates lib symlink and Python venv
    - Creates VS Code workspace file with repository-specific theme
    - Symlinks logs from /home/logs/SFAP-<ticket> if they exist
    - When creating from a remote branch, the worktree starts from that branch's HEAD

EOF
        return 0
    fi

    # Save original directory to return to at the end
    local original_dir="$(pwd)"

    # Handle rename action differently (maintains old interface)
    if [[ "$1" == "r" ]]; then
        # For rename: gwt r <repo> <old_worktree_name> <new_worktree_name>
        if [[ $# -lt 4 ]]; then
            echo "Error: Rename requires 4 arguments"
            echo "Usage: gwt r <repo> <old_worktree_name> <new_worktree_name>"
            return 1
        fi
        local action="$1"
        local repo="$2"
        local old_worktree_name="$3"
        local new_worktree_name="$4"
    else
        # For generate: gwt <action> <repo> <ticket_number> <description> [upstream_branch]
        # For delete: gwt <action> <repo> <ticket_number> [description]
        #          OR gwt <action> <repo> <full_worktree_name>

        local action="$1"
        local repo="$2"
        local third_arg="$3"

        # Check if third argument is a full worktree name (contains hyphens beyond just SFAP-)
        # e.g., "sfaos-SFAP-123456-test" or "auto-SFAP-123456-description"
        if [[ "$third_arg" =~ ^(sfaos|auto)-SFAP-[0-9]{5,6}-.+ ]]; then
            # Full worktree name provided - extract components
            if [[ "$third_arg" =~ ^(sfaos|auto)-SFAP-([0-9]{5,6})-(.+)$ ]]; then
                local extracted_repo="${BASH_REMATCH[1]}"
                local ticket_number="${BASH_REMATCH[2]}"
                local description="${BASH_REMATCH[3]}"

                # Override repo if it was extracted from worktree name
                case "$extracted_repo" in
                    auto) repo="a" ;;
                    sfaos) repo="s" ;;
                esac

                local upstream_branch="${4:-master}"
            else
                echo "Error: Could not parse worktree name: $third_arg"
                return 1
            fi
        else
            # Traditional argument format
            local ticket_number="$third_arg"
            local description="$4"
            local upstream_branch="${5:-master}"
        fi

        if [[ "$action" == "g" && -z "$description" ]]; then
            echo "Usage: gwt <action> <repo> <ticket_number> <description> [upstream_branch]"
            echo "    OR gwt <action> <repo> <full_worktree_name> [upstream_branch]"
            echo "action: g (generate) or d (delete)"
            echo "repo: a (auto) or s (sfaos)"
            echo "ticket_number: SFAP ticket number (5 or 6 digits)"
            echo "description: ticket description for branch name (required for generate, optional for delete)"
            echo "upstream_branch: optional, defaults to master"
            echo ""
            echo "Examples:"
            echo "  gwt g s 12345 coupled-crash-issue master"
            echo "  gwt g s 123456 other-issue 12.8-branch"
            echo "  gwt d s 12345 coupled-crash-issue  (traditional usage)"
            echo "  gwt d s 12345                      (auto-find worktree by SFAP number)"
            echo "  gwt d s sfaos-SFAP-123456-test     (full worktree name)"
            echo ""
            echo "For rename: gwt r <repo> <old_worktree_name> <new_worktree_name>"
            return 1
        elif [[ "$action" == "d" && -z "$ticket_number" ]]; then
            echo "Usage: gwt d <repo> <ticket_number> [description]"
            echo "    OR gwt d <repo> <full_worktree_name>"
            echo "For delete, description is optional - will auto-find worktree by SFAP number"
            return 1
        fi
    fi

    local base_repo
    local worktree_name

    # Validate action
    case "$action" in
        g|d|r) ;;
        *) echo "Invalid action. Use 'g' for generate, 'd' for delete, or 'r' for rename"; cd "$original_dir"; return 1 ;;
    esac

    # Set base repository
    case "$repo" in
        a) base_repo="auto" ;;
        s) base_repo="sfaos" ;;
        *) echo "Invalid repo. Use 'a' for auto or 's' for sfaos"; cd "$original_dir"; return 1 ;;
    esac

    # Set worktree name
    if [[ "$action" == "r" ]]; then
        worktree_name="$old_worktree_name"  # For rename, we start with the old name
    elif [[ "$action" == "d" && -z "$description" ]]; then
        # For delete with just SFAP number, find the matching worktree
        local pattern="${base_repo}-SFAP-${ticket_number}-"
        local found_worktrees=($(find "$projects_dir" -maxdepth 1 -type d -name "${pattern}*" | sed "s|$projects_dir/||"))

        if [[ ${#found_worktrees[@]} -eq 0 ]]; then
            echo "Error: No worktree found matching SFAP-${ticket_number} for ${base_repo}"
            cd "$original_dir"
            return 1
        elif [[ ${#found_worktrees[@]} -gt 1 ]]; then
            echo "Error: Multiple worktrees found matching SFAP-${ticket_number} for ${base_repo}:"
            printf '  %s\n' "${found_worktrees[@]}"
            echo "Please specify the description to disambiguate."
            cd "$original_dir"
            return 1
        fi

        worktree_name="${found_worktrees[0]}"
        echo "Found worktree: ${worktree_name}"
    else
        worktree_name="${base_repo}-SFAP-${ticket_number}-${description}"
    fi

    # Switch to base repository directory (without opening VS Code)
    cd "$projects_dir/$base_repo" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Could not change to base repository directory: $projects_dir/$base_repo"
        cd "$original_dir"
        return 1
    fi
    clear
    echo -e "Working in ${base_repo} repository for worktree operations."

    case "$action" in
        g) # Generate worktree
            echo -e "\nCreating worktree: ${worktree_name}"
            # Create worktree directly from the remote branch in one atomic operation
            # This ensures the local branch starts from the correct upstream branch
            git worktree add -b "${worktree_name}" "$projects_dir/${worktree_name}" "origin/${upstream_branch}"

            # Symlink logs if they exist
            local logs_source="/home/logs/SFAP-${ticket_number}"
            if [[ -d "${logs_source}" ]]; then
                echo -e "\nFound logs for SFAP-${ticket_number}, creating symlink..."
                echo "Source: ${logs_source}"
                ln -s "${logs_source}" "$projects_dir/${worktree_name}/logs"
                git -C "$projects_dir/${worktree_name}" status --porcelain >/dev/null 2>&1
            fi

            # Set theme based on repo type
            local theme_name
            if [[ "$repo" == "a" ]]; then
                theme_name="mikasa rainbow"
            else
                theme_name="Monokai"
            fi

            # Create VS Code workspace file with repository-specific theme
            local workspace_file="$projects_dir/${worktree_name}/${worktree_name}.code-workspace"
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
            echo -e "\nSwitching to new worktree: ${worktree_name}"
            cd "$projects_dir/${worktree_name}"

            # Open VS Code with the workspace
            code -n "${worktree_name}.code-workspace"

            # If this is an SFAOS tree, setup lib symlink and virtual environment
            if [[ "$repo" == "s" ]]; then
                local scripts_dir="$projects_dir/${worktree_name}/janus/test/scripts"
                local monty_dir="$projects_dir/${worktree_name}/janus/test/monty"

                if [[ -d "$scripts_dir" ]]; then
                    echo -e "\nCreating lib symlink for SFAOS..."
                    cd "$scripts_dir"
                    ln -s $projects_dir/auto/lib
                fi

                if [[ -d "$monty_dir" ]]; then
                    echo -e "\nSetting up Python virtual environment..."
                    cd "$monty_dir"
                    env/venv.sh
                fi
            fi

            echo -e "\nWorktree setup complete. VS Code workspace opened in new window."
            echo -e "\nYour current list of worktrees:"
            # Switch back to base repo to show worktree list
            cd "$projects_dir/$base_repo"
            git worktree list
            ;;

        d) # Delete worktree
            echo -e "\nYour current list of worktrees:"
            git worktree list
            echo -e "\nRemoving worktree: ${worktree_name}"
            rm -rf "$projects_dir/${worktree_name}"
            echo -e "\nPruning your worktrees."
            git worktree prune
            echo -e "\nRemoving branch: ${worktree_name}"
            git branch -D "${worktree_name}"

            # Remove from VS Code recent workspaces
            local storage_path="$HOME/.config/Code/User/workspaceStorage"
            local vscode_state="$HOME/.config/Code/User/globalStorage/state.vscdb"

            # Remove workspace storage directory if it exists
            if [ -d "$storage_path" ]; then
                find "$storage_path" -type d -name "*${worktree_name}*" -exec rm -rf {} + 2>/dev/null || true
            fi

            # Remove from VSCode state DB if sqlite3 is available
            if command -v sqlite3 >/dev/null 2>&1; then
                if [ -f "$vscode_state" ]; then
                    sqlite3 "$vscode_state" "DELETE FROM ItemTable WHERE value LIKE '%${worktree_name}%';" 2>/dev/null || true
                fi
            fi

            echo -e "\nDelete operation completed."
            ;;

        r) # Rename worktree
            echo -e "\nYour current list of worktrees:"
            git worktree list

            # Validate that the old worktree exists
            if [[ ! -d "$projects_dir/${old_worktree_name}" ]]; then
                echo "Error: Worktree '${old_worktree_name}' does not exist"
                cd "$original_dir"
                return 1
            fi

            # Validate that the new worktree name doesn't already exist
            if [[ -d "$projects_dir/${new_worktree_name}" ]]; then
                echo "Error: Worktree '${new_worktree_name}' already exists"
                cd "$original_dir"
                return 1
            fi

            echo -e "\nRenaming worktree from '${old_worktree_name}' to '${new_worktree_name}'"

            # Step 1: Rename the directory
            mv "$projects_dir/${old_worktree_name}" "$projects_dir/${new_worktree_name}"

            # Step 2: Update git worktree path
            git worktree remove "${old_worktree_name}" 2>/dev/null || true
            git worktree add "$projects_dir/${new_worktree_name}" "${old_worktree_name}"

            # Step 3: Rename the branch
            git branch -m "${old_worktree_name}" "${new_worktree_name}"

            # Step 4: Update the workspace file name and content
            local old_workspace_file="$projects_dir/${new_worktree_name}/${old_worktree_name}.code-workspace"
            local new_workspace_file="$projects_dir/${new_worktree_name}/${new_worktree_name}.code-workspace"

            if [[ -f "$old_workspace_file" ]]; then
                # Update the workspace name in the file content
                sed -i "s/\"name\": \"${old_worktree_name}\"/\"name\": \"${new_worktree_name}\"/" "$old_workspace_file"
                # Rename the workspace file
                mv "$old_workspace_file" "$new_workspace_file"
                echo -e "Updated workspace file: ${new_workspace_file}"
            fi

            echo -e "\nWorktree renamed successfully!"
            echo -e "Old name: ${old_worktree_name}"
            echo -e "New name: ${new_worktree_name}"
            ;;
    esac

    echo -e "\nYour new list of worktrees:"
    git worktree list

    # Return to original directory
    cd "$original_dir"
    echo -e "\nReturned to original directory: $(pwd)"
}

