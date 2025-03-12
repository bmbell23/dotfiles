#!/bin/bash

# Kanban board functions

# Define color codes (for general text output)
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Add item to backlog
backlog() {
    local item="$*"
    local backlog_file="$WORKSPACE/.kanban/backlog.txt"

    mkdir -p "$WORKSPACE/.kanban"
    echo "$(date '+%Y-%m-%d'): $item" >> "$backlog_file"
    echo -e "${GREEN}Added to backlog:${RESET} $item"
    show_kanban
}

# Move item to WIP or add new WIP item
wip() {
    local item="$*"
    local wip_file="$WORKSPACE/.kanban/wip.txt"

    mkdir -p "$WORKSPACE/.kanban"
    echo "$(date '+%Y-%m-%d'): $item" >> "$wip_file"
    printf "${YELLOW}Added to WIP:${RESET} %s\n" "$item"
    show_kanban
}

# Move item to Done
finish() {
    local item="$*"
    local done_file="$WORKSPACE/.kanban/done.txt"

    mkdir -p "$WORKSPACE/.kanban"
    echo "$(date '+%Y-%m-%d'): $item" >> "$done_file"
    printf "${CYAN}Added to Done:${RESET} %s\n" "$item"
    show_kanban
}

# Show kanban board
show_kanban() {
    local backlog_file="$WORKSPACE/.kanban/backlog.txt"
    local wip_file="$WORKSPACE/.kanban/wip.txt"
    local done_file="$WORKSPACE/.kanban/done.txt"

    printf "\n${YELLOW}📋 Kanban Board for ${CYAN}%s${RESET}\n\n" "$(basename "$WORKSPACE")"

    printf "${YELLOW}🚀 IN PROGRESS:${RESET}\n"
    if [[ -f "$wip_file" ]]; then
        cat "$wip_file"
    else
        printf "No items in progress\n"
    fi

    printf "\n${GREEN}📥 BACKLOG:${RESET}\n"
    if [[ -f "$backlog_file" ]]; then
        cat "$backlog_file"
    else
        printf "No items in backlog\n"
    fi

    printf "\n${CYAN}✅ RECENTLY COMPLETED:${RESET}\n"
    if [[ -f "$done_file" ]]; then
        tail -n 5 "$done_file"
    else
        printf "No completed items\n"
    fi
}

# Move items between states
move_to_wip() {
    local backlog_file="$WORKSPACE/.kanban/backlog.txt"
    local wip_file="$WORKSPACE/.kanban/wip.txt"

    if [[ ! -f "$backlog_file" ]]; then
        printf "No items in backlog\n"
        return
    fi

    printf "Select item to move to WIP:\n"
    select item in $(cat "$backlog_file"); do
        if [[ -n "$item" ]]; then
            echo "$item" >> "$wip_file"
            grep -v "$item" "$backlog_file" > "$backlog_file.tmp"
            mv "$backlog_file.tmp" "$backlog_file"
            printf "${GREEN}Moved to WIP:${RESET} %s\n" "$item"
        fi
        break
    done
}

move_to_done() {
    local wip_file="$WORKSPACE/.kanban/wip.txt"
    local done_file="$WORKSPACE/.kanban/done.txt"

    if [[ ! -f "$wip_file" ]]; then
        printf "No items in WIP\n"
        return
    fi

    printf "Select item to move to Done:\n"
    select item in $(cat "$wip_file"); do
        if [[ -n "$item" ]]; then
            echo "$item" >> "$done_file"
            grep -v "$item" "$wip_file" > "$wip_file.tmp"
            mv "$wip_file.tmp" "$wip_file"
            printf "${GREEN}Moved to Done:${RESET} %s\n" "$item"
        fi
        break
    done
}
