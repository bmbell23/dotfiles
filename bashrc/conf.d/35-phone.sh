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
    com.vzw.apnlib
)
PHONE_GUARD_REGEX='ims|telephony|carrier|launcher'

# `phone debloat <group>`: package -> "group|what it is". Picked from what's actually on the
# Pixel 10 Pro Fold (2026-10-11), conservative on purpose: nothing for calls, texts, camera,
# setup, updates or the launcher. Add or drop entries in ~/.config/phone/config, e.g.
#     PHONE_BLOAT[com.google.android.apps.photos]="google|Photos"
#     unset 'PHONE_BLOAT[com.google.android.apps.docs]'
declare -gA PHONE_BLOAT=(
    [com.android.chrome]="google|Chrome"
    [com.google.android.youtube]="google|YouTube"
    [com.google.android.apps.youtube.music]="google|YouTube Music"
    [com.google.android.videos]="google|Google TV"
    [com.google.android.apps.magazines]="google|Google News"
    [com.google.android.apps.docs]="google|Drive"
    [com.google.android.apps.bard]="google|Gemini"
    [com.google.android.apps.tachyon]="google|Meet"
    [com.google.android.apps.chromecast.app]="google|Google Home"
    [com.google.android.apps.tips]="google|Pixel Tips"
    [com.google.android.apps.labs.language.tailwind]="google|NotebookLM"
    [com.google.android.apps.pixel.creativeassistant]="google|Pixel Studio"
    [com.google.android.apps.aiwallpapers]="google|AI wallpapers"
    [com.google.android.apps.emojiwallpaper]="google|Emoji wallpapers"
    [com.google.android.apps.magicportrait]="google|Magic portrait"
    [com.google.android.apps.internal.betterbug]="google|Bug reporter"
    [com.google.android.feedback]="google|Feedback"
    [com.vzw.hss.myverizon]="verizon|My Verizon"
    [com.verizon.mips.services]="verizon|Verizon Mobile Intelligence (analytics)"
    [com.amazon.mShop.android.shopping]="partner|Amazon Shopping"
    [com.amazon.dee.app]="partner|Alexa"
    [com.facebook.katana]="partner|Facebook"
)

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

