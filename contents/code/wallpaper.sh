#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Prints the current desktop wallpaper image. Usage: wallpaper.sh [screen-width screen-height]
# (the size picks the closest-aspect image when the wallpaper is a multi-resolution package)

rc="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"

img=""
if [ -r "$rc" ]; then
    img=$(awk '
        /^\[/ { group = $0 }
        group ~ /^\[Containments\]\[[0-9]+\]$/ && /^plugin=org\.kde\.plasma\.folder$/ {
            id = group; gsub(/[^0-9]/, "", id); folder[id] = 1
        }
        /^Image=/ && group ~ /^\[Containments\]\[[0-9]+\]\[Wallpaper\]\[org\.kde\.image\]\[General\]$/ {
            id = group; sub(/^\[Containments\]\[/, "", id); sub(/\].*/, "", id)
            value[id] = substr($0, 7)
        }
        END { for (id in folder) if (value[id] != "") { print value[id]; exit } }
    ' "$rc")
fi
[ -z "$img" ] && img="Next"

img=${img#file://}
case "$img" in
    /*) path=$img ;;
    *)
        path=/usr/share/wallpapers/$img
        [ -e "$path" ] || path=${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/$img
        ;;
esac

if [ -d "$path" ]; then
    dir=$path/contents/images
    scheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
    lnf=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)
    case "$scheme$lnf" in
        *[Dd]ark*) [ -d "$path/contents/images_dark" ] && dir=$path/contents/images_dark ;;
    esac
    [ -d "$dir" ] || dir=$path

    path=$(ls "$dir"/* 2>/dev/null | awk -v sw="${1:-16}" -v sh="${2:-9}" '
        {
            name = $0; sub(/.*\//, "", name)
            if (match(name, /^[0-9]+x[0-9]+/)) {
                split(substr(name, RSTART, RLENGTH), d, "x")
                diff = (d[1] / d[2]) - (sw / sh); if (diff < 0) diff = -diff
                if (best == "" || diff < bestDiff) { best = $0; bestDiff = diff }
            } else if (best == "") {
                best = $0; bestDiff = 999
            }
        }
        END { print best }')
fi

printf '%s' "$path"
