#!/bin/bash

# Force the keyboard back to the first (US) group before locking. i3lock grabs
# the keyboard, so the Alt+Space layout switcher is unreachable on the lock
# screen -- if we lock while in ua/ru, the password becomes untypable.
#
# i3's environment has no LD_LIBRARY_PATH (xautolock and xss-lock inherit it),
# so a bare `xkb-switch` dies with a loader error (rc=127) because
# libxkbswitch.so.2 lives in ~/lib. xkblayout-state needs no custom libs, so it
# is the primary. Group *index* 0 is US in both the us,ua and us,ru pairs.
reset_kbd() {
    "$HOME/bin/xkblayout-state" set 0 2>/dev/null
    [ "$("$HOME/bin/xkblayout-state" print '%c' 2>/dev/null)" = "0" ] && return 0

    env LD_LIBRARY_PATH="$HOME/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        "$HOME/bin/xkb-switch" -s us 2>/dev/null && return 0

    # Never fail silently again -- but lock anyway; locking matters more.
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -u critical "i3lock" "Could NOT reset keyboard to US layout"
    return 1
}

lock_bg() {
    # Manual / idle lock: old behaviour
    reset_kbd
    i3lock -t -d -f -e --color=000000
}

lock_fg() {
    # For suspend/xss-lock: pause dunst, hide bar, lock in foreground, restore

    # Before pausing dunst, so a reset_kbd warning is actually visible
    reset_kbd

    # Pause dunst notifications if dunstctl is available
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused true
    fi

    i3-msg "bar mode hide" >/dev/null

    # -n: don't fork, stay in foreground until unlock
    i3lock -n -t -d -f -e --color=000000

    # After unlock: resume dunst and restore bar
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused false
    fi

    i3-msg "bar mode dock" >/dev/null
}

case "$1" in
    lock)
        lock_bg
        ;;
    lock-fg)
        lock_fg
        ;;
    logout)
        i3-msg exit
        ;;
    suspend)
        lock_fg && systemctl suspend
        ;;
    reboot)
        systemctl reboot
        ;;
    poweroff)
        systemctl poweroff
        ;;
    *)
        echo "Usage: $0 {lock|lock-fg|logout|suspend|reboot|poweroff}"
        exit 2
        ;;
esac

exit 0
