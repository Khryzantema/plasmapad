#!/bin/sh
# Compiles po/*.po into contents/locale/<lang>/LC_MESSAGES/plasma_applet_io.github.khryzantema.plasmapad.mo
cd "$(dirname "$0")/.." || exit 1
for po in po/*.po; do
    lang=$(basename "$po" .po)
    dir=contents/locale/$lang/LC_MESSAGES
    mkdir -p "$dir"
    msgfmt -o "$dir/plasma_applet_io.github.khryzantema.plasmapad.mo" "$po"
done
