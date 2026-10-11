#!/bin/bash

# phone: manage Brandon's phone over ADB (Wireless debugging through Tailscale). `phone help` for usage.
# The host lives in an untracked file, ~/.config/phone/config, e.g.:
#     PHONE_HOST=100.x.y.z
#     PHONE_ALIASES[maps]=com.google.android.apps.maps    # extra aliases go here too
# The last connect port and an action log (for undo) live in ~/.local/state/phone/.

declare -gA PHONE_ALIASES=(
    [youtube]=com.google.android.youtube
    [ytmusic]=com.google.android.apps.youtube.music
    [playstore]=com.android.vending
    [chrome]=com.android.chrome
    [gmail]=com.google.android.gm
    [maps]=com.google.android.apps.maps
)

# Never removed without --force: these keep calls, texts and the phone itself working on Verizon.
PHONE_GUARD=(
    com.google.android.gms
    com.android.phone
    com.android.systemui
    com.android.settings
    com.google.android.apps.nexuslauncher
)
PHONE_GUARD_REGEX='ims|telephony|carrier|launcher'

_phone_config="${XDG_CONFIG_HOME:-$HOME/.config}/phone/config"
_phone_state="${XDG_STATE_HOME:-$HOME/.local/state}/phone"
[ -f "$_phone_config" ] && source "$_phone_config"

_phone_serial() {
    local port
    port=$(cat "$_phone_state/port" 2>/dev/null)
    if [ -z "${PHONE_HOST:-}" ] || [ -z "$port" ]; then
        echo "phone: not set up. Put PHONE_HOST=<ip> in $_phone_config, then: phone connect <port>" >&2
        return 1
    fi
    echo "$PHONE_HOST:$port"
}

_phone_adb() {
    local serial
    serial=$(_phone_serial) || return 1
    adb -s "$serial" "$@"
}

_phone_pkg() {  # alias -> package name; anything else passes through
    echo "${PHONE_ALIASES[$1]:-$1}"
}

_phone_guarded() {
    local pkg="$1" g
    for g in "${PHONE_GUARD[@]}"; do
        [ "$pkg" = "$g" ] && return 0
    done
    [[ "$pkg" =~ $PHONE_GUARD_REGEX ]]
}

_phone_log() {  # _phone_log <action> <pkg> <result>
    mkdir -p "$_phone_state"
    printf '%s\t%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" "$3" >> "$_phone_state/actions.log"
}

