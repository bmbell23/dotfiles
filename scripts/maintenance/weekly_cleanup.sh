#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Run various cleanup tasks
echo "Running weekly system cleanup..."

# Check and install any missing cron jobs
echo "Checking cron jobs..."
"${DOTFILES_DIR}/scripts/cron/install_crons.sh" check || "${DOTFILES_DIR}/scripts/cron/install_crons.sh" install

# Other cleanup tasks...