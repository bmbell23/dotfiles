#!/bin/bash

# pihole: shortcuts for the Pi-hole stack in the docker repo (Dakota's; container `pihole`, v6).
# Only defined where that stack lives (dockerhost). `pihole help` for usage.
_pihole_dir=~/projects/docker/pihole
if [ -d "$_pihole_dir" ]; then

pihole() {
    local cmd="${1:-help}"
    shift || true
    case "$cmd" in
        status)
            docker exec pihole pihole status
            ;;
        block)
            [ $# -gt 0 ] || { echo "Usage: pihole block <domain>..."; return 1; }
            "$_pihole_dir/scripts/block.sh" "$@"
            ;;
        unblock)
            [ $# -gt 0 ] || { echo "Usage: pihole unblock <domain>..."; return 1; }
            "$_pihole_dir/scripts/unblock.sh" "$@"
            ;;
        pause)
            # For when a site breaks: blocking turns itself back on after the timer.
            docker exec pihole pihole disable "${1:-5m}"
            ;;
        resume)
            docker exec pihole pihole enable
            ;;
        top)
            # Most-blocked domains over the last N days, read-only from FTL's query database.
            local n="${1:-20}" days="${2:-7}"
            [[ "$n" =~ ^[0-9]+$ && "$days" =~ ^[0-9]+$ ]] || { echo "Usage: pihole top [count] [days]"; return 1; }
            printf "select count(*) as hits, domain from queries
                    where status in (1,4,5,6,7,8,9,10,11,15,16,18)
                      and timestamp > strftime('%%s','now','-%s days')
                    group by domain order by hits desc limit %s;\n" "$days" "$n" |
                docker exec -i pihole pihole-FTL sqlite3 -readonly -separator '  ' /etc/pihole/pihole-FTL.db
            ;;
        update)
            docker exec pihole pihole -g
            ;;
        help|-h|--help)
            cat << 'HELP'
pihole status                 is it blocking?
pihole block <domain>...      block a site and its subdomains (docker/pihole/scripts/block.sh)
pihole unblock <domain>...    undo a block (scripts/unblock.sh)
pihole pause [5m]             turn blocking off for a while (e.g. 30s, 5m, 1h)
pihole resume                 turn it back on now
pihole top [count] [days]     most-blocked domains (default 20, last 7 days)
pihole update                 refresh the blocklists (pihole -g)
Web UI: http://100.69.184.113:8053/admin
HELP
            ;;
        *)
            echo "pihole: unknown command '$cmd' (pihole help)" >&2
            return 1
            ;;
    esac
}
complete -W "status block unblock pause resume top update help" pihole

fi