phone() {
    local cmd="${1:-help}"
    shift || true
    local pkg out force=0

    case "$cmd" in
        pair)
            [ $# -eq 2 ] || { echo "Usage: phone pair <pairing-port> <code>  (Wireless debugging → Pair device with pairing code)"; return 1; }
            [ -n "${PHONE_HOST:-}" ] || { echo "phone: set PHONE_HOST in $_phone_config" >&2; return 1; }
            adb pair "$PHONE_HOST:$1" "$2"
            ;;
        connect)
            [ -n "${PHONE_HOST:-}" ] || { echo "phone: set PHONE_HOST in $_phone_config" >&2; return 1; }
            if [ -n "${1:-}" ]; then
                mkdir -p "$_phone_state"
                echo "$1" > "$_phone_state/port"
            fi
            local serial
            serial=$(_phone_serial) || return 1
            out=$(adb connect "$serial" 2>&1)
            echo "$out"
            [[ "$out" == *"connected to"* ]]
            ;;
        off)
            local serial
            serial=$(_phone_serial) || return 1
            adb disconnect "$serial"
            ;;
        status)
            local serial
            serial=$(_phone_serial) || return 1
            echo "phone: $serial ($(adb -s "$serial" get-state 2>/dev/null || echo "not connected"))"
            adb devices -l | grep -F "$serial" || true
            ;;
        apps)
            _phone_adb shell pm list packages | sed 's/^package://' | grep -i -- "${1:-.}" | sort
            ;;
        disabled)
            _phone_adb shell pm list packages -d | sed 's/^package://' | sort
            ;;
        rm)
            [ "${1:-}" = "--force" ] && { force=1; shift; }
            [ $# -gt 0 ] || { echo "Usage: phone rm [--force] <pkg|alias>..."; return 1; }
            local rc=0
            for pkg in "$@"; do
                pkg=$(_phone_pkg "$pkg")
                if _phone_guarded "$pkg" && [ "$force" -ne 1 ]; then
                    echo "phone: refusing $pkg (guarded: calls/texts/system). Use --force if you're sure." >&2
                    rc=1; continue
                fi
                out=$(_phone_adb shell pm uninstall --user 0 "$pkg" 2>&1)
                if [[ "$out" == Success* ]]; then
                    _phone_log uninstall "$pkg" ok
                    echo "$pkg: uninstalled for user 0 (undo: phone restore $pkg)"
                    continue
                fi
                # System apps usually refuse ("only root can delete system app…"), so disable instead.
                local out2
                out2=$(_phone_adb shell pm disable-user --user 0 "$pkg" 2>&1)
                if [[ "$out2" == *"new state: disabled"* ]]; then
                    _phone_log disable "$pkg" ok
                    echo "$pkg: disabled (uninstall said: ${out//$'\n'/ }) (undo: phone restore $pkg)"
                else
                    _phone_log rm-failed "$pkg" "${out2//$'\n'/ }"
                    echo "phone: $pkg: uninstall: ${out//$'\n'/ }; disable: ${out2//$'\n'/ }" >&2
                    rc=1
                fi
            done
            return $rc
            ;;
        restore)
            [ $# -gt 0 ] || { echo "Usage: phone restore <pkg|alias>..."; return 1; }
            local rc=0
            for pkg in "$@"; do
                pkg=$(_phone_pkg "$pkg")
                if _phone_adb shell pm list packages -d | grep -qx "package:$pkg"; then
                    out=$(_phone_adb shell pm enable --user 0 "$pkg" 2>&1)
                    [[ "$out" == *"new state: enabled"* ]] && { _phone_log enable "$pkg" ok; echo "$pkg: enabled"; continue; }
                else
                    out=$(_phone_adb shell cmd package install-existing "$pkg" 2>&1)
                    [[ "$out" == *"installed for user"* ]] && { _phone_log install-existing "$pkg" ok; echo "$pkg: reinstalled for user 0"; continue; }
                fi
                _phone_log restore-failed "$pkg" "${out//$'\n'/ }"
                echo "phone: $pkg: ${out//$'\n'/ }" >&2
                rc=1
            done
            return $rc
            ;;
        log)
            cat "$_phone_state/actions.log" 2>/dev/null || echo "phone: nothing logged yet"
            ;;
        aliases)
            local a
            for a in "${!PHONE_ALIASES[@]}"; do printf '%-12s %s\n' "$a" "${PHONE_ALIASES[$a]}"; done | sort
            ;;
        sh|shell)
            _phone_adb shell "$@"
            ;;
        push|pull|install|logcat|reboot)
            _phone_adb "$cmd" "$@"
            ;;
        adb)
            _phone_adb "$@"
            ;;
        help|-h|--help)
            cat << 'EOF'
phone pair <port> <code>      pair (Wireless debugging → Pair device with pairing code)
phone connect [port]          connect; the port is remembered (it changes on every toggle)
phone off | status            disconnect / show connection
phone apps [filter]           installed packages, optionally filtered
phone disabled                disabled packages
phone rm [--force] <app>...   uninstall for user 0, or disable if that's refused; logged
phone restore <app>...        undo rm (enable, or reinstall the system copy)
phone log | aliases           action log / app aliases (add more in ~/.config/phone/config)
phone sh <cmd>                adb shell; also push, pull, install, logcat, reboot, adb <anything>
EOF
            ;;
        *)
            echo "phone: unknown command '$cmd' (phone help)" >&2
            return 1
            ;;
    esac
}

_phone_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "pair connect off status apps disabled rm restore log aliases sh push pull install logcat reboot adb help" -- "$cur"))
    elif [[ "${COMP_WORDS[1]}" == rm || "${COMP_WORDS[1]}" == restore ]]; then
        COMPREPLY=($(compgen -W "${!PHONE_ALIASES[*]} --force" -- "$cur"))
    fi
}
complete -F _phone_complete phone