_phone_label() {  # best-effort human name: bloat list, then aliases; Android gives none over adb
    local pkg="$1" a
    if [ -n "${PHONE_BLOAT[$pkg]:-}" ]; then echo "${PHONE_BLOAT[$pkg]#*|}"; return; fi
    for a in "${!PHONE_ALIASES[@]}"; do
        [ "${PHONE_ALIASES[$a]}" = "$pkg" ] && { echo "$a"; return; }
    done
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
        reconnect)
            # Wireless debugging picks a new port whenever it's toggled; find it by scanning, then connect.
            [ -n "${PHONE_HOST:-}" ] || { echo "phone: set PHONE_HOST in $_phone_config" >&2; return 1; }
            local range="${PHONE_PORT_RANGE:-30000-49999}" open n
            echo "phone: scanning $PHONE_HOST ports $range for Wireless debugging..."
            open=$(seq "${range%-*}" "${range#*-}" |
                xargs -P 200 -I{} sh -c "nc -z -w1 '$PHONE_HOST' {} 2>/dev/null && echo {}" | sort -n)
            if [ -z "$open" ]; then
                echo "phone: no open ports on $PHONE_HOST. Is Wireless debugging on (and the phone on Tailscale)?" >&2
                return 1
            fi
            # Usually one port; the pairing dialog (or another service) can add more, so try each.
            for n in $open; do
                if adb connect "$PHONE_HOST:$n" 2>&1 | grep -q "connected to" &&
                   [ "$(adb -s "$PHONE_HOST:$n" get-state 2>/dev/null)" = device ]; then
                    mkdir -p "$_phone_state"; echo "$n" > "$_phone_state/port"
                    echo "phone: connected on port $n"
                    return 0
                fi
                adb disconnect "$PHONE_HOST:$n" &>/dev/null
            done
            echo "phone: open port(s) ${open//$'\n'/ } but none accepted adb. Check Wireless debugging; if it was reset, re-pair: phone pair <port> <code>" >&2
            return 1
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
        debloat)
            local group="" yes=0 a
            for a in "$@"; do
                case "$a" in
                    --yes) yes=1 ;;
                    google|verizon|partner|all) group="$a" ;;
                    *) echo "Usage: phone debloat <google|verizon|partner|all> [--yes]" >&2; return 1 ;;
                esac
            done
            [ -n "$group" ] || { echo "Usage: phone debloat <google|verizon|partner|all> [--yes]  (without --yes it only shows the plan)"; return 1; }
            local enabled todo=() p g label
            enabled=$(_phone_adb shell pm list packages -e) || return 1
            for p in $(printf '%s\n' "${!PHONE_BLOAT[@]}" | sort); do
                g="${PHONE_BLOAT[$p]%%|*}"; label="${PHONE_BLOAT[$p]#*|}"
                [ "$group" = all ] || [ "$group" = "$g" ] || continue
                if grep -qx "package:$p" <<< "$enabled"; then
                    printf '  %-8s %-28s %s\n' "$g" "$label" "$p"
                    todo+=("$p")
                fi
            done
            if [ ${#todo[@]} -eq 0 ]; then
                echo "phone: nothing left to remove in '$group' (already gone or disabled)"
                return 0
            fi
            if [ "$yes" -ne 1 ]; then
                echo "${#todo[@]} app(s) above would be removed. Run again with --yes to do it (undo any with: phone restore <pkg>)."
                return 0
            fi
            phone rm "${todo[@]}"
            ;;
        speed)
            local k
            local keys=(window_animation_scale transition_animation_scale animator_duration_scale)
            if [ -z "${1:-}" ]; then
                for k in "${keys[@]}"; do printf '%-28s %s\n' "$k" "$(_phone_adb shell settings get global "$k")"; done
                return
            fi
            [[ "$1" =~ ^(0|0\.5|1|1\.5|2)$ ]] || { echo "Usage: phone speed [0|0.5|1]  (0 = no animations, 1 = stock)"; return 1; }
            for k in "${keys[@]}"; do _phone_adb shell settings put global "$k" "$1" || return 1; done
            echo "animations: $1"
            ;;
        dns)
            if [ -z "${1:-}" ]; then
                local mode
                mode=$(_phone_adb shell settings get global private_dns_mode) || return 1
                case "$mode" in
                    hostname) echo "private DNS: $(_phone_adb shell settings get global private_dns_specifier)" ;;
                    off) echo "private DNS: off" ;;
                    *) echo "private DNS: automatic (Android default)" ;;
                esac
            elif [ "$1" = off ]; then
                _phone_adb shell settings put global private_dns_mode off && echo "private DNS: off"
            elif [[ "$1" =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                _phone_adb shell settings put global private_dns_specifier "$1" &&
                    _phone_adb shell settings put global private_dns_mode hostname &&
                    echo "private DNS: $1"
            else
                echo "Usage: phone dns [<hostname>|off]  (a DoT hostname, e.g. dns.adguard-dns.com; not an IP)"; return 1
            fi
            ;;
        review)
            # Enabled apps you installed, plus enabled system apps with a launcher icon. Pick, then `phone rm`.
            local enabled user launch pkgs=() p tag lines=() picked=() n i
            enabled=$(_phone_adb shell pm list packages -e | sed 's/^package://') || return 1
            user=$(_phone_adb shell pm list packages -3 | sed 's/^package://')
            launch=$(_phone_adb shell cmd package query-activities --brief -a android.intent.action.MAIN \
                         -c android.intent.category.LAUNCHER | sed -n 's#^ *\([A-Za-z0-9_.]*\)/.*#\1#p')
            while IFS= read -r p; do
                grep -qxF "$p" <<< "$enabled" || continue
                if grep -qxF "$p" <<< "$user"; then tag=user; else tag=system; fi
                _phone_guarded "$p" && tag="$tag,guarded"
                lines+=("$(printf '%-48s [%s] %s' "$p" "$tag" "$(_phone_label "$p")")")
            done < <(printf '%s\n%s\n' "$user" "$launch" | grep . | sort -u)
            [ ${#lines[@]} -gt 0 ] || { echo "phone: no apps found"; return 1; }

            if command -v fzf &>/dev/null; then
                mapfile -t picked < <(printf '%s\n' "${lines[@]}" |
                    fzf --multi --prompt="remove> " --header="TAB marks apps, ENTER removes, ESC cancels" | awk '{print $1}')
            else
                for i in "${!lines[@]}"; do printf '%3d) %s\n' $((i + 1)) "${lines[$i]}"; done
                read -r -p "Numbers to remove (e.g. 3 7 12-15), blank to cancel: " n
                for i in $n; do
                    if [[ "$i" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                        for ((p = BASH_REMATCH[1]; p <= BASH_REMATCH[2]; p++)); do picked+=("${lines[$((p - 1))]%% *}"); done
                    elif [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -ge 1 ] && [ "$i" -le ${#lines[@]} ]; then
                        picked+=("${lines[$((i - 1))]%% *}")
                    else
                        echo "phone: skipping '$i' (not a number on the list)" >&2
                    fi
                done
            fi
            mapfile -t picked < <(printf '%s\n' "${picked[@]}" | grep . | sort -u)
            [ ${#picked[@]} -gt 0 ] || { echo "phone: nothing picked"; return 0; }
            printf '  %s\n' "${picked[@]}"
            read -r -p "Remove these ${#picked[@]} app(s)? (undo any with phone restore) [y/N] " n
            [[ "$n" == [yY]* ]] || { echo "phone: cancelled"; return 0; }
            phone rm "${picked[@]}"
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
phone reconnect               the port moved? scan for it and connect (PHONE_PORT_RANGE, default 30000-49999)
phone off | status            disconnect / show connection
phone apps [filter]           installed packages, optionally filtered
phone disabled                disabled packages
phone rm [--force] <app>...   uninstall for user 0, or disable if that's refused; logged
phone restore <app>...        undo rm (enable, or reinstall the system copy)
phone debloat <group> [--yes] google | verizon | partner | all: show the plan; --yes removes
phone speed [0|0.5|1]         animation speed (0 = off, 1 = stock); no value shows it
phone dns [<host>|off]        Private DNS hostname, or off; no value shows it
phone review                  pick installed/launcher apps from a list (fzf if installed), then rm
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
        COMPREPLY=($(compgen -W "pair connect off status apps disabled rm restore debloat review speed dns log aliases sh push pull install logcat reboot adb help" -- "$cur"))
    elif [[ "${COMP_WORDS[1]}" == rm || "${COMP_WORDS[1]}" == restore ]]; then
        COMPREPLY=($(compgen -W "${!PHONE_ALIASES[*]} --force" -- "$cur"))
    elif [[ "${COMP_WORDS[1]}" == debloat ]]; then
        COMPREPLY=($(compgen -W "google verizon partner all --yes" -- "$cur"))
    fi
}
complete -F _phone_complete phone
