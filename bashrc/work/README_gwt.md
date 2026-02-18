# gwt - Git Worktree Manager

A bash function for easily managing git worktrees for SFAP tickets.

## Installation

Add this line to your `~/.bashrc` or `~/.bash_profile`:

```bash
source /path/to/gwt.sh
```

Then reload your shell:
```bash
source ~/.bashrc
```

## Usage

Run `gwt` or `gwt --help` to see full usage information.

### Quick Examples

**Create a new worktree from master:**
```bash
gwt g s 12345 coupled-crash-issue
```

**Create a worktree from a different remote branch:**
```bash
gwt g s 102078 read-copy-to-ap SFAP-102078-read-copy-to-ap
```

**Delete a worktree:**
```bash
gwt d s 12345
```

**Rename a worktree:**
```bash
gwt r s sfaos-SFAP-12345-old-name sfaos-SFAP-12345-new-name
```

## Features

- **Auto-detects** your projects directory (checks `/home/$USER/work/projects`, `/home/$USER/projects`, `/home/$USER`)
- **Auto-creates** VS Code workspace files with repository-specific themes
- **Auto-symlinks** logs from `/home/logs/SFAP-<ticket>` if they exist
- **For sfaos worktrees:**
  - Automatically creates lib symlink to auto/lib
  - Automatically sets up Python virtual environment
- **Cleans up** VS Code workspace storage when deleting worktrees

## Requirements

- Git with worktree support
- VS Code (optional, for workspace features)
- For sfaos: auto repository with lib directory

## Repository Structure

The function expects your repositories to be in one of these locations:
- `/home/$USER/work/projects/sfaos` and `/home/$USER/work/projects/auto`
- `/home/$USER/projects/sfaos` and `/home/$USER/projects/auto`
- `/home/$USER/sfaos` and `/home/$USER/auto`

Worktrees will be created as siblings to the main repository directory.

